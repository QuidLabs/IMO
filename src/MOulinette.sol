
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25; // EVM: london
import "lib/forge-std/src/console.sol"; // TODO 
import {Quid} from "./QD.sol";
import {WETH} from "lib/solmate/src/tokens/WETH.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ERC4626} from "lib/solmate/src/tokens/ERC4626.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";

import {TickMath} from "./imports/math/TickMath.sol";
import {FullMath} from "./imports/math/FullMath.sol";
import {ISwapRouter} from "./imports/ISwapRouter.sol"; 
import {IUniswapV3Pool} from "./imports/IUniswapV3Pool.sol";
import {LiquidityAmounts} from "./imports/math/LiquidityAmounts.sol";
import {INonfungiblePositionManager} from "./imports/INonfungiblePositionManager.sol";
// import {IV3SwapRouter as ISwapRouter} from "./imports/IV3SwapRouter.sol"; // TODO base

contract MO is ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for WETH;
    address public immutable USDC;
    ERC20 public immutable token1;
    ERC20 public immutable token0;
    WETH public immutable WETH9;
    uint public ID; // V3 NFT...
    uint public FEE = WAD / 28;
    bool public token1isWETH;
    int24 internal UPPER_TICK;
    int24 internal LOWER_TICK;
    int24 internal LAST_TICK;
    uint internal _ETH_PRICE; // TODO 
    uint constant WAD = 1e18;
    uint24 constant POOL_FEE = 500;
    INonfungiblePositionManager NFPM;
    IUniswapV3Pool POOL; ISwapRouter ROUTER;
    uint128 liquidityUnderManagement; // UniV3
    mapping(address => uint) flashLoanProtect;
    struct FoldState { uint delta; uint price;
        uint average_price; uint average_value;
        uint deductible; uint cap; uint minting;
        bool liquidate; uint repay; uint collat;
    } Quid QUID; // tethered to the MO contract
    function get_info(address who) view
        external returns (uint, uint) {
        Offer memory pledge = pledges[who];
        return (pledge.carry.debit, QUID.balanceOf(who));
        // this is more of an internal tracking variable
    }   function get_more_info(address who) view
        external returns (uint, uint, uint, uint) {
        Offer memory pledge = pledges[who];
        // work is pledged as a CDP, weth as insurance
        return (pledge.work.debit, pledge.work.credit,
                pledge.weth.debit, pledge.weth.credit);
        // for address(this), this ^^^^^^^^^^^^^^^^^^
        // is ETH amount (that we're hedging), and
        // for depositors it's the $ value hedged
    } // continuous payment from Uniswap LP fees
     // with a fixed charge (deductible) payable
     // upfront (upon deposit), 1/2 on withdrawal
     // deducted as a % FEE from the $ value which
     // is either being deposited, or moved in fold
    struct Pod { // for pledge.weth this amounts to
        uint credit; // sum[amt x price at deposit]
        uint debit; //  quantity of tokens pledged
    } /* carry.credit = contribution to weighted...
    ...SUM of (QD / total QD) x (ROI / avg ROI) */
    uint public SUM = 1; uint public AVG_ROI = 1;
    struct Offer { Pod weth; Pod carry; Pod work;
    Pod last; } // timestamp of last liquidation,
    // amt that was liquidated (smaller over time)
    // for address(this) it's time since NFPM.burn
    // work is like a checking account (credit can
    // be drawn against it) while weth is savings,
    // but it pays interest to the contract itself;
    // together, and only if used in combination,
    // they form an insured revolving credit line;
    // carry is relevant for redemption purposes.
    // fold() holds depositors accountable for
    // work, as well as accountability for weth
    function setQuid(address _quid) 
        external { QUID = Quid(_quid);
            require(QUID.Moulinette()
             == address(this), "42");
    }
    modifier onlyQuid {
        require(msg.sender
            == address(QUID),
            "unauthorised"); _;
    }
    receive() external payable {}
    function setFee(uint index)
        public onlyQuid { FEE =
        WAD / (index + 11); }
    // recall the 3rd Delphic maxim...
    mapping (address => Offer) pledges;
    function setMetrics(uint avg_roi) public
        onlyQuid { AVG_ROI = avg_roi;
    } // this is the only essential one
    // TODO add informative metrics...
    function dollar_amt_to_qd_amt(uint cap, 
        uint amt) public view returns (uint) {
            if (cap == 0) { 
                (, cap) = capitalisation(0, false);
            }
            return FullMath.mulDiv(amt,
              100 + (100 - cap), 100);
    }
    // not same as eponymous function in QD
    function qd_amt_to_dollar_amt(uint cap,
        uint amt) public view returns (uint) {
        if (cap == 0) {
            (, cap) = capitalisation(0, false);
        }
        return FullMath.mulDiv(amt, cap, 100);
    }

    function set_price_eth(bool up,
        bool refresh) external {
        (uint160 sqrtPriceX96
          ,,,,,,) = POOL.slot0();
        if (refresh) { _ETH_PRICE = 0;
          _ETH_PRICE = getPrice(sqrtPriceX96);
        } else { uint delta = _ETH_PRICE / 5;
            _ETH_PRICE = up ? _ETH_PRICE + delta
                            : _ETH_PRICE - delta;
        } // TODO remove this testing function...
    }

    constructor(address _weth, address _usdc,
        address _nfpm, address _pool, 
        address _router) { USDC = _usdc;
        WETH9 = WETH(payable(_weth));
        POOL = IUniswapV3Pool(_pool);
        ROUTER = ISwapRouter(_router);
        NFPM = INonfungiblePositionManager(_nfpm);
        token0 = ERC20(POOL.token0());
        token1 = ERC20(POOL.token1());
        token0.approve(_router, 
            type(uint256).max);
        token0.approve(_nfpm,
            type(uint256).max);
        token1.approve(_nfpm,
            type(uint256).max);
        token1.approve(_router,
            type(uint256).max);
        token1isWETH = address(token0) == USDC;
        // needed as order is swapped on Base
    } 

    // present value of the expected cash flows
    function capitalisation(uint qd, bool burn)
        public view returns (uint, uint) { // ^ in QD
        (uint160 sqrtPriceX96,,,,,,) = POOL.slot0();
        uint price = getPrice(sqrtPriceX96); // in $
        Offer memory pledge = pledges[address(this)];
        // collateral may be sold or claimed in fold
        uint collateral = FullMath.mulDiv(price,
            pledge.work.credit, WAD // in $
        ); // collected in deposit and fold
        uint deductibles = FullMath.mulDiv(
            price, pledge.weth.debit, WAD // $
        ); // weth.debit is ETH owned by contract
        // total composition of solvency capital:
        uint assets = collateral + deductibles +
            // USDC (upscaled for precision)...
            QUID.get_total_deposits(true);
        // not incl. pledge.weth.credit,
        // which are insured liabilities
        uint total = QUID.totalSupply();
        if (qd > 0) { total = (burn) ?
            total - qd : total + qd;
        }   if (assets >= total) 
            { return (0, 100); }
            else { return ((total - assets),
            FullMath.mulDiv(100, assets, total));
        }
    } 

    // helpers allow treating QD balances
    // uniquely without needing ERC721...
    function transferHelper(address from,
      address to, uint amount, // in QD
      uint priorBalance) onlyQuid // ^
            public returns (uint) {
            if (to == address(this)) { // TODO in fold
                uint credit = pledges[from].work.credit;
                (, uint cap) = capitalisation(amount, true);
                uint burn = FullMath.min(
                    qd_amt_to_dollar_amt(
                   cap, amount), credit);
                require(amount <= 
                dollar_amt_to_qd_amt(cap, burn), "?$?");
                pledges[from].work.credit -= burn; 
                return burn;
            } else if (to != address(0)) {
            // percentage of carry.debit gets
            // transferred over in proportion
            // to amount's % of total balance
            // determine % of total balance
            // transferred for ROI pro rata
            uint ratio = FullMath.mulDiv(WAD,
                amount, priorBalance);
            require(ratio <= WAD, "not enough");
            // proportionally transfer debit...
            uint debit = FullMath.mulDiv(ratio,
            pledges[from].carry.debit, WAD);
            pledges[to].carry.debit += debit;
            pledges[from].carry.debit -= debit;
            // pledges[address(this)].carry.debit
            // remains constant; handled case-by-
            // case in helper (pledge.carry.credit)
            // QD minted in coverage claims or
            // over-collateralisation does not
            // transfer over carry.credit b/c
            // carry credit only gets created
            // in the discounted mint windows
            _creditHelper(to);
        }   _creditHelper(from);
            return amount;
    }
    function _creditHelper(address who) internal {
        uint credit = pledges[who].carry.credit;
        SUM -= FullMath.min(SUM, credit); // old_share--
        // may be zero if this is the first time
        // _creditHelper is called for `who`...
        uint balance = QUID.balanceOf(who);
        uint debit = pledges[who].carry.debit;
        uint share = FullMath.mulDiv(WAD,
            balance, QUID.totalSupply());
        credit = share; // workaround from using NFT
        if (debit > 0 && QUID.currentBatch() > 0) {
            // projected ROI if QD is $1...
            uint roi = FullMath.mulDiv(WAD,
                    balance - debit, debit);
            // calculate individual ROI over total...
            roi = FullMath.mulDiv(WAD, roi, AVG_ROI);
            credit = FullMath.mulDiv(roi, share, WAD);
            // credit is the product (composite) of
            // two separate share (ratio) quantities
            // and the sum of products is what we use
            // in determining pro rata in redeem()
        }   pledges[who].carry.credit = credit;
        SUM += credit; // update sum with new share
    }

    function _repackNFT(uint amount0,uint amount1,
        uint price) internal { uint128 liquidity;
        uint last = flashLoanProtect[address(this)];
        flashLoanProtect[address(this)] = block.number;
        if (pledges[address(this)].last.credit != 0) { // TODO twap
            // not the first time _repackNFT is called
            if ((LAST_TICK > UPPER_TICK || LAST_TICK < LOWER_TICK) &&
            // "to improve is to change, to perfect is to change often"
            block.timestamp - pledges[address(this)].last.credit >= 10 minutes) {
                // && last != block.number) // TODO uncomment for deployment) {
                // we want to make sure that all of the WETH deposited to this
                // contract is always in range (collecting), and range is ~7%
                // below and above tick, as voltage regulators watch currents
                // and control a relay (which turns on & off the alternator,
                // if below or above 12 volts, (re-charging battery as such)
                (,,,,,,, liquidity,,,,) = NFPM.positions(ID);
                (uint collected0,
                 uint collected1) = _withdrawAndCollect(liquidity);
                amount0 += collected0; amount1 += collected1;
                // temporary displacement just like _creditHelper
                if (token1isWETH) {
                    pledges[address(this)].weth.debit -= FullMath.min(
                        collected1, pledges[address(this)].weth.debit);
                    pledges[address(this)].work.debit -= FullMath.min(
                        collected0, pledges[address(this)].work.debit);
                } else {
                    pledges[address(this)].weth.debit -= FullMath.min(
                        collected0, pledges[address(this)].weth.debit);
                    pledges[address(this)].work.debit -= FullMath.min(
                        collected1, pledges[address(this)].work.debit);
                } NFPM.burn(ID); 
            }
        } if (liquidity > 0 || ID == 0) { // 1st time or repack
            (UPPER_TICK, LOWER_TICK) = _adjustTicks(LAST_TICK);
            if (token1isWETH) { (amount1, amount0) = _swap(
                                 amount1, amount0, price);
            } else { (amount0, amount1) = _swap(
                      amount0, amount1, price);
            }
            (ID, liquidityUnderManagement,,) = NFPM.mint(
                INonfungiblePositionManager.MintParams({ token0: address(token0),
                    token1: address(token1), fee: POOL_FEE, tickLower: LOWER_TICK,
                    tickUpper: UPPER_TICK, amount0Desired: amount0,
                    amount1Desired: amount1, amount0Min: 0, amount1Min: 0,
                    recipient: address(this), deadline: block.timestamp }));
                    pledges[address(this)].last.credit = block.timestamp;
        } // else no need to repack NFT, only collect LP fees
        else { (uint collected0, uint collected1) = _collect();
            amount0 += collected0; amount1 += collected1;
            if (token1isWETH) { (amount1, amount0) = _swap(
                                 amount1, amount0, price);
            } else { (amount0, amount1) = _swap(
                      amount0, amount1, price);
            }
            (liquidity,,) = NFPM.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams(
                    ID, amount0, amount1, 0, 0, block.timestamp));
                    liquidityUnderManagement += liquidity;
        }
        if (token1isWETH) {
            pledges[address(this)].weth.debit += amount1;
            pledges[address(this)].work.debit += amount0;
        }
        else {
            pledges[address(this)].weth.debit += amount0;
            pledges[address(this)].work.debit += amount1;
        }
    }
    function repackNFT() public nonReentrant {
        (uint160 sqrtPriceX96,,,,,,) = POOL.slot0();
        _repackNFT(0, 0, getPrice(sqrtPriceX96));
        // TODO test ID before and after, after
        // set_price_eth
    }
    // from v3-periphery/OracleLibrary...
    function getPrice(uint160 sqrtRatioX96)
        public view returns (uint price) {
        if (_ETH_PRICE > 0) { // TODO
            return _ETH_PRICE; // remove
        }
        // console.log("consulted price", _consult());
        uint casted = uint(sqrtRatioX96);
        uint ratioX128 = FullMath.mulDiv(
          casted, casted, 1 << 64);

        if (token1isWETH) {
            price = FullMath.mulDiv(
                1 << 128, 
                WAD * 1e12, 
                ratioX128
            );
        } else { // token1 is not WETH
            price = FullMath.mulDiv(
                ratioX128, 
                WAD * 1e12, 
                1 << 128
            );
        }
        console.log("**** THE RETRIEVED PRICE *****", price);
    }
    function _collect() internal returns
        (uint amount0, uint amount1) {
        (amount0, amount1) = NFPM.collect(
            INonfungiblePositionManager.CollectParams(ID,
                address(this), type(uint128).max, type(uint128).max
            ) // "collect calls to the tip sayin' how ya changed"
        ); //
    }
    function _withdrawAndCollect(uint128 liquidity)
        internal returns (uint amount0, uint amount1) {
        require(liquidity > 0, "nothing to decrease");
        if (liquidity > liquidityUnderManagement) {
            liquidity = liquidityUnderManagement;
            liquidityUnderManagement = 0;
        } else {
            liquidityUnderManagement -= liquidity;
        }
        NFPM.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams(
                ID, liquidity, 0, 0, block.timestamp
            )
        );  (amount0, // collect includes proceeds from the decrease...
             amount1) = _collect(); // above + fees since last collect
    }
    function _adjustToNearestIncrement(int24 input)
        internal pure returns (int24 result) {
        int24 remainder = input % 10; // 10
        // is the tick width for WETH<>USDC...
        if (remainder == 0) { result = input;
        } else if (remainder >= 5) { // round up
            result = input + (10 - remainder);
        } else { // round down instead...
            result = input - remainder;
        } // just here as sanity check
        if (result > 887220) { // max
            return 887220;
        } else if (-887220 > result) {
            return -887220;
        }   return result;
    } // adjust to the nearest multiple of our tick width
    function _adjustTicks(int24 twap) internal pure returns
        (int24 adjustedIncrease, int24 adjustedDecrease) {
        // dynamic width of the gap depending on % delta vol TODO
        int256 upper = int256(WAD + (WAD / 28));
        int256 lower = int256(WAD - (WAD / 28));
        int24 increase = int24((int256(twap) * upper) / int256(WAD));
        int24 decrease = int24((int256(twap) * lower) / int256(WAD));
        adjustedIncrease = _adjustToNearestIncrement(increase);
        adjustedDecrease = _adjustToNearestIncrement(decrease);
        if (adjustedIncrease == adjustedDecrease) { // edge case
            adjustedIncrease += 10;
        }
    }
    function _consult() internal 
        view returns (int24 mean) { 
        uint32[] memory ago = new 
        uint32[](2); ago[0] = 28800; ago[1] = 0;
        (int56[] memory ticks,) = POOL.observe(ago);
        int56 delta = ticks[1] - ticks[0]; 
        int56 since = int56(int32(ago[0]));
        mean = int24(delta / since);
        if (delta < 0 &&  (delta
         % since != 0)) mean--;
    } // TODO reverts with "OLD"

    function _swap(uint eth, uint usdc, 
        uint price) internal returns 
        (uint delta0, uint delta1) {
        uint scaled = usdc * 1e12;
        uint in_usd = FullMath.mulDiv(eth, 
                          price, WAD);
        
        int delta = (int(in_usd) - int(scaled))
                   / int(2 * price / 1e18);
    
        uint selling; uint surplus;
        if (delta > 0) { // sell eth
            selling = uint(delta);
            eth -= selling;
            usdc += ROUTER.exactInput(
                ISwapRouter.ExactInputParams(abi.encodePacked(
                    address(WETH9), POOL_FEE, USDC), address(this),
                    block.timestamp, selling, 0));
        }
        else if (delta < 0) {
            selling = uint(delta * -1);
            selling = FullMath.mulDiv(
                selling, price, 1e30);
            usdc -= selling;
            eth += ROUTER.exactInput(
                ISwapRouter.ExactInputParams(abi.encodePacked(
                    USDC, POOL_FEE, address(WETH9)), address(this),
                    block.timestamp, selling, 0));
        }
        uint160 lower = TickMath.getSqrtPriceAtTick(LOWER_TICK);
        uint160 upper = TickMath.getSqrtPriceAtTick(UPPER_TICK);
        uint160 current = TickMath.getSqrtPriceAtTick(LAST_TICK);
        uint128 liquidity = token1isWETH ?
            LiquidityAmounts.getLiquidityForAmount1(
                              current, upper, eth) :
            LiquidityAmounts.getLiquidityForAmount0(
                              current, upper, eth);
        (delta0,
         delta1) = LiquidityAmounts.getAmountsForLiquidity(
                          current, lower, upper, liquidity);

        if (token1isWETH) {
            if (usdc > delta0) {
                surplus = usdc - delta0;
                // send surplus to Morpho
                ERC4626(QUID.VAULT()).deposit(
                surplus, address(QUID));
                    usdc = delta0;
            }
            else if (usdc < delta0) {
                usdc += QUID.withdrawUSDC(
                            delta0 - usdc);
            }
        } else {
            if (usdc > delta1) {
                surplus = usdc - delta1;
                ERC4626(QUID.VAULT()).deposit(
                surplus, address(QUID));
                    usdc = delta1;
            }
            else if (usdc < delta1) {
                usdc += QUID.withdrawUSDC(
                            delta1 - usdc);
            }
        } return (eth, usdc); 
    }

    function deposit(address beneficiary, uint amount,
        bool long) external nonReentrant payable {
        Offer memory pledge = pledges[beneficiary];
        (uint160 sqrtPriceX96, int24 tick,,,,,) = POOL.slot0();
        LAST_TICK = tick; uint price = getPrice(sqrtPriceX96);
        if (amount > 0) { WETH9.transferFrom(
            msg.sender, address(this), amount);
        } else { require(msg.value > 0, "ETH!"); }
        if (msg.value > 0) { amount += msg.value;
            WETH9.deposit{ value: msg.value }();
        }   if (long) { pledge.work.debit += amount;
            pledges[address(this)].work.credit += amount;
        } //
        else { uint in_dollars = FullMath.mulDiv(price, amount, WAD);
            uint deductible = FullMath.mulDiv(in_dollars, FEE, WAD);
            // change deductible to be in units of ETH instead...
            deductible = FullMath.mulDiv(WAD, deductible, price);
            uint insured = amount - deductible; // in ETH
            pledge.weth.debit += insured; // withdrawable
            // by folding balance into pledge.work.debit...
            pledges[address(this)].weth.debit += deductible;
            pledges[address(this)].weth.credit += insured;
            pledge.weth.credit += in_dollars - deductible;
            require(pledges[address(this)].carry.debit >
              FullMath.mulDiv(pledges[address(this)].weth.credit,
                price, WAD), "over-encumbered");
        }       pledges[beneficiary] = pledge;
                token1isWETH ? _repackNFT(0, amount, price) 
                             : _repackNFT(amount, 0, price);
    }

    function mint(address to, // use in ERC20.mint
        uint cost, uint minted) public onlyQuid {
        pledges[address(this)].carry.debit += cost;
        pledges[address(this)].carry.credit += minted - cost;
        // ^needed for tracking total capitalisation...
        pledges[to].carry.debit += cost; // contingent
        // variable for ROI as well as redemption,
        // carry.credit gets reset in _creditHelper
        pledges[to].carry.credit += minted;
        _creditHelper(to); // beneficiary
    }

    // call in QD's worth (обнал sans liabilities)
    // calculates the coverage absorption for each
    // insurer by first determining their share %
    // and then adjusting based on average ROI...
    // (insurers with higher ROI absorb more)...
    // "you never count your money while you're
    // sittin' at the table...there'll be time
    function redeem(uint amount) // into $...
        external nonReentrant { // amount QD
        amount = FullMath.min(
            QUID.matureBalanceOf(
                       msg.sender), amount);
        require(amount > 0, "let it steep");
        // can be said of tea, or a t-bill too
        uint share = FullMath.mulDiv(WAD, amount,
                QUID.matureBalanceOf(msg.sender));

        // coverage includes 30% of QD minted in QUID.mint...
        // as this % supply is not 1:1 backed; also includes
        // any remaining debt on a fully liquidated pledge,
        // and QD minted in fold() as insurance coverage...
        uint absorb = FullMath.mulDiv(FullMath.mulDiv(
        // max $ pledge would absorb if redeemed 100%
        pledges[address(this)].carry.credit, // updated in helper
          FullMath.mulDiv(WAD, pledges[msg.sender].carry.credit,
            SUM), WAD), FullMath.min(QUID.currentBatch() -
              QUID.lastRedeem(msg.sender), 1), 24);
       
        if (WAD > share) { // not redeeming 100%
            absorb = FullMath.mulDiv(absorb,
                                share, WAD);
        } // helper function called by turn
        // which handles PLEDGE.CARRY.CREDIT--
        absorb = QUID.turn(msg.sender, amount);
        (, uint cap) = capitalisation(0, false);
        amount = qd_amt_to_dollar_amt(cap, amount);
        absorb = FullMath.min(absorb, amount / 3); // TODO safe max?
        amount -= absorb; amount -= QUID.morph(msg.sender, amount);
        if (amount > 0) {  
            (uint160 sqrtPriceX96,
            int24 tick,,,,,) = POOL.slot0(); LAST_TICK = tick;
            (uint amount0, uint amount1) = _withdrawAndCollect(
             LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96,
                         TickMath.getSqrtPriceAtTick(LOWER_TICK),
                         TickMath.getSqrtPriceAtTick(UPPER_TICK),
                         amount / (2 * 1e12), FullMath.mulDiv(WAD,
                            amount / 2, getPrice(sqrtPriceX96))));
            
            amount = token1isWETH ? amount0 : amount1;
            uint eth = token1isWETH ? amount1 : amount0;
            
            amount += ROUTER.exactInput(ISwapRouter.ExactInputParams(
                        abi.encodePacked(address(WETH9), POOL_FEE, USDC),
                        address(this), block.timestamp, eth, 0));
                        ERC20(USDC).transfer(msg.sender, amount);
        } pledges[address(this)].carry.credit -= absorb;
        // } else { pledges[address(this)].carry.credit -= amount; }
        // "I said see you at the top, and they misunderstood me:
        // I hold no resentment in my heart, that's that maturity;
    } // and we don't keep it on us anymore," ain't no securities

    // Quid says if amount is QD...
    // ETH can only be withdrawn from
    // pledge.work.debit; if ETH was
    // deposited pledge.weth.debit,
    // call fold() before withdraw()
    function withdraw(uint amount, bool quid)
        external nonReentrant payable {
        uint amount0; uint amount1;
        (uint160 sqrtPriceX96,
        int24 tick,,,,,) = POOL.slot0();
        LAST_TICK = tick; // chinches
        uint price = getPrice(sqrtPriceX96);
        Offer memory pledge = pledges[msg.sender]; // TODO uncomment
        // require(flashLoanProtect[msg.sender] != block.number,
        //             "can't fold & withdraw in same block");
        if (quid) { // amount is in units of QD
            if (msg.value > 0) { amount1 = msg.value;
                WETH9.deposit{ value: amount1 }();
                pledges[address(this)].work.credit +=
                amount1; pledge.work.debit += amount1;
            }   uint debit = FullMath.mulDiv(price,
                             pledge.work.debit, WAD);
            uint haircut = debit - (debit / 9);
            require(haircut >= pledge.work.credit && haircut > 0, "CR"); 
            amount = FullMath.min(amount, haircut - pledge.work.credit);
            if (amount > 0) { pledge.work.credit += amount;
                (, uint cap) = capitalisation(amount, false);
                amount = dollar_amt_to_qd_amt(cap, amount);
                QUID.mint(msg.sender, amount, address(QUID));
            } //
        } else { uint withdrawable; // of ETH collateral (work.debit)
            if (pledge.work.credit > 0) { // see if we owe debt on it
                uint debit = FullMath.mulDiv( // dollar value of ETH
                    price, pledge.work.debit, WAD);
                uint haircut = debit - debit / 9;
                require(haircut >= pledge.work.credit, "CR!");
                withdrawable = FullMath.mulDiv(WAD,
                    haircut - pledge.work.credit, price);
            } uint transfer = amount; 
            if (transfer > withdrawable) {
                // recalculate based on how much
                // will remain after clearing...
                withdrawable = FullMath.mulDiv(
                WAD, pledge.work.credit, price); 
                uint on_hand = qd_amt_to_dollar_amt(0,
                        QUID.balanceOf(address(QUID)));
                if (on_hand >= pledge.work.credit) {
                    QUID.transferFrom(address(QUID), msg.sender, 
                         dollar_amt_to_qd_amt(0, pledge.work.credit));
                    
                    pledge.work.debit -= withdrawable;
                    // sell ETH...to clear work.credit of pledge...
                    pledges[address(this)].weth.debit += withdrawable; 
                    transfer = FullMath.min(amount, pledge.work.debit);
                    pledge.work.debit -= transfer;
                }
            }   require(transfer > 0, "nothing to withdraw");
            pledges[address(this)].work.credit -= transfer;
            // for unwrapping from Uniswap to transfer ETH
            uint usdc = FullMath.mulDiv(price, 
                transfer / 2, WAD * 1e12);
            if (token1isWETH) {
                amount1 = transfer / 2;
                amount0 = usdc;
            } else { amount1 = usdc;
                amount0 = transfer / 2;
            }
            (amount0, amount1) = _withdrawAndCollect(
                LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96,
                    TickMath.getSqrtPriceAtTick(LOWER_TICK),
                    TickMath.getSqrtPriceAtTick(UPPER_TICK),
                    amount0, amount1));      
            if (!token1isWETH) { // increase amount0 (eth) by amount1 sold
                amount0 += ROUTER.exactInput(ISwapRouter.ExactInputParams(
                    abi.encodePacked(address(token1), POOL_FEE, address(token0)),
                    address(this), block.timestamp, amount1, 0)); amount1 = 0;
                    transfer = FullMath.min(transfer, amount0);
                    amount0 -= transfer; 
            } else { // increase amount1 by selling amount0 (usdc) for eth
                amount1 += ROUTER.exactInput(ISwapRouter.ExactInputParams(
                    abi.encodePacked(address(token0), POOL_FEE, address(token1)),
                    address(this), block.timestamp, amount0, 0)); amount0 = 0;
                    transfer = FullMath.min(transfer, amount1);
                    amount1 -= transfer; 
            } WETH9.withdraw(transfer); 
            (bool success, ) = msg.sender.call{value: transfer}("");
            require(success, "$"); _repackNFT(amount0, amount1, price); 
        }   pledges[msg.sender] = pledge;
    }

    // "Entropy" comes from a Greek word for transformation;
    // Clausius interpreted as the magnitude of the degree
    // to which things separate from each other: "so close
    // no matter how far...love be in it like you couldn’t
    // believe, or work like I could've scarcely imagined;
    // if one isn’t satisfied, indulge the latter, ‘neath
    // the halo of a street-lamp, I turn my [straddle] to
    // the cold and damp...know when to hold 'em...know
    // when to..."
    function fold(address beneficiary, uint amount, bool sell)
        external payable nonReentrant { FoldState memory state;
        (uint160 sqrtPriceX96, int24 tick,,,,,) = POOL.slot0();
        LAST_TICK = tick; state.price = getPrice(sqrtPriceX96);
        // call in collateral that's insured, or liquidate;
        // if there is an insured event, QD may be minted,
        // or simply clear the debt of a long position...
        // "we can serve our [wick nest] or we can serve
        // our purpose, but not both" ~ Mother Cabrini
        // "menace ou prière, L'un parle bien, l'autre 
        // se tait; et c'est l'autre que je préfère"
        Offer memory pledge = pledges[beneficiary];
        flashLoanProtect[beneficiary] = block.number;
        amount = FullMath.min(amount, pledge.weth.debit);
        (, state.cap) = capitalisation(0, false); 
        // gzip у джинсы, зупинившись
        if (pledge.work.credit > 0) {
            console.log("state.collat...", state.collat);
            state.collat = FullMath.mulDiv(
                state.price, pledge.work.debit, WAD
            );  // "lookin' too hot; simmer down" ~ Bob Marley...
            if (pledge.work.credit > state.collat) { // "or soon"
                state.repay = pledge.work.credit - state.collat;
                state.repay += state.collat / 10; // you'll get
                state.liquidate = true; // dropped, reversibly...
            } else { // for using claimed coverage to payoff debt
                state.delta = state.collat - pledge.work.credit;
                if (state.collat / 10 > state.delta) {
                    state.repay = (state.collat / 10) - state.delta;
                }
            } 
        } if (amount > 0 && pledge.weth.debit > 0) {
            state.collat = FullMath.mulDiv(amount, state.price, WAD);
            state.average_price = FullMath.mulDiv(WAD,
                pledge.weth.credit, pledge.weth.debit
            ); // ^^^^^^^^^^^^^^^^ must be in dollars
            state.average_value = FullMath.mulDiv(
                amount, state.average_price, WAD
            );
            pledges[address(this)].work.credit += amount; pledge.work.debit += amount;
            // if price drop above 10% (average_value > 10% more than current value)...
            if (state.average_price >= FullMath.mulDiv(110, state.price, 100)) {
                state.delta = state.average_value - state.collat;
                if (!sell) { state.minting = state.delta;
                    state.deductible = FullMath.mulDiv(WAD,
                        FullMath.mulDiv(state.collat, FEE, WAD),
                        state.price
                    ); // the sell method ensures that
                    // ETH will always be bought at dips
                    // so it's practical for the protocol
                    // to hold on to it (prices will rise)
                } else if (!state.liquidate) {
                    // if liquidate = true it
                    // will be a sale anyway...
                    state.deductible = amount;
                    state.minting = state.collat -
                        FullMath.mulDiv( // deducted
                            state.collat, FEE, WAD);
                } if (state.repay > 0) { // capitalise into credit
                    state.cap = FullMath.min(state.minting, state.repay);
                    // ^^^^^^ variable reused to save space...
                    pledge.work.credit -= state.cap;
                    state.minting -= state.cap;
                    state.repay -= state.cap;
                }   (, state.cap) = capitalisation(state.delta, false);
                if (state.minting > state.delta || state.cap > 69) {
                // minting will equal delta unless it's a sell, and if it's not,
                // we can't mint coverage if the protocol is under-capitalised...
                    state.minting = dollar_amt_to_qd_amt(state.cap, state.minting);
                    QUID.mint(beneficiary, state.minting, address(QUID));
                    pledges[address(this)].carry.credit += state.delta;
                }   else { state.deductible = 0; } // no mint = no charge
            }   else if (!state.liquidate) { require(
                    msg.sender == beneficiary, "auth");
            }
            pledges[address(this)].weth.credit -= amount;
            // amount is no longer insured by the protocol
            pledge.weth.debit -= amount; // deduct amount
            pledge.weth.credit -= FullMath.min(pledge.weth.credit,
                                            state.average_value);
            // if we were to deduct actual value instead
            // it could be taken advantage of (increased
            // payouts with each subsequent call to fold)
            pledge.work.debit = (msg.value + pledge.work.debit) -
            state.deductible; // if sell true...pledge doesn't
            // get any ETH back that they can withdraw(), but QD
            pledges[address(this)].work.credit -= state.deductible;
            pledges[address(this)].weth.debit += state.deductible;

            state.collat = FullMath.mulDiv(pledge.work.debit, state.price, WAD);
            if (state.collat > pledge.work.credit) { state.liquidate = false; }
        }   // "things have gotten closer to the sun, and I've done things
            // in small doses, so don't think that I'm pushing you away;
            // iron spits, cats fold, infact they get their life froze"
        if (state.liquidate) { // "⚡️ strikes and the 🏀 court lights
            (, state.cap) = capitalisation(state.repay, true); // get
            amount = FullMath.min(dollar_amt_to_qd_amt(state.cap, // dim...
                state.repay), QUID.balanceOf(beneficiary));
            console.log("liquidating");
            QUID.transferFrom(beneficiary, address(this), amount);
            amount = qd_amt_to_dollar_amt(state.cap, amount);
            pledge.work.credit -= amount; // -- $ value of QD
            state.delta = block.timestamp - pledge.last.credit;
            if (pledge.work.credit > state.collat) {
                if (pledge.work.credit > WAD * 10
                    && state.delta >= 10 minutes) {
                    // liquidation bot doesn't
                    // skip a chance to fold()
                    state.delta /= 10 minutes;
                    // six of this per hour...
                    amount = FullMath.min(pledge.work.debit,
                        FullMath.max(pledge.last.debit + 
                            pledge.last.debit / 28, FullMath.mulDiv(
                                state.delta, pledge.work.debit, 6048)));
                                            // 1008 hours is 42 days...
                                            // 6 * 10 mins per hour...
                    pledges[address(this)].weth.debit += amount;
                    pledge.work.debit -= amount;
                    amount = FullMath.min(pledge.work.credit,
                    FullMath.mulDiv(state.price,amount, WAD));
                    // "It's like inch by inch, and step by
                    // step, I'm closin' in on your position"
                    pledge.last.debit = amount; 
                    pledge.work.credit -= amount; 
                    //
                    pledge.last.credit = block.timestamp; // up to
                } else { pledges[address(this)].weth.debit += pledge.work.debit;
                    pledges[address(this)].carry.credit += pledge.work.credit;
                    // debt surplus absorbed ^^^^^^^^^ as if it were coverage
                    pledge.work.credit = 0; pledge.work.debit = 0; // reset
                    pledge.last.credit = 0; pledge.last.debit = 0; // storage
                }   // Thinkin' about them licks I hit, I had to
            } 
        } else if (pledge.last.credit != 0) {
            pledge.last.credit = 0;
            pledge.last.debit = 0;
        }   pledges[beneficiary] = pledge;
    }
}
