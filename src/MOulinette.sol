
// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25; // EVM: london
import {Quid} from "./QD.sol"; // ERC777
import "lib/forge-std/src/console.sol"; // TODO delete
import {WETH} from "lib/solmate/src/tokens/WETH.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {TickMath} from "./interfaces/math/TickMath.sol";
import {FullMath} from "./interfaces/math/FullMath.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol"; 
// import {IV3SwapRouter as ISwapRouter} from "./interfaces/IV3SwapRouter.sol"; // TODO
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";
import {LiquidityAmounts} from "./interfaces/math/LiquidityAmounts.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";

contract MO { // Modus Operandi...
    using SafeTransferLib for ERC20;
    using SafeTransferLib for WETH;
    ERC20 public immutable token1;
    ERC20 public immutable token0;
    WETH public immutable WETH9;
    uint public ID; // V3 NFT
    uint constant WAD = 1e18;
    uint public FEE = WAD / 28;  
    uint constant DIME = 10 * WAD;
    uint24 constant POOL_FEE = 500;
    INonfungiblePositionManager NFPM;
    int24 internal LAST_TWAP_TICK;
    int24 internal UPPER_TICK; 
    int24 internal LOWER_TICK;
    uint internal _ETH_PRICE; // TODO delete
    IUniswapV3Pool POOL; ISwapRouter ROUTER; 
    uint128 liquidityUnderManagement; // UniV3
    struct FoldState { uint delta; uint price;
        uint average_price; uint average_value;
        uint deductible; uint cap; uint minting;
        bool liquidate; uint repay; uint collat; 
    }   Quid QUID; // tethered to the MO contract
    function get_info(address who) view
        external returns (uint, uint) {
        Offer memory pledge = pledges[who];
        return (pledge.carry.debit, QUID.balanceOf(who));
        // never need pledge.carry.credit in the frontend,
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
     // is either being deposited or moved in fold
    struct Pod { // for pledge.weth this amounts to
        uint credit; // sum[amt x price at deposit]
        uint debit; //  quantity of tokens pledged 
    } /* carry.credit = contribution to weighted...
    ...SUM of (QD / total QD) x (ROI / avg ROI) */
    uint public SUM = 1; uint public AVG_ROI = 1;
    // formal contracts require a specific method of 
    // formation to be enforaceable; one example is
    // negotiable instruments like promissory notes 
    // an Offer is a promise or commitment to do
    // or refrain from doing something specific
    // in the future...our case is bilateral...
    // promise for a promise, aka quid pro quo...
    struct Offer { Pod weth; Pod carry; Pod work;
    uint last; } // timestamp of last liquidate & 
    // % that's been liquidated (smaller over time)
    // for address(this) it's time since NFPM.burn
    // work is like a checking account (credit can
    // be drawn against it) while weth is savings,
    // but it pays interest to the contract itself;
    // together, and only if used in combination,
    // they form an insured revolving credit line;
    // carry is relevant for redemption purposes.
    // fold() holds depositors accountable for 
    // work, as well as accountability for weth
    function setQuid(address _quid) external 
        {  QUID = Quid(_quid); 
        require(QUID.Moulinette()
         == address(this), "42");
    } 
    modifier onlyQuid {
        require(msg.sender 
            == address(QUID), 
            "unauthorised"); _;
    }
    function setFee(uint index) 
        public onlyQuid { FEE = 
        WAD / (index + 11); }
    // recall the 3rd Delphic maxim...
    mapping (address => Offer) pledges;
    function _max(uint128 _a, uint128 _b) 
        internal pure returns (uint128) {
        return (_a > _b) ? _a : _b;
    }
    function _min(uint _a, uint _b) 
        internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }
    function setMetrics(uint avg_roi) public
        onlyQuid { AVG_ROI = avg_roi;
    }
    function dollar_amt_to_qd_amt(uint cap, uint amt) 
        public view returns (uint) { return (cap < 100) ? 
        FullMath.mulDiv(amt, 100 + (100 - cap), 100) : amt; 
    } 
    // different from eponymous function in ERC20...
    function qd_amt_to_dollar_amt(uint cap, uint amt) 
        public view returns (uint) { return (cap < 100) ? 
        FullMath.mulDiv(amt, cap, 100) : amt;
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
        public view returns (uint) { // ^ extra in QD
        uint price = QUID.getPrice(); // $ value of ETH
        // earned from deductibles and Uniswap fees
        Offer memory pledge = pledges[address(this)];
        uint collateral = FullMath.mulDiv(price,
            pledge.work.credit, WAD // in $
        ); // collected in deposit and fold
        uint deductibles = FullMath.mulDiv(
            price, pledge.weth.debit, WAD // $
        ); // composition of insurance capital:
        uint assets = collateral + deductibles + 
            // USDC (upscaled for precision)...
            (pledge.work.debit * 1e12) + 
            QUID.get_total_deposits(true);
        // doesn't account for pledge.weth.credit,
        // which are liabilities (that are insured)
        uint total = QUID.totalSupply(); 
        if (qd > 0) { total = (burn) ? 
            total - qd : total + qd;
        }
        return FullMath.mulDiv(100, assets, total); 
    }

    // helpers allow treating QD balances
    // uniquely without needing ERC721...
    function transferHelper(address from, 
        address to, uint amount) onlyQuid 
        public { if (to == address(this)) { // burn
            uint credit = pledges[from].work.credit;
            uint cap = capitalisation(amount, true); 
            uint burn = _min(qd_amt_to_dollar_amt(cap, amount), credit);
            require(amount <= dollar_amt_to_qd_amt(cap, burn), "$");
            pledges[from].work.credit -= burn; // write to storage
        } else if (to != address(0)) {
            // percentage of carry.debit gets 
            // transferred over in proportion 
            // to amount's % of total balance
            // determine % of total balance
            // transferred for ROI pro rata
            uint ratio = FullMath.mulDiv(WAD, 
                amount, QUID.balanceOf(from));
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
        credit = share; 
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

    function _liquidity(uint amount0, uint amount1) 
        internal returns (uint160, uint160, uint128) {
        uint160 sqrtPriceX96lower = TickMath.getSqrtPriceAtTick(LOWER_TICK);
        uint160 sqrtPriceX96upper = TickMath.getSqrtPriceAtTick(UPPER_TICK);
        uint128 liquidity0 = LiquidityAmounts.getLiquidityForAmount0(
            sqrtPriceX96lower, sqrtPriceX96upper, amount0
        ); 
        uint128 liquidity1 = LiquidityAmounts.getLiquidityForAmount1(
            sqrtPriceX96lower, sqrtPriceX96upper, amount1
        );
        return (sqrtPriceX96lower, sqrtPriceX96upper, 
                _max(liquidity0, liquidity1));
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
        liquidityUnderManagement -= liquidity;
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
        int256 upper = int256(WAD + (WAD / 14)); 
        int256 lower = int256(WAD - (WAD / 14));
        int24 increase = int24((int256(twap) * upper) / int256(WAD));
        int24 decrease = int24((int256(twap) * lower) / int256(WAD));
        adjustedIncrease = _adjustToNearestIncrement(increase);
        adjustedDecrease = _adjustToNearestIncrement(decrease);
        if (adjustedIncrease == adjustedDecrease) { // edge case
            adjustedIncrease += 10; 
        } 
    }
    function _swap(uint amount0, uint amount1, 
        uint160 sqrtPriceX96) internal returns 
        (uint, uint) { uint price = QUID.getPrice();
        (,, uint128 liquidity) = _liquidity(amount0, amount1);
        
        (uint positionAmount0, // target amounts for LP deposit
         uint positionAmount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96, TickMath.getSqrtPriceAtTick(LOWER_TICK), 
            TickMath.getSqrtPriceAtTick(UPPER_TICK), liquidity
        );  console.log("positionAmount0...", positionAmount0); console.log("positionAmount1...", positionAmount1); 
        uint targetRatio = positionAmount1 / (positionAmount0 + 1);
        if (token0.balanceOf(address(this)) > 0) {
            amount0 = _min(positionAmount0, 
            token0.balanceOf(address(this)));
        }   uint currentRatio = amount1 / (amount0 + 1);
        if (currentRatio <= (targetRatio * 999) / 1000 
         || currentRatio >= (targetRatio * 1001) / 1000) {
            int selling = ( // some algebra...
                int(amount1 * price / 1e18) - 
                int(amount0 * 1e12) // minus
            ) / int(2 * price / 1e18); 
            if (selling > 0) {
                amount1 -= uint(selling); 
                amount0 += ROUTER.exactInput(
                    ISwapRouter.ExactInputParams(abi.encodePacked(
                        address(token1), POOL_FEE, address(token0)),
                        address(this), block.timestamp, uint(selling), 0)
                    );
            } else { // TODO comment out block.timestamp for Taiko deploy
                selling *= int(price) / 1e30; amount0 -= uint(selling);
                amount1 += ROUTER.exactInput(ISwapRouter.ExactInputParams(
                    abi.encodePacked(address(token0), POOL_FEE, address(token1)),
                        address(this), block.timestamp, uint(selling), 0)
                );
            }   currentRatio = amount1 / amount0;
        }   return (amount0, amount1); 
    }

    // call in QD's worth (обнал sans liabilities)
    // calculates the coverage absorption for each 
    // insurer by first determining their share %
    // and then adjusting based on average ROI...
    // (insurers w/ higher avg. ROI absorb more) 
    // "you never count your money while you're
    // sittin' at the table...there'll be time
    function redeem(uint amount) // QD
        external returns (uint absorb) {
        uint cap = capitalisation(0, false);
        // if (cap) TODO morpho
        // % share of overall balance...
        uint share = FullMath.mulDiv(WAD, 
            amount, _min(QUID.matureBalanceOf(
                        msg.sender), amount));
        
        uint coverage = pledges[address(this)].carry.credit; 
        // maximum $ pledge would absorb if  redeemed all QD
        absorb = FullMath.mulDiv(coverage, FullMath.mulDiv(WAD, 
            pledges[msg.sender].carry.credit, SUM), WAD  
        );  
        // if not 100% of the mature QD is
        if (WAD > share) { // being redeemed
            absorb = FullMath.mulDiv(absorb, 
                                share, WAD);
        } 
        console.log("AbsorbInRedeem...", absorb);
        QUID.turn(msg.sender, amount);
        // helper function called by turn
        // handles PLEDGE.CARRY.CREDIT-- 
        amount = qd_amt_to_dollar_amt(cap, amount);  
        console.log("AbsorbAmount...", amount);
        // this is a collect call... 
        // do you accept the charges
        if (amount > absorb) {  
            amount -= absorb; 
            QUID.draw(msg.sender, amount);
            pledges[address(this)].carry.credit -= amount;
        }   pledges[address(this)].carry.credit -= absorb;         
    }
        
    function mint(address to, // used by ERC20.mint
        uint cost, uint minted) public onlyQuid {
        pledges[address(this)].carry.debit += cost;
        // ^needed for tracking total capitalisation...
        pledges[to].carry.debit += cost; // contingent
        // variable for ROI as well as redemption,
        // carry.credit gets reset in _creditHelper
        pledges[to].carry.credit += minted; 
        _creditHelper(to); // beneficiary
    }
    
    // quid says if amount is QD...
    // ETH can only be withdrawn from
    // pledge.work.debit; if ETH was 
    // deposited pledge.weth.debit,
    // call fold() before withdraw():
    // form of flash loan protection
    function withdraw(uint amount, 
        bool quid) external payable {
        uint amount0; uint amount1; 
        uint price = QUID.getPrice();
        Offer memory pledge = pledges[msg.sender];
        if (quid) { // amount is in units of QD...
            require(amount >= DIME, "too small");
            if (msg.value > 0) { amount1 = msg.value;
                WETH9.deposit{ value: amount1 }();
                pledges[address(this)].work.credit += 
                amount1; pledge.work.debit += amount1;
            }   uint debit = FullMath.mulDiv(price, 
                             pledge.work.debit, WAD);
            uint buffered = debit - (debit / 5);
            require(buffered >= pledge.work.credit
            && buffered > 0, "CR"); amount = _min(
                amount, buffered - pledge.work.credit);
            if (amount > 0) { 
                pledge.work.credit += amount;
                amount = dollar_amt_to_qd_amt(
                capitalisation(amount, false), amount); 
                QUID.mint(msg.sender, amount, address(QUID)); 
            }   console.log("WithDrawing...", amount); // in QD
            require(pledges[address(this)].carry.debit > 
                (FullMath.mulDiv(pledges[address(this)].weth.credit, 
                    price, WAD) + FullMath.mulDiv(price,
                    pledges[address(this)].work.credit / 2, // TODO
                    WAD)), "over-encumbered"); // assume 90% drop max
        } else { uint withdrawable;
            if (pledge.work.credit > 0) {
                uint debit = FullMath.mulDiv(price, 
                    pledge.work.debit, WAD
                ); uint buffered = debit - debit / 5;
                require(buffered >= pledge.work.credit, "CR!");
                withdrawable = FullMath.mulDiv(WAD, 
                buffered - pledge.work.credit, price); 
            }   uint transfer = amount;
            if (transfer > withdrawable) {
                withdrawable = FullMath.mulDiv(
                    WAD, pledge.work.credit, price 
                ); pledge.work.credit = 0; // clear
                pledge.work.debit -= withdrawable;
                pledges[address(this)].weth.debit += // sell ETH
                withdrawable; // to clear work.credit of pledge          
                transfer = _min(amount, pledge.work.debit);  
            }   pledges[address(this)].work.credit -= transfer;
            // for unwrapping from Uniswap to transfer ETH...
            console.log("TRANSFER...", transfer);
            (,, uint128 liquidity) = _liquidity(1, transfer);
            console.log("LIQUIDITY...", uint256(liquidity));
            (amount0, amount1) = _withdrawAndCollect(liquidity);
            console.log("WithdrawingETH...", transfer, amount0, amount1);
            if (amount1 >= transfer) { WETH9.transfer(msg.sender, transfer);
                amount1 -= transfer; } repackNFT(amount0, amount1);
        }   pledges[msg.sender] = pledge;
    }

    function deposit(address beneficiary, // pledge
        uint amount, bool long) external payable { 
        Offer memory pledge = pledges[beneficiary];
        if (amount > 0) { WETH9.transferFrom(
            msg.sender, address(this), amount);
        } else { require(msg.value > 0, "ETH!"); }
        if (msg.value > 0) { amount += msg.value; 
            WETH9.deposit{ value: msg.value }(); 
        }   if (long) { pledge.work.debit += amount;
            pledges[address(this)].work.credit += amount; 
        }   else { uint price = QUID.getPrice(); // insure $ of ETH
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
                (FullMath.mulDiv(pledges[address(this)].weth.credit, 
                    price, WAD) + FullMath.mulDiv(price,
                    pledges[address(this)].work.credit, 
                    WAD)), "insuring too much"); // 1:1     
        }           pledges[beneficiary] = pledge; 
                    repackNFT(0, amount); 
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
    function fold(address beneficiary, // amount is
        uint amount, bool sell) external payable { 
        FoldState memory state; state.price = QUID.getPrice();
        // call in collateral that's insured, or liquidate;
        // if there is an insured event, QD may be minted,
        // or simply clear the debt of a long position...
        // "we can serve our [wick nest] or we can serve
        // our purpose, but not both" ~ Mother Cabrini
        Offer memory pledge = pledges[beneficiary];
        amount = _min(amount, pledge.weth.debit);
        require(amount > 0, "amount too low");
        state.cap = capitalisation(0, false);
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
                }   state.cap = capitalisation(state.delta, false); 
                if (state.minting > state.delta || state.cap > 77) { 
                // minting will equal delta unless it's a sell, and if it's not,
                // we can't mint coverage if the protocol is under-capitalised...
                    state.minting = dollar_amt_to_qd_amt(state.cap, state.minting);
                    console.log("FoldMinted...", state.minting, state.delta);
                    QUID.mint(beneficiary, state.minting, address(QUID));
                    pledges[address(this)].carry.credit += state.delta; 
                }   else { state.deductible = 0; } // no mint = no charge  
            }   else if (!state.liquidate) { require(
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
            // in small doses, so don't think that I'm pushing you away"  
            // "when iron spit, cats fold, infact they
        if (state.liquidate && // get their life froze"
            (block.timestamp - pledge.last > 1 hours)) {  
            state.cap = capitalisation(state.repay, true);
            amount = _min(dollar_amt_to_qd_amt(state.cap, 
                state.repay), QUID.balanceOf(beneficiary)
            );  QUID.transferFrom(beneficiary, 
                        address(this), amount); 
            amount = qd_amt_to_dollar_amt(
                        state.cap, amount);
            // subtract the $ value of QD
            pledge.work.credit -= amount;
            console.log("FoldSalve...", amount); 
            // "lightnin' ⚡️ strikes and the 🏀 court lights...
            if (pledge.work.credit > state.collat) { // get dim"
                if (pledge.work.credit > DIME) { // assumes that 
                // liquidation bot will not skip opportunities...
                    amount = pledge.work.debit / 727; 
                    pledge.work.debit -= amount; 
                    pledges[address(this)].weth.debit += amount; 
                    amount = _min(pledge.work.credit, 
                        FullMath.mulDiv(state.price, 
                                        amount, WAD));
                    console.log("FoldLiquidate", amount);
                    // "It's like inch by inch, and step by 
                    // step, I'm closin' in on your position
                    // and [eviction] is my mission"
                    // Euler’s disk 💿 erasure code
                    pledge.work.credit -= amount; 
                    pledge.last = block.timestamp;
                } else { // "it don't get no better than this, you catch my [dust]"
                    // otherwise we run into a vacuum leak (infinite contraction)
                    pledges[address(this)].weth.debit += pledge.work.debit;
                     pledges[address(this)].carry.credit += pledge.work.credit;
                    // debt surplus absorbed ^^^^^^^^^ as if it were coverage
                    pledge.work.credit = 0; pledge.work.debit = 0; // reset
                }   
            }
        }   pledges[beneficiary] = pledge;
    } 

    // fold() doesn't repackNFT (only withdraw, deposit, redeem)
    // "to improve is to change, to perfect is to change often,"
    // we want to make sure that all of the WETH deposited to 
    // this contract is always in range (collecting), since 
    // burn & mint is relatively costly in terms of gas, we 
    // want to do that rarely...so as a rule of thumb, the  
    // range is roughly 14% total, 7% below and above tick,
    // this number was inspired by automotive science: how
    // voltage regulators watch the currents and control the 
    // relay (which turns on & off the alternator, if below 
    // or above 14 volts, respectively, re-charging battery)
    function repackNFT(uint amount0, uint amount1) public {
        (uint160 sqrtPriceX96, // Chainlink price used by swap
        // to prevent possible sandwich / price manipulation
        int24 twap,,,,,) = POOL.slot0(); uint128 liquidity; 
        if (LAST_TWAP_TICK != 0) { // not first _repack...
            if ( (twap > UPPER_TICK || twap < LOWER_TICK) && 
            block.timestamp - pledges[address(this)].last >= 1 hours) {
                (,,,,,,, liquidity,,,,) = NFPM.positions(ID);
                (uint collected0, 
                 uint collected1) = _withdrawAndCollect(liquidity); 
                amount0 += collected0; amount1 += collected1;
                pledges[address(this)].weth.debit -= collected1;
                pledges[address(this)].work.debit -= collected0;
                NFPM.burn(ID); // this ^^^^^^^^^^ is USDC fees
                pledges[address(this)].last = block.timestamp;
            }
        } LAST_TWAP_TICK = twap; if (liquidity > 0 || ID == 0) {
        (UPPER_TICK, LOWER_TICK) = _adjustTicks(LAST_TWAP_TICK);
        (amount0, 
         amount1) = _swap(amount0, amount1, sqrtPriceX96);
        (ID, liquidity,,) = NFPM.mint(
            INonfungiblePositionManager.MintParams({ token0: address(token0),
                token1: address(token1), fee: POOL_FEE, tickLower: LOWER_TICK, 
                tickUpper: UPPER_TICK, amount0Desired: amount0 /*- 1*/, 
                amount1Desired: amount1, amount0Min: 0, amount1Min: 0, 
                recipient: address(this), deadline: block.timestamp }));
                liquidityUnderManagement = liquidity;
        } // else no need to repack NFT, only collect LP fees
        else { (uint collected0, uint collected1) = _collect(); 
            amount0 += collected0; amount1 += collected1;
            (amount0, amount1) = _swap(
             amount0, amount1, sqrtPriceX96); 
            (liquidity,,) = NFPM.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams(
                    ID, amount0 /*- 1*/, amount1, 0, 0, block.timestamp
            )); 
            liquidityUnderManagement += liquidity;
        }   pledges[address(this)].weth.debit += amount1;
            pledges[address(this)].work.debit += amount0;
    }
}
