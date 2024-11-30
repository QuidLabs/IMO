
// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25; // EVM: london
import {Quid} from "./QD.sol"; // ERC777
import "lib/forge-std/src/console.sol"; // TODO delete logging and set_price_eth

import {TickMath} from "./interfaces/math/TickMath.sol";
import {FullMath} from "./interfaces/math/FullMath.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";
import {LiquidityAmounts} from "./interfaces/math/LiquidityAmounts.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
// import {IV3SwapRouter as ISwapRouter} from "./interfaces/IV3SwapRouter.sol"; // TODO only for Sepolia
import {WETH} from "lib/solmate/src/tokens/WETH.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";
import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";

contract MO is ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for WETH;
    ERC20 public immutable token1;
    ERC20 public immutable token0;
    WETH public immutable WETH9;
    uint public ID; // V3 NFT
    uint constant WAD = 1e18;
    uint public FEE = WAD / 28;
    uint constant RACK = 1000 * WAD;
    uint24 constant POOL_FEE = 500;
    uint constant REV = POOL_FEE / 10;
    INonfungiblePositionManager NFPM;
    int24 internal LAST_TWAP_TICK;
    int24 internal UPPER_TICK;
    int24 internal LOWER_TICK;
    uint internal _ETH_PRICE; // TODO delete
    IUniswapV3Pool POOL; ISwapRouter ROUTER;
    uint128 liquidityUnderManagement; // UniV3
    mapping(address => uint) flashLoanProtect;
    // TODO storage perecentage delta in vol
    struct FoldState { uint delta; uint price;
        uint average_price; uint average_value;
        uint deductible; uint cap; uint minting;
        bool liquidate; uint repay; uint collat;
    }   Quid QUID; // tethered to the MO contract
    function get_info(address who) view
        external returns (uint, uint) {
        Offer memory pledge = pledges[who];
        return (pledge.carry.debit, QUID.balanceOf(who));
        // this is more of an internal tracking variable
    }   function get_more_info(address who) view
        external returns (uint, uint, uint, uint) {
        Offer memory pledge = pledges[who];
        return (pledge.work.debit, pledge.work.credit,
                pledge.weth.debit, pledge.weth.credit);
        // for address(this), this ^^^^^^^^^^^^^^^^^^
        // is ETH amount (that we're insuring), and
        // for depositors it's the $ value insured
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
    function _min(uint _a, uint _b)
        internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }
    function _max(uint _a, uint _b)
        internal pure returns (uint) {
        return (_a > _b) ? _a : _b;
    }
    function setFee(uint index)
        public onlyQuid { FEE =
        WAD / (index + 11); }
    // recall the 3rd Delphic maxim...
    mapping (address => Offer) pledges;
    function setMetrics(uint avg_roi) public
        onlyQuid { AVG_ROI = avg_roi;
    }
    function dollar_amt_to_qd_amt(uint cap,
        uint amt) public pure returns (uint) {
            return FullMath.mulDiv(amt,
            100 + (100 - cap), 100);
    }
    // not same as eponymous function in QD
    function qd_amt_to_dollar_amt(uint cap,
        uint amt) public pure returns (uint) {
        return FullMath.mulDiv(amt, cap, 100);
    }
    
    function set_price_eth(bool up,
        bool refresh) external {
        (uint160 sqrtPriceX96,,,,,,) = POOL.slot0();
        if (refresh) { _ETH_PRICE = 0;
            _ETH_PRICE = getPrice(sqrtPriceX96);
        }   else { uint delta = _ETH_PRICE / 5;
            _ETH_PRICE = up ? _ETH_PRICE + delta
                              : _ETH_PRICE - delta;
        } // TODO remove this testing function...
    }

    constructor(address _weth, address _nfpm,
        address _pool, address _router) {
        WETH9 = WETH(payable(_weth));
        POOL = IUniswapV3Pool(_pool);
        ROUTER = ISwapRouter(_router);
        NFPM = INonfungiblePositionManager(_nfpm);
        token0 = ERC20(IUniswapV3Pool(_pool).token0());
        token1 = ERC20(IUniswapV3Pool(_pool).token1());
        token0.approve(_router, type(uint256).max);
        token1.approve(_router, type(uint256).max);
        token0.approve(_nfpm, type(uint256).max);
        token1.approve(_nfpm, type(uint256).max);
    }

    // present value of the expected cash flows...
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
        }   if (assets >= total) { return (0, 100); }
            else { return ((total - assets),
            FullMath.mulDiv(100, assets, total));
        }
    }

    // helpers allow treating QD balances
    // uniquely without needing ERC721...
    function transferHelper(address from, address to, 
        uint amount, uint priorBalance)
        onlyQuid public returns (uint) {
            if (to == address(this)) {
                uint credit = pledges[from].work.credit;
                (, uint cap) = capitalisation(amount, true);
                uint burn = _min(qd_amt_to_dollar_amt(cap, amount), credit);
                require(amount <= dollar_amt_to_qd_amt(cap, burn), "$");
                pledges[from].work.credit -= burn; return burn;
            } else if (to != address(0)) {
            // percentage of carry.debit gets
            // transferred over in proportion
            // to amount's % of total balance
            // determine % of total balance
            // transferred for ROI pro rata
            uint ratio = FullMath.mulDiv(WAD,
                amount, priorBalance);
            require(ratio <= WAD, "not enough");
            console.log("TransferHelperEvent...", ratio);
            // proportionally transfer debit...
            uint debit = FullMath.mulDiv(ratio,
            pledges[from].carry.debit, WAD);
            console.log("DebitTransferHelper...", debit);
            pledges[to].carry.debit += debit;
            pledges[from].carry.debit -= debit;
            // pledge.carry.credit in helper...
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
        SUM -= _min(SUM, credit); // old_share--
        // may be zero if this is the first time
        // _creditHelper is called for `who`...
        uint balance = QUID.balanceOf(who);
        uint debit = pledges[who].carry.debit;
        uint share = FullMath.mulDiv(WAD,
            balance, QUID.totalSupply());
        console.log("CreditHelperShare...", share, who);
        credit = share; // workaround from using NFT
        if (debit > 0 && QUID.currentBatch() > 0) {
            // projected ROI if QD is $1...
            uint roi = FullMath.mulDiv(WAD,
                    balance - debit, debit);
            // calculate individual ROI over total...
            roi = FullMath.mulDiv(WAD, roi, AVG_ROI);
            credit = FullMath.mulDiv(roi, share, WAD);
            console.log("CreditHelperROI...", roi, who);
            // credit is the product (composite) of
            // two separate share (ratio) quantities
            // and the sum of products is what we use
            // in determining pro rata in redeem()...
        }   pledges[who].carry.credit = credit;
        SUM += credit; // update sum with new share
        console.log("CreditHelper...", credit, who);
    }

    function getPrice(uint160 sqrtPriceX96)
        public view returns (uint) {
        if (_ETH_PRICE > 0) { // TODO b4 12/12
            return _ETH_PRICE; // remove local
        }   return FullMath.mulDiv( // testing
            uint(sqrtPriceX96) * 1e7, // only
            uint(sqrtPriceX96) * 1e7, // 1:1
            2 ** 192) / 10; // for precision
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
        // dynamic width of the gap depending on volume TODO
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
    function _swap(uint amount0, uint amount1,
        uint price) internal returns (uint, uint) {
        uint scaled = amount0 * 1e12;
        uint in_usd = FullMath.mulDiv(
                amount1, price, WAD);
        if (in_usd > scaled && // from QUID.mint...
            token0.balanceOf(address(this)) > 0) {
            amount0 = _min((in_usd - scaled) / 1e12,
                token0.balanceOf(address(this)));
        } else if (scaled > in_usd) { scaled = in_usd;
                            amount0 = in_usd / 1e12;
        } int delta = (int(in_usd) - int(scaled))
                      / int(2 * price / 1e18);
        uint selling;
        if (delta > 0) {
            selling = uint(delta);
            amount1 -= selling;
            amount0 += ROUTER.exactInput(
                ISwapRouter.ExactInputParams(abi.encodePacked(
                    address(token1), POOL_FEE, address(token0)),
                    address(this), block.timestamp, selling, 0));
        } else if (delta < 0) {
            selling = uint(delta * -1);
            selling = FullMath.mulDiv(
                selling, price, 1e30);
            amount0 -= selling;
            amount1 += ROUTER.exactInput(
                ISwapRouter.ExactInputParams(abi.encodePacked(
                    address(token0), POOL_FEE, address(token1)),
                    address(this), block.timestamp, selling, 0));
        }   return (amount0, amount1);
    }

    function mint(address to, // used by ERC20.mint
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
    // (insurers with higher ROI absorb more) 
    // "you never count your money while you're
    // sittin' at the table...there'll be time
    function redeem(uint amount) // into $
        external nonReentrant { // amount QD
        amount = _min(QUID.matureBalanceOf(
                        msg.sender), amount);
        require(amount > 0, "let it steep");
        // be said of tea, bill, or a mountain,
        // we're talking...accountant of monte
        // crystal: the moments when potential 
        // risks stop being hypothetical and 
        // become part of realised book value
        uint share = FullMath.mulDiv(WAD, amount, 
                QUID.matureBalanceOf(msg.sender));
            
        // coverage includes 30% of all QD minted in QUID.mint
        // as this % supply is not 1:1 backed; also includes
        // any remaining debt on a fully liquidated pledge,
        // and QD minted in fold() as insurance coverage...
        uint absorb = FullMath.mulDiv(FullMath.mulDiv(
        // maximum $ pledge would absorb if redeemed all its QD
        pledges[address(this)].carry.credit, FullMath.mulDiv(WAD, 
        pledges[msg.sender].carry.credit, SUM), WAD), _min(
        QUID.currentBatch() - QUID.lastRedeem(msg.sender), 1), 16);  
    
        if (WAD > share) { // not redeeming 100%
            absorb = FullMath.mulDiv(absorb,
                                share, WAD);
        }
        // uint last = QUID.lastRedeem();
        absorb = QUID.turn(msg.sender, amount);

        console.log("AbsorbInRedeem...", absorb);
        // helper function called by turn
        // handles PLEDGE.CARRY.CREDIT--
        (, uint cap) = capitalisation(0, false);
        amount = qd_amt_to_dollar_amt(cap, amount);
        console.log("AbsorbAmount...", amount);
        
        amount -= _min(absorb, amount / 3);
        amount -= QUID.morph(msg.sender, amount);
        if (amount > 0) { uint usdc = token0.balanceOf(address(this)) * 1e12;
            if (usdc > amount) { token0.transfer(msg.sender, amount); }
            else { (uint160 sqrtPriceX96, int24 tick,,,,,) = POOL.slot0();
                LAST_TWAP_TICK = tick; amount -= usdc;
                (uint amount0, uint amount1) = _withdrawAndCollect(
                    LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96,
                        TickMath.getSqrtPriceAtTick(LOWER_TICK),
                        TickMath.getSqrtPriceAtTick(UPPER_TICK),
                        amount / (2 * 1e12), FullMath.mulDiv(WAD,
                        amount / 2, getPrice(sqrtPriceX96))));
                require(amount0 > 0 && amount1 > 0, "nothing withdrawn");
                amount0 += ROUTER.exactInput(ISwapRouter.ExactInputParams(
                    abi.encodePacked(address(token1), POOL_FEE, address(token0)),
                    address(this), block.timestamp, amount1, 0));
                token0.transfer(msg.sender, usdc / 1e12 + amount0);
            }
        }    pledges[address(this)].carry.credit -= absorb;
        // } else { pledges[address(this)].carry.credit -= amount; }
        // "I said see you at the top, and they misunderstood me:
        // I hold no resentment in my heart, that's that maturity;
    } // and we don't keep it on us anymore," ain't no securities

    // Quid says if amount is QD...
    // ETH can only be withdrawn from
    // pledge.work.debit; if ETH was
    // deposited pledge.weth.debit,
    // call fold() before withdraw():
    // form of flash loan protection
    function withdraw(uint amount, bool quid) 
        external nonReentrant payable {
        uint amount0; uint amount1;
        (uint160 sqrtPriceX96,
        int24 tick,,,,,) = POOL.slot0();
        LAST_TWAP_TICK = tick; // chinches
        uint price = getPrice(sqrtPriceX96);
        Offer memory pledge = pledges[msg.sender]; // TODO uncomment
        // require(flashLoanProtect[msg.sender] != block.number,
        //             "can't fold & withdraw in same block");
        if (quid) { // amount is in units of QD
            require(amount >= RACK, "too small");
            if (msg.value > 0) { amount1 = msg.value;
                WETH9.deposit{ value: amount1 }();
                pledges[address(this)].work.credit +=
                amount1; pledge.work.debit += amount1;
            }   uint debit = FullMath.mulDiv(price,
                             pledge.work.debit, WAD);
            uint haircut = debit - (debit / 5);
            require(haircut >= pledge.work.credit
            && haircut > 0, "CR"); amount = _min(
                amount, haircut - pledge.work.credit);
            if (amount > 0) { pledge.work.credit += amount;
                (, uint cap) = capitalisation(amount, false);
                amount = dollar_amt_to_qd_amt(cap, amount);
                QUID.mint(msg.sender, amount, address(QUID));
            }
        } else { uint withdrawable; // of ETH collateral (work.debit)
            if (pledge.work.credit > 0) { // see if we owe debt on it
                uint debit = FullMath.mulDiv( // dollar value of ETH
                    price, pledge.work.debit, WAD);
                uint haircut = debit - debit / 5;
                require(haircut >= pledge.work.credit, "CR!");
                withdrawable = FullMath.mulDiv(WAD,
                    haircut - pledge.work.credit, price);
            }   uint transfer = amount;
            if (transfer > withdrawable) {
                withdrawable = FullMath.mulDiv(
                    WAD, pledge.work.credit, price
                ); pledge.work.credit = 0; // clear
                pledge.work.debit -= withdrawable;
                pledges[address(this)].weth.debit += // sell ETH
                withdrawable; // to clear work.credit of pledge
                transfer = _min(amount, pledge.work.debit);
            }   require(transfer > 0, "nothing to withdraw");
            pledges[address(this)].work.credit -= transfer;
            // for unwrapping from Uniswap to transfer ETH
            (amount0, amount1) = _withdrawAndCollect(
                LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96,
                    TickMath.getSqrtPriceAtTick(LOWER_TICK),
                    TickMath.getSqrtPriceAtTick(UPPER_TICK),
                    FullMath.mulDiv(price, transfer / 2, 
                              WAD * 1e12), transfer / 2));
            if (amount0 > 0) {
                amount1 += ROUTER.exactInput(ISwapRouter.ExactInputParams(
                    abi.encodePacked(address(token0), POOL_FEE, address(token1)),
                    address(this), block.timestamp, amount0, 0)); amount0 = 0;
            }       transfer = transfer > amount1 ? amount1 : transfer;
            
            WETH9.withdraw(transfer); amount1 -= transfer;
            (bool success, ) = msg.sender.call{value: transfer}("");
            require(success, "raw"); if (amount1 > 0) { _repackNFT(
                                         amount0, amount1, price); }
        }   pledges[msg.sender] = pledge;
    }

    function deposit(address beneficiary, uint amount,
        bool long) external nonReentrant payable {
        Offer memory pledge = pledges[beneficiary];
        (uint160 sqrtPriceX96, int24 tick,,,,,) = POOL.slot0();
        LAST_TWAP_TICK = tick; uint price = getPrice(sqrtPriceX96);
        if (amount > 0) { WETH9.transferFrom( //
            msg.sender, address(this), amount);
        } else { require(msg.value > 0, "ETH!"); }
        if (msg.value > 0) { amount += msg.value;
            WETH9.deposit{ value: msg.value }();
        }   if (long) { pledge.work.debit += amount;
            pledges[address(this)].work.credit += amount;
        }   else { // 
            uint in_dollars = FullMath.mulDiv(price, amount, WAD);
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
                    price * 90 / 100, WAD), "over-encumbered");
        }           pledges[beneficiary] = pledge;
                    _repackNFT(0, amount, price);
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
        LAST_TWAP_TICK = tick; state.price = getPrice(sqrtPriceX96);
        // call in collateral that's insured, or liquidate;
        // if there is an insured event, QD may be minted,
        // or simply clear the debt of a long position...
        // "we can serve our [wick nest] or we can serve
        // our purpose, but not both" ~ Mother Cabrini
        Offer memory pledge = pledges[beneficiary];
        flashLoanProtect[beneficiary] = block.number;
        amount = _min(amount, pledge.weth.debit);
        require(amount > 0, "amount too low");
        (, state.cap) = capitalisation(0, false);
        if (pledge.work.credit > 0) {
            state.collat = FullMath.mulDiv(
                state.price, pledge.work.debit, WAD
            );  // "lookin' too hot; simmer down" ~ Bob Marley...
            if (pledge.work.credit > state.collat) { // "or soon"
                state.repay = pledge.work.credit - state.collat;
                state.repay += state.collat / 10; // you'll get
                state.liquidate = true; // dropped, reversibly...
                console.log("FoldRepayLiquidate...", state.repay);
            } else { // for using claimed coverage to payoff debt
                state.delta = state.collat - pledge.work.credit;
                if (state.collat / 10 > state.delta) {
                    state.repay = (state.collat / 10) - state.delta;
                }
                console.log("FoldRepayNoLiquidate...", state.repay);
            }
        } if (amount > 0 && pledge.weth.debit > 0) { // repossesion...
            state.collat = FullMath.mulDiv(amount, state.price, WAD);
            state.average_price = FullMath.mulDiv(WAD,
                pledge.weth.credit, pledge.weth.debit
            ); // ^^^^^^^^^^^^^^^^ must be in dollars
            state.average_value = FullMath.mulDiv(
                amount, state.average_price, WAD
            );
            console.log("Fold...", 
                state.average_price, state.average_value,
                FullMath.mulDiv(110, state.price, 100)
            );
            pledges[address(this)].work.credit += amount; pledge.work.debit += amount;
            // if price drop above 10% (average_value > 10% more than current value)...
            if (state.average_price >= FullMath.mulDiv(110, state.price, 100)) {
                state.delta = state.average_value - state.collat;
                console.log("FoldDelta...", state.delta);
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
                            state.collat, FEE, WAD
                        );
                } if (state.repay > 0) { // capitalise into credit
                    state.cap = _min(state.minting, state.repay);
                    // ^^^^^^ variable reused to save space...
                    pledge.work.credit -= state.cap;
                    state.minting -= state.cap;
                    state.repay -= state.cap;
                }   (, state.cap) = capitalisation(state.delta, false);
                if (state.minting > state.delta || state.cap > 69) {
                // minting will equal delta unless it's a sell, and if it's not,
                // we can't mint coverage if the protocol is under-capitalised...
                    state.minting = dollar_amt_to_qd_amt(state.cap, state.minting);
                    console.log("FoldMinted...", state.minting, state.delta);
                    QUID.mint(beneficiary, state.minting, address(QUID));
                    pledges[address(this)].carry.credit += state.delta;
                }   else { state.deductible = 0; } // no mint = no charge
            }   else if (!state.liquidate) { require( // TODO test
                msg.sender == beneficiary, "auth");
            }
            pledges[address(this)].weth.credit -= amount;
            // amount is no longer insured by the protocol
            pledge.weth.debit -= amount; // deduct amount
            pledge.weth.credit -= _min(pledge.weth.credit,
                                    state.average_value);
            // if we were to deduct actual value instead
            // that could be taken advantage of (increased
            // payouts with each subsequent call to fold)...
            console.log(
                "FoldDeductible...", amount,
                state.deductible
            );
            pledge.work.debit = (msg.value +
            pledge.work.debit) - state.deductible;
            // if sell true...pledge doesn't get any ETH back...
            pledges[address(this)].work.credit -= state.deductible;
            pledges[address(this)].weth.debit += state.deductible;
            
            state.collat = FullMath.mulDiv(pledge.work.debit, state.price, WAD);
            if (state.collat > pledge.work.credit) { state.liquidate = false; }
        }   // "things have gotten closer to the sun, and I've done things
            // in small doses, so don't think that I'm pushing you away;
            // iron spits, cats fold, infact they get their life froze"
        if (state.liquidate) { // "⚡️ strikes and the 🏀 court lights
            (, state.cap) = capitalisation(state.repay, true); // get
            amount = _min(dollar_amt_to_qd_amt(state.cap, // dim...
                state.repay), QUID.balanceOf(beneficiary));
            QUID.transferFrom(beneficiary, address(this), amount);
            amount = qd_amt_to_dollar_amt(state.cap, amount);
            pledge.work.credit -= amount; // -- $ value of QD
            state.delta = block.timestamp - pledge.last.credit;
            if (pledge.work.credit > state.collat) {
                if (pledge.work.credit > RACK / 10
                    && state.delta >= 10 minutes) {
                    // liquidation bot doesn't
                    // skip a chance to fold()
                    state.delta /= 10 minutes; 
                    amount = _min(pledge.work.debit,
                                _max(pledge.last.debit +
                                    pledge.last.debit / 28,
                                    FullMath.mulDiv(state.delta,
                                        pledge.work.debit, 6048)));
                    pledges[address(this)].weth.debit += amount;
                    pledge.work.debit -= amount;
                    amount = _min(pledge.work.credit,
                        FullMath.mulDiv(state.price,
                                        amount, WAD));
                    console.log("FoldLiquidate", amount);
                    // "It's like inch by inch, and step by
                    // step, I'm closin' in on your position
                    // and [eviction] is my mission"
                    // Euler’s disk 💿 erasure code 
                    pledge.work.credit -= amount;
                    pledge.last.credit = block.timestamp;
                    pledge.last.debit = amount;
                } else { // "it don't get no better than this, you catch my [dust]"
                    // otherwise we run into a vacuum leak (infinite contraction)
                    pledges[address(this)].weth.debit += pledge.work.debit;
                     pledges[address(this)].carry.credit += pledge.work.credit;
                    // debt surplus absorbed ^^^^^^^^^ as if it were coverage
                    pledge.work.credit = 0; pledge.work.debit = 0; // reset
                    pledge.last.credit = 0; pledge.last.debit = 0; // storage
                }
            }
        }   pledges[beneficiary] = pledge;
    } 

    // fold() doesn't _repackNFT (only withdraw, deposit, redeem)
    // "to improve is to change, to perfect is to change often,"
    // we want to make sure that all of the WETH deposited to
    // this contract is always in range (collecting), since
    // burn & mint is relatively costly in terms of gas, we
    // want to do that rarely...so as a rule of thumb, the
    // range is roughly 7% below and above tick, it's how
    // voltage regulators watch the currents and control a
    // relay (which turns on & off the alternator, if below
    // or above 12 volts, respectively, re-charging battery)
    function _repackNFT(uint amount0,uint amount1, 
        uint price) internal { uint128 liquidity;
        if (pledges[address(this)].last.credit != 0) {
            // not the first time _repackNFT is called
            if ((LAST_TWAP_TICK > UPPER_TICK || LAST_TWAP_TICK < LOWER_TICK) &&
                block.timestamp - pledges[address(this)].last.credit >= 1 hours) {
                (,,,,,,, liquidity,,,,) = NFPM.positions(ID);
                (uint collected0,
                 uint collected1) = _withdrawAndCollect(liquidity);
                amount0 += collected0; amount1 += collected1;
                pledges[address(this)].weth.debit -= collected1;
                pledges[address(this)].work.debit -= collected0;
                NFPM.burn(ID); // this ^^^^^^^^^^ is USDC fees
                pledges[address(this)].last.credit = block.timestamp;
            }
        } if (liquidity > 0 || ID == 0) { // first time or repack...
            (UPPER_TICK, LOWER_TICK) = _adjustTicks(LAST_TWAP_TICK);
            (amount0, amount1) = _swap(amount0, amount1, price);
            (ID, liquidityUnderManagement,,) = NFPM.mint(
                INonfungiblePositionManager.MintParams({ token0: address(token0),
                    token1: address(token1), fee: POOL_FEE, tickLower: LOWER_TICK,
                    tickUpper: UPPER_TICK, amount0Desired: amount0,
                    amount1Desired: amount1, amount0Min: 0, amount1Min: 0,
                    recipient: address(this), deadline: block.timestamp }));
        } // else no need to repack NFT, only collect LP fees
        else { (uint collected0, uint collected1) = _collect();
            amount0 += collected0; amount1 += collected1;
            (amount0, amount1) = _swap(amount0, amount1, price);
            (liquidity,,) = NFPM.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams(
                    ID, amount0, amount1, 0, 0, block.timestamp));
                    liquidityUnderManagement += liquidity;
        }   pledges[address(this)].weth.debit += amount1;
            pledges[address(this)].work.debit += amount0;
    }
    function repackNFT() external nonReentrant {
        (uint160 sqrtPriceX96,,,,,,) = POOL.slot0();
        _repackNFT(0, 0, getPrice(sqrtPriceX96));
    }
}
