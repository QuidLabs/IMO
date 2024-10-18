
// SPDX-License-Identifier: AGPL-3.0

pragma solidity =0.8.8; 
import {TransferHelper} from "./interfaces/TransferHelper.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import {TickMath} from "./interfaces/math/TickMath.sol";
import {FullMath} from "./interfaces/math/FullMath.sol";
import {IV3SwapRouter} from "./interfaces/IV3SwapRouter.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";
import {LiquidityAmounts} from "./interfaces/math/LiquidityAmounts.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
interface IWETH is IERC20 {
    function deposit() 
    external payable;
}   import "./QD.sol";
contract MO is Ownable {
// essentially 4626, but we
// save on contract size by
// not inheriting interface
    address public SUSDE; 
    address public USDE;
    address constant public WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14; // token0 on mainnet, token1 on sepolia
    address constant public USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // token1 on mainnet, token0 on sepolia
    // TODO uncomment these for mainnet deployment, make sure to respect token0 and token1 order in _swap and NFPM.mint
    // address constant public SUSDE = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    // address constant public USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    // address constant public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address constant public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; 
    uint internal _ETH_PRICE; // TODO delete when finished testing
    uint24 constant POOL_FEE = 500;
    
    uint internal FEE;
    uint constant WAD = 1e18;
    uint128 constant Q96 = 2**96; 
    uint constant DIME = 10 * WAD;
    INonfungiblePositionManager NFPM;
    int24 internal LAST_TWAP_TICK;
    int24 internal UPPER_TICK; 
    int24 internal LOWER_TICK;
    
    uint public ID; uint public MINTED; // QD
    IUniswapV3Pool POOL; IV3SwapRouter ROUTER; 
    struct FoldState { uint delta; uint price;
        uint average_price; uint average_value;
        uint deductible; uint cap; uint minting;
        bool liquidate; uint repay; uint collat; 
    }
    struct SwapState { 
        uint256 positionAmount0;
        uint256 positionAmount1;
        int24 currentTick;
        int24 twapTick;
        uint160 sqrtPriceX96;
        uint160 sqrtPriceX96Lower;
        uint160 sqrtPriceX96Upper;
        uint256 priceX96;
        uint256 amountRatioX96;
        uint256 delta0;
        uint256 delta1;
        bool sell0;
    }   Quid QUID;
    
    // event CreditHelperShare(uint share, address who); 
    // event CreditHelperROI(uint roi, address who);
    // event CreditHelper(uint credit, address who);
    // event TransferHelperEvent(uint ratio);
    // event DebitTransferHelper(uint debit);
    // event WithdrawingETH(uint amount, uint amount0, uint ammount1);
    // event DepositDeductibleInDollars(uint deductible);
    // event DepositDeductibleInETH(uint deductible);
    // event DepositInsured(uint insured);
    // event DepositInDollars(uint in_dollars); 
    // TODO ^these seem right, double check later?
    
    event Fold(uint price, uint value, uint cover);
    event FoldDelta(uint delta);
    event FoldMinted(uint minted, uint delta);
    event FoldSalve(uint amount); 
    event FoldLiquidate(uint amount);
    event FoldDeductible(uint amount, uint deductible);
    event FoldRepayNoLiquidate(uint amount);
    event FoldRepayLiquidate(uint amount);

    // TODO test redeem after all others 
    event AbsorbAmount(uint amount);
    event USDCinRedeem(uint usdc);
    event WeirdRedeem(uint absorb, uint amount);
    event ThirdInRedeem(uint third);
    event AbsorbInRedeem(uint absorb);
    event SellInRedeem(uint amount);
    
    // event WithDrawing(uint amount);
    // event SwapDelta0(uint delta0);
    // event SwapSell0(uint amount0, uint amount1);
    // event SwapSell1(uint amount0, uint amount1);
    // event SwapSell0numerator(uint numerator);
    // event SwapSell1numerator(uint numerator);
    // event SwapAmountsForLiquidity(uint amount0, uint amount1);
    // event SwapPrices(uint priceX96, uint sqrtPriceX96Lower, uint sqrtPriceX96Upper);

    // event RepackNFTamountsAfterCollectInBurn(uint amount0, uint amount1);
    // event RepackNFTtwap(int24 twap, int24 twapUpper, int24 twapLower);
    // event RepackNFTamountsBefore(uint amount0, uint amount1);
    // event RepackNFTamountsAfterCollect(uint amount0, uint amount1);
    event RepackNFTamountsAfterSwap(uint amount0, uint amount1);
    event RepackMintingNFT(int24 upper, int24 lower, uint amount0, uint amount1);
        
    function get_info(address who) view
        external returns (uint, uint) {
        Offer memory pledge = pledges[who];
        return (pledge.carry.debit, QUID.balanceOf(who));
        // never need pledge.carry.credit in the frontend,
        // this is more of an internal tracking variable...
    }
    function get_more_info(address who) view
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
    } /* quid.credit = contribution to weighted...
    ...SUM of (QD / total QD) x (ROI / avg ROI) */
    uint public SUM = 1; uint public AVG_ROI = 1; 
    uint public liquidityUnderManagement; // UniV3...
    // formal contracts require a specific method of 
    // formation to be enforaceable; one example is
    // negotiable instruments like promissory notes 
    // an Offer is a promise or commitment to do
    // or refrain from doing something specific
    // in the future...our case is bilateral...
    // promise for a promise, aka quid pro quo...
    struct Offer { Pod weth; Pod carry; Pod work;
    // Pod last; } // timestamp of last liquidate & 
    // % that's been liquidated (smaller over time)
    uint last; } // TODO (after testing finished)
    // work is like a checking account (credit can
    // be drawn against it) while weth is savings,
    // but it pays interest to the contract itself;
    // together, and only if used in combination,
    // they form an insured revolving credit line;
    // carry is relevant for redemption purposes.
    // fold() holds depositors accountable for 
    // work as well as accountability for weth
    function setQuid(address _quid) external 
        onlyOwner {  QUID = Quid(_quid); 
        // renounceOwnership();
    } 
    modifier onlyQuid {
        require(_msgSender() 
            == address(QUID), 
            "unauthorised"); _;
    }
    function setFee(uint index) 
        public onlyQuid { FEE = 
        WAD / (index + 11); }
    //  recall 3rd Delphic maxim
    mapping (address => Offer) pledges;
    function _max(uint128 _a, uint128 _b) 
        internal pure returns (uint128) {
        return (_a > _b) ? _a : _b;
    }
    function _min(uint _a, uint _b) 
        internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }
    function _minAmount(address from, address token, 
        uint amount) internal view returns (uint) {
        amount = _min(amount, IERC20(token).balanceOf(from));
        require(amount > 0, "0 balance"); 
        if (token != address(QUID)) {
            amount = _min(amount,IERC20(token).allowance(from, address(this)));
            require(amount > 0, "0 allowance"); 
        }
        return amount;
    }
    function setMetrics(uint avg_roi) public
        onlyQuid { AVG_ROI = avg_roi;
    }
    function _isDollar(address dollar) internal view returns 
        (bool) { return dollar == SUSDE || dollar == USDE; } 

    function dollar_amt_to_qd_amt(uint cap, uint amt) 
        public view returns (uint) { return (cap < 100) ? 
        FullMath.mulDiv(amt, 100 + (100 - cap), 100) : amt; 
    } 

    // different from eponymous function in ERC20...
    function qd_amt_to_dollar_amt(uint cap, uint amt) 
        public view returns (uint) { return (cap < 100) ? 
        FullMath.mulDiv(amt, cap, 100) : amt;
    }

    constructor(address _usde, address _susde) { 
        USDE = _usde; SUSDE = _susde; // TODO remove (for Sepolia only)
                                         // as well as from constructor...
        // TODO replace addresses (with ones below for mainnet deployment)
        // POOL = IUniswapV3Pool(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640);
        // ROUTER = IV3SwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        // address nfpm = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88; 
        POOL = IUniswapV3Pool(0x3289680dD4d6C10bb19b899729cda5eEF58AEfF1);
        ROUTER = IV3SwapRouter(0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E);
        address nfpm = 0x1238536071E1c677A632429e3655c799b22cDA52; 
        NFPM = INonfungiblePositionManager(nfpm); 
        // "Le souffle des 4 vents décuple ma puissance...
        // De longs mois de travail ont exacerbé mes sens
        // Je crée un déséquilibre interne volontairement
        FEE = WAD / 28; // Afin que le côté Yang soit le dominant"
        TransferHelper.safeApprove(WETH, nfpm, type(uint256).max);
        TransferHelper.safeApprove(USDC, nfpm, type(uint256).max);
        TransferHelper.safeApprove(USDE, SUSDE, type(uint256).max);
    }
    // present value of the expected cash flows...
    function capitalisation(uint qd, bool burn) 
        public view returns (uint) { // ^ extra in QD
        uint price = _getPrice(); // $ value of ETH
        // earned from deductibles and Uniswap fees
        Offer memory pledge = pledges[address(this)];
        uint collateral = FullMath.mulDiv(price,
            pledge.work.credit, WAD // in $
        ); // collected in deposit and fold...
        uint deductibles = FullMath.mulDiv(price,
            pledge.weth.debit, WAD // in $
        ); // composition of insurance capital:
        uint assets = collateral + deductibles + 
            // USDC (upscaled for precision)...
            (pledge.work.debit * 1e12) + // USDe...
             pledge.carry.debit; // not incl. yield
        // doesn't account for pledge.weth.credit,
        // which are liabilities (that are insured)
        uint total = QUID.totalSupply(); 
        if (qd > 0) { total = (burn) ? 
            total - qd : total + qd;
        }
        return FullMath.mulDiv(100, assets, total); 
    } // TODO compound sUSDe and sDAI fees?

    // helpers allow treating QD balances
    // uniquely without needing ERC721...
    function transferHelper(address from, 
        address to, uint amount) onlyQuid public {
            if (to != address(0)) { // not burning
                // percentage of carry.debit gets 
                // transferred over in proportion 
                // to amount's % of total balance
                // determine % of total balance
                // transferred for ROI pro rata
                uint ratio = FullMath.mulDiv(WAD, 
                    amount, QUID.balanceOf(from));
                // emit TransferHelperEvent(ratio);
                // proportionally transfer debit...
                uint debit = FullMath.mulDiv(ratio, 
                pledges[from].carry.debit, WAD);
                // emit DebitTransferHelper(debit);
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
    function _creditHelper(address who) // QD holder 
        internal { // until batch 1 we have no AVG_ROI
        if (QUID.currentBatch() > 0) { // to work with
            uint credit = pledges[who].carry.credit;
            SUM -= credit; // subtract old share, which
            // may be zero if this is the first time 
            // _creditHelper is called for `who`...
            uint balance = QUID.balanceOf(who);
            uint debit = pledges[who].carry.debit;
            uint share = FullMath.mulDiv(WAD, 
                balance, QUID.totalSupply());
            // emit CreditHelperShare(share, who);
            credit = share;
            if (debit > 0) { // share is product
                // projected ROI if QD is $1...
                uint roi = FullMath.mulDiv(WAD, 
                        balance - debit, debit);
                // calculate individual ROI over total 
                roi = FullMath.mulDiv(WAD, roi, AVG_ROI);
                credit = FullMath.mulDiv(roi, share, WAD);
                // emit CreditHelperROI(roi, who);
                // credit is the product (composite) of 
                // two separate share (ratio) quantities 
                // and the sum of products is what we use
                // in determining pro rata in redeem()...
            }   pledges[who].carry.credit = credit;
            SUM += credit; // update sum with new share
            // emit CreditHelper(credit, who);
        }
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
        // is the tick width for WETH<>USDC
        if (remainder == 0) { result = input;
        } else if (remainder >= 5) { // round up
            result = input + (10 - remainder);
        } else { // round down instead...
            result = input - remainder;
        }
        // just here as sanity check
        if (result > 887220) { // max
            return 887220; 
        } else if (-887220 > result) { 
            return -887220;
        }   return result;
    }
    // adjust to the nearest multiple of our tick width...
    function _adjustTicks(int24 twap) internal pure returns 
        (int24 adjustedIncrease, int24 adjustedDecrease) {
        uint wad = WAD;
        int256 upper = int256(wad + (wad / 14)); 
        int256 lower = int256(wad - (wad / 14));
        int24 increase = int24((int256(twap) * upper) / int256(wad));
        int24 decrease = int24((int256(twap) * lower) / int256(wad));
        adjustedIncrease = _adjustToNearestIncrement(increase);
        adjustedDecrease = _adjustToNearestIncrement(decrease);
        if (adjustedIncrease == adjustedDecrease) { // edge case
            adjustedIncrease += 10; 
        } 
    }
    function _getTWAP(bool immediate) internal view returns (int24) {
        // FIXME if immediate is true, for some reason we get 0 as the result!
        uint32[] memory when = new uint32[](2); when[1] = immediate ? 60 : 28800; when[0] = 0; 
        try POOL.observe(when) returns (int56[] memory cumulatives, uint160[] memory) {
            int24 delta = int24(cumulatives[1] - cumulatives[0]);
            int24 result = immediate ? delta / 60 : delta / 28800;
            return result;
        } catch { return int24(0); } 
    }
    function _getPrice() internal view returns (uint) {
        if (_ETH_PRICE > 0) return _ETH_PRICE; // TODO
        // (uint160 sqrtPriceX96,,,,,,) = POOL.slot0();
        // price = FullMath.mulDiv(uint256(sqrtPriceX96), 
        //                         uint256(sqrtPriceX96), Q96);
        return QUID.getPrice(); 
    }
    function set_price_eth(bool up,
        bool refresh) external { 
        if (refresh) { _ETH_PRICE = 0;
            _ETH_PRICE = _getPrice();
        }   else { uint delta = _ETH_PRICE / 5;
            _ETH_PRICE = up ? _ETH_PRICE + delta 
                              : _ETH_PRICE - delta;
        } // TODO remove this admin testing function
    } 

    function draw(address to, // redeemer...
        uint amount) public returns (uint qd) { 
        if (_msgSender() == address(QUID)) {
            qd = dollar_amt_to_qd_amt(
                capitalisation(0, false), 
            amount / 2); to = owner();
        } else { require(_msgSender() == address(this), "$"); }
        if (capitalisation(0, false) > 100 && amount > 0) { 
            // uint reserveSDAI = IERC4626(SDAI).balanceOf(address(this));
            uint reserveSUSDE = IERC4626(SUSDE).balanceOf(address(this));
            // TODO does ^^^ return shares?
            amount = _min(reserveSUSDE, amount);
            // require(pledges[address(this)].carry.debit 
            //     == reserveSDAI + reserveSUSDE, "don't add up");

            // uint totalBalance = reserveSDAI + reserveSUSDE;
            // uint newTotalBalance = totalBalance - amount;
            // uint targetBalance = newTotalBalance / 2;

            // uint withdrawFromSDAI = reserveSDAI > targetBalance ? 
            //                         reserveSDAI - targetBalance : 0;
            // uint withdrawFromSUSDE = reserveSUSDE > targetBalance ? 
            //                          reserveSUSDE - targetBalance : 0;

            // uint totalWithdrawn = withdrawFromSDAI + withdrawFromSUSDE;
            // if (totalWithdrawn < amount) {
            //     uint remainingAmount = amount - totalWithdrawn;
            //     if (reserveSDAI - withdrawFromSDAI > remainingAmount / 2) {
            //         withdrawFromSDAI += remainingAmount / 2;
            //         remainingAmount -= remainingAmount / 2;
            //     } else {
            //         withdrawFromSDAI += reserveSDAI - withdrawFromSDAI;
            //         remainingAmount -= reserveSDAI - withdrawFromSDAI;
            //     }
            //     if (reserveSUSDE - withdrawFromSUSDE > remainingAmount) {
            //         withdrawFromSUSDE += remainingAmount;
            //     } else {
            //         withdrawFromSUSDE += reserveSUSDE - withdrawFromSUSDE;
            //     }
            // }
            // IERC4626(SDAI).redeem(withdrawFromSDAI, to, address(this));
            IERC4626(SUSDE).redeem(amount, to, address(this));
            // redeem takes amount of sUSDe you want to turn into USDe. 
            // withdraw specifies amount of USDe you wish to withdraw, 
            // and will pull the required amount of sUSDe from sender. 
            // TODO steps to withdraw from morpho (mainnet)
        }
    }
    
    /* TODO uncomment
    function _swap(uint amount0, uint amount1) internal returns (uint, uint) {
        SwapState memory state; state.twapTick = LAST_TWAP_TICK;
        (state.sqrtPriceX96, state.currentTick,,,,,) = POOL.slot0();
        // (protects from price manipulation attacks / sandwich attacks)
        require(LAST_TWAP_TICK > 0 && (state.twapTick > state.currentTick 
        && ((state.twapTick - state.currentTick) < 100)) || (state.twapTick <= state.currentTick  
        && ((state.currentTick  - state.twapTick) < 100)), "delta"); // 100 = 1% max tick diff.

        state.priceX96 = FullMath.mulDiv(uint256(state.sqrtPriceX96), 
                                         uint256(state.sqrtPriceX96), Q96);
        
        state.sqrtPriceX96Lower = TickMath.getSqrtPriceAtTick(LOWER_TICK);
        state.sqrtPriceX96Upper = TickMath.getSqrtPriceAtTick(UPPER_TICK);

        emit SwapPrices(state.priceX96, state.sqrtPriceX96Lower, state.sqrtPriceX96Upper);

        (state.positionAmount0, 
         state.positionAmount1) = LiquidityAmounts.getAmountsForLiquidity(
                                                    state.sqrtPriceX96, 
                                                    state.sqrtPriceX96Lower, 
                                                    state.sqrtPriceX96Upper, Q96);
        emit SwapAmountsForLiquidity(state.positionAmount0, state.positionAmount1);
        // how much of the position needs to
        // be converted to the other token:
        if (state.positionAmount0 == 0) { // FIXME delta0 
        // should be how much position 0 needs to change into 1?
            state.sell0 = true; state.delta0 = amount0; // FullMath.mulDiv(Q96, amount1, state.priceX96);
        } else if (state.positionAmount1 == 0) { state.sell0 = false;
            state.delta0 = FullMath.mulDiv(Q96, amount0, state.priceX96);
        } else {
            state.amountRatioX96 = FullMath.mulDiv(Q96, state.positionAmount0, state.positionAmount1);
            uint denominator = FullMath.mulDiv(state.amountRatioX96, state.priceX96, Q96) + Q96;
            uint numerator; state.sell0 = (state.amountRatioX96 * amount1 < amount0 * Q96); 
            if (state.sell0) {
                numerator = (amount0 * Q96) - FullMath.mulDiv(state.amountRatioX96, amount1, 1);
                emit SwapSell0numerator(numerator);
            } else {    
                numerator = FullMath.mulDiv(state.amountRatioX96, amount1, 1) - (amount0 * Q96);
                emit SwapSell1numerator(numerator);
            }
            state.delta0 = numerator / denominator;
        }
        emit SwapDelta0(state.delta0);
        if (state.delta0 > 0) {
            if (state.sell0) { 
                TransferHelper.safeApprove(USDC, 
                address(ROUTER), state.delta0);
                uint256 amount = ROUTER.exactInput(
                    IV3SwapRouter.ExactInputParams(abi.encodePacked(
                        USDC, POOL_FEE, WETH), address(this), state.delta0, 0)
                ); 
                TransferHelper.safeApprove(USDC, address(ROUTER), 0);
                // IERC20(WETH).approve(address(ROUTER), 0);
                amount0 = amount0 - state.delta0;
                amount1 = amount1 + amount;
                emit SwapSell0(amount0, amount1);
            } 
            else { // sell1
                state.delta1 = FullMath.mulDiv(state.delta0, state.priceX96, Q96);
                if (state.delta1 > 0) { // prevent possible rounding to 0 issue
                    TransferHelper.safeApprove(WETH, 
                    address(ROUTER), state.delta1);
                    uint256 amount = ROUTER.exactInput(
                        IV3SwapRouter.ExactInputParams(abi.encodePacked(
                            WETH, POOL_FEE, USDC), address(this), state.delta1, 0)
                    ); 
                    TransferHelper.safeApprove(WETH, address(ROUTER), 0);
                    // IERC20(USDC).approve(address(ROUTER), 0);
                    amount0 = amount0 + amount;
                    amount1 = amount1 - state.delta1;
                    emit SwapSell1(amount0, amount1);
                }
            }
        }
        return (amount0, amount1); 
    }   
    */

    // call in QD's worth (обнал sans liabilities)
    // calculates the coverage absorption for each 
    // insurer by first determining their share %
    // and then adjusting based on average ROI...
    // (insurers w/ higher avg. ROI absorb more) 
    // "you never count your money while you're
    // sittin' at the table...there'll be time
    // enough for countin'...when,"
    function redeem(uint amount) 
        external returns (uint absorb) {
        amount = _min(QUID.matureBalanceOf(_msgSender()),
        amount); // % share over the overall balance...
        emit AbsorbAmount(amount);
        uint share = FullMath.mulDiv(WAD, amount, 
                     QUID.balanceOf(_msgSender()));
        Offer storage pledge = pledges[_msgSender()]; 
        uint coverage = pledges[address(this)].carry.credit; 
        // maximum $ that pledge would absorb
        // if they redeemed all their QD...
        absorb = FullMath.mulDiv(coverage, 
            FullMath.mulDiv(WAD, 
            pledge.carry.credit, SUM), WAD  
        );  
        // if not 100% of the mature QD is
        if (WAD > share) { // being redeemed
            absorb = FullMath.mulDiv(absorb, 
                                share, WAD);
        }   emit AbsorbInRedeem(absorb);
        // QUID.burn(_msgSender(), amount); 
        amount = qd_amt_to_dollar_amt(
            capitalisation(0, false),
            amount
        );  emit AbsorbAmount(amount);
        if (amount > absorb) { /* amount -= absorb; 
            // remainder is $ value to be released 
            // after accounting for liabilities...
            uint third = 3 * amount / 10; // $
            // 70% of amount from carry.debit...
            draw(_msgSender(), amount - third);
            emit ThirdInRedeem(third);
            
            // convert 1/3 of amount into USDC precision...
            uint usdc = _min(third / 1e12,
            pledges[address(this)].work.debit);
            
            emit USDCinRedeem(usdc);
            bool sell = third > (pledges[address(this)].work.debit * 1e12);

            if (sell) { amount = FullMath.mulDiv(WAD,
                (third - (usdc * 1e12)), _getPrice());
                emit SellInRedeem(amount);
                amount = _min(amount, 
                pledges[address(this)].weth.debit);
                pledges[address(this)].work.debit = 0;
                pledges[address(this)].weth.debit -= amount;
            } else { amount = 0; // ETH being sent out...
                pledges[address(this)].work.debit -= usdc; 
            }
            uint160 sqrtPriceX96atLowerTick = TickMath.getSqrtPriceAtTick(LOWER_TICK);
            uint160 sqrtPriceX96atUpperTick = TickMath.getSqrtPriceAtTick(UPPER_TICK);
            uint128 liquidity0 = LiquidityAmounts.getLiquidityForAmount0(
                sqrtPriceX96atUpperTick, sqrtPriceX96atLowerTick, usdc
            );
            uint128 liquidity1 = LiquidityAmounts.getLiquidityForAmount1(
                sqrtPriceX96atUpperTick, sqrtPriceX96atLowerTick, amount
            );
            uint128 liquidity = _max(liquidity0, liquidity1); // TODO update
            // require(liquidity < liquidityUnderManagement, "overflow NFT");
            (uint amount0, uint amount1) = _withdrawAndCollect(liquidity);
            if (amount1 >= amount) { 
                TransferHelper.safeTransfer(WETH, 
                        _msgSender(), usdc);
                           amount1 -= amount;
                           // emit RedeemWETH(weth);
            }
            if (amount0 >= usdc) { 
                TransferHelper.safeTransfer(USDC, 
                        _msgSender(), usdc);
                           amount0 -= usdc;
                           // emit RedeemUSDC(usdc);
                
            }   
            pledges[address(this)].carry.credit -= absorb; 
            if (amount0 > 0 || amount1 > 0) 
            { repackNFT(amount0, amount1); }
        } 
        else {
            emit WeirdRedeem(absorb, amount);
            pledges[address(this)].carry.credit -= amount;
            // else the entire amount being redeemed
            // is consumed by absorbing protocol debt
        }
        */
        }
    }
    
    // quid says if amount is QD...
    // ETH can only be withdrawn from
    // pledge.work.debit; if ETH was 
    // deposited pledge.weth.debit,
    // call fold() before withdraw()
    function withdraw(uint amount, 
        bool quid) external payable {
        uint amount0; uint amount1; 
        uint price = _getPrice();
        Offer memory pledge = pledges[_msgSender()];
        if (quid) { // amount is in units of QD...
            require(amount >= DIME, "too small");
            if (msg.value > 0) { amount1 = msg.value;
                IWETH(WETH).deposit{ value: amount1 }();
                pledges[address(this)].work.credit += 
                amount1; pledge.work.debit += amount1;
            }   uint debit = FullMath.mulDiv(price, 
                             pledge.work.debit, WAD);
            uint buffered = debit - (debit / 5);
            require(buffered >= pledge.work.credit, "CR");
            amount = _min(amount, 
            buffered - pledge.work.credit);
            if (amount > 0) { 
                pledge.work.credit += amount;
                amount = dollar_amt_to_qd_amt(
                capitalisation(amount, false), amount); 
                QUID.mint(amount, _msgSender(), address(QUID)); 
            }   // emit WithDrawing(amount);
        } else { uint withdrawable; // uint of ETH...
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
            // Procedure for unwrapping from Uniswap to transfer ETH:
            // determine liquidity needed to call decreaseLiquidity...
            uint160 sqrtPriceX96atLowerTick = TickMath.getSqrtPriceAtTick(LOWER_TICK);
            uint160 sqrtPriceX96atUpperTick = TickMath.getSqrtPriceAtTick(UPPER_TICK);
            uint128 liquidity = LiquidityAmounts.getLiquidityForAmount1(
                sqrtPriceX96atUpperTick, sqrtPriceX96atLowerTick, transfer
            );
            // TODO check below total liquidityUnderManagement
            (amount0,
             amount1) = _withdrawAndCollect(liquidity);
            // emit WithdrawingETH(transfer, amount0, amount1);
            if (amount1 >= transfer) { 
                // address(this) balance should be >= amount1
                TransferHelper.safeTransfer(
                    WETH, _msgSender(), transfer);
                             amount1 -= transfer;
            }     
        }   pledges[_msgSender()] = pledge;
        if (amount0 > 0 || amount1 > 0) 
        { repackNFT(amount0, amount1); }
    }

    // allowing deposits on behalf of a benecifiary
    // enables similar functionality to suretyship
    function deposit(address beneficiary, uint amount,
        address token, bool long) external payable { 
        Offer memory pledge = pledges[beneficiary];
        if (_isDollar(token)) { // amount interpreted as QD to mint
            uint cost = QUID.mint(amount, beneficiary, token);
            TransferHelper.safeTransferFrom(
                token, beneficiary, address(this), cost
            );  pledges[address(this)].carry.debit += cost;
            // ^needed for tracking total capitalisation
            pledge.carry.debit += cost; // contingent
            // variable for ROI as well as redemption,
            // carry.credit gets reset in _creditHelper
            pledges[beneficiary] = pledge; // save changes
            _creditHelper(beneficiary); // because we read
            // from pledge ^^^^^^^^^^ in _creditHelper
            if (token == USDE) { // to accrue rewards
                IERC4626(SUSDE).deposit( // before...
                    cost, address(this) // move to 
                );
                // TODO stake into morpho (mainnet)
            } 
            // else if (token == DAI) { // TODO
                // IERC4626(SDAI).deposit( // before 
                //     cost, address(this) // move to 
                // ); // advanced integration of USDS 
                // Aave USDS market + USDS Savings Rate 
            // }
        } 
        else if (token == address(QUID)) {
            amount = _minAmount(_msgSender(), token, amount);
            uint cap = capitalisation(amount, true);
            amount = _min(qd_amt_to_dollar_amt(cap, 
            amount), pledge.work.credit); 
            pledge.work.credit -= amount;
            cap = capitalisation(amount, true); 
            QUID.burn(_msgSender(),
            dollar_amt_to_qd_amt(cap, amount));
        } else {
            if (amount > 0) { amount = _minAmount(
                _msgSender(), WETH, amount); 
                TransferHelper.safeTransferFrom(WETH, 
                _msgSender(), address(this), amount);
            } else { require(msg.value > 0, "ETH!");
                 amount += msg.value; }
            if (msg.value > 0) { IWETH(WETH).deposit{
                                 value: msg.value }(); 
            }       if (long) { pledge.work.debit += amount; }
            else { uint price = _getPrice(); // insuring the $ value...
                uint in_dollars = FullMath.mulDiv(price, amount, WAD);
                uint deductible = FullMath.mulDiv(in_dollars, FEE, WAD);
                // emit DepositInDollars(in_dollars); 
                in_dollars -= deductible; 
                // emit DepositDeductibleInDollars(deductible); 
                // change deductible to be in units of ETH instead
                deductible = FullMath.mulDiv(WAD, deductible, price);
                // emit DepositDeductibleInETH(deductible);
                uint insured = amount - deductible; // in ETH
                // emit DepositInsured(insured);
                pledge.weth.debit += insured; // withdrawable
                // by folding balance into pledge.work.debit...
                pledges[address(this)].weth.debit += deductible;
                pledges[address(this)].weth.credit += insured;
                pledge.weth.credit += in_dollars;
                in_dollars = FullMath.mulDiv(price, 
                    pledges[address(this)].weth.credit, WAD
                );  require(pledges[address(this)].carry.debit
                            > in_dollars, "insuring too much"); 
                pledges[beneficiary] = pledge; // save changes
            }   repackNFT(0, amount); // 0 represents USDC
        } // TODO consider that half the ETH is converted ^
        // so this affects the risk the protocol is holding
        // and edge case (there may not be enough liquidity
        // to convert that USDC half to necessary ETH amt)
        // this is relevant for withdraw, fold, redeem...
    }

    // "Entropy" comes from a Greek word for transformation; 
    // Clausius interpreted as the magnitude of the degree 
    // to which Pods be separate from each other: "so close
    // no matter how far...rage be in it like you couldn’t
    // believe, or work like I could've scarcely imagined;
    // if one isn’t satisfied, indulge the latter, ‘neath 
    // the halo of a street-lamp, I turn my straddle to
    // the cold and damp...know when to hold 'em...know 
    // when to..." 
     function fold(address beneficiary, // amount is...
        uint amount, bool sell) external { // in ETH
        FoldState memory state; state.price = _getPrice();
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
            );  // "lookin' too hot; simmer down"
            if (pledge.work.credit > state.collat) {
                state.repay = pledge.work.credit - state.collat; 
                state.repay += state.collat / 10;
                state.liquidate = true; // not final
                emit FoldRepayLiquidate(state.repay);
            } else { // for using claimed coverage to payoff debt
                state.delta = state.collat - pledge.work.credit;
                if (state.collat / 10 > state.delta) {
                    state.repay = (state.collat / 10) - state.delta;
                }
                emit FoldRepayNoLiquidate(state.repay);
            }   
        } if (amount > 0) { // claim ETH amount that's been insured
            state.collat = FullMath.mulDiv(amount, state.price, WAD);
            state.average_price = FullMath.mulDiv(WAD, 
                pledge.weth.credit, pledge.weth.debit
            ); // ^^^^^^^^^^^^^^^^ must be in dollars
            state.average_value = FullMath.mulDiv( 
                amount, state.average_price, WAD
            );  
            emit Fold(state.average_price, state.average_value, FullMath.mulDiv(110, state.price, 100));
            // if price drop > 10% (average_value > 10% more than current value) 
            if (state.average_price >= FullMath.mulDiv(110, state.price, 100)) { 
                state.delta = state.average_value - state.collat;
                emit FoldDelta(state.delta);
                
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
                    // ^^^^^^ variable being reused for space...
                    pledge.work.credit -= state.cap; 
                    state.minting -= state.cap; 
                    state.repay -= state.cap; 
                }
                pledges[address(this)].work.credit += amount;
                // we need to increment before calling capitalisation
                // in order for the ratio to be calculated correctly
                    state.cap = capitalisation(state.delta, false); 
                if (state.minting > state.delta || state.cap > 57) { 
                // minting will equal delta unless it's a sell, and if it's not,
                // we can't mint coverage if the protocol is under-capitalised...
                    state.minting = dollar_amt_to_qd_amt(state.cap, state.minting);
                    emit FoldMinted(state.minting, state.delta);
                    QUID.mint(state.minting, beneficiary, address(QUID));
                    pledges[address(this)].carry.credit += state.delta; 
                } else { state.deductible = 0; } // no mint = no charge  
                pledges[address(this)].weth.credit -= amount;
                // amount is no longer insured by the protocol
                pledge.weth.debit -= amount; // deduct amount
                pledge.weth.credit -= state.average_value;
                // if we were to deduct actual value instead
                // that could be taken advantage of (increased
                // payouts with each subsequent call to fold)... 
                emit FoldDeductible(amount, state.deductible);
                pledge.work.debit += amount - state.deductible;
                // if sell true, pledge doesn't get any ETH back
                pledges[address(this)].work.credit -= state.deductible;
                pledges[address(this)].weth.debit += state.deductible;
                
                state.collat = FullMath.mulDiv(pledge.work.debit, state.price, WAD);
                if (state.collat > pledge.work.credit) { state.liquidate = false; }
            } 
        } // "things have gotten closer to the sun, and I've done 
        // things in small doses, so don't think that I'm pushing 
        // you away...when you're...amount: the state repayment...
        if (state.liquidate && ( // the one that I've kept closest"
            QUID.blocktimestamp() - pledge.last/*.credit*/ > 1 hours)) {  
            state.cap = capitalisation(state.repay, true);
            amount = _min(dollar_amt_to_qd_amt(state.cap, 
                state.repay), QUID.balanceOf(beneficiary)
            );  QUID.burn(beneficiary, amount);
            amount = qd_amt_to_dollar_amt(state.cap, amount);
            // subtract the $ value of QD
            pledge.work.credit -= amount;
            emit FoldSalve(amount); 
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
                    emit FoldLiquidate(amount);
                    // "It's like inch by inch, and step by 
                    // step, I'm closin' in on your position
                    // and [eviction] is my mission..."
                    // Euler’s disk 💿 erasure code
                    pledge.work.credit -= amount; 
                    pledge.last/*.credit*/ = QUID.blocktimestamp();
                    // pledge.last.debit = 
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
    // repackNFT is relatively costly in terms of gas, we 
    // want to call it rarely...so as a rule of thumb, the  
    // range is roughly 14% total, 7% below and above TWAP,
    // we check for a delta of this size over last 8 hours;
    // this number was inspired by automotive science: how
    // voltage regulators watch the currents and control the 
    // relay (which turns on & off the alternator, if below 
    // or above 14 volts, respectively, re-charging battery)
    function repackNFT(uint amount0, uint amount1) public {
        uint128 liquidity; int24 twap = _getTWAP(true); 
        // emit RepackNFTamountsBefore(amount0, amount1);
        if (LAST_TWAP_TICK != 0) { // not first _repack call
            if (twap > UPPER_TICK || twap < LOWER_TICK) {
                (,,,,,,, liquidity,,,,) = NFPM.positions(ID);
                (uint collected0, 
                 uint collected1) = _withdrawAndCollect(liquidity); 
                amount0 += collected0; amount1 += collected1;
                // emit RepackNFTamountsAfterCollectInBurn(amount0, amount1);
                pledges[address(this)].weth.debit += collected1;
                pledges[address(this)].work.debit += collected0;
                NFPM.burn(ID); // this ^^^^^^^^^^ is USDC fees
            }
        } LAST_TWAP_TICK = twap; if (liquidity > 0 || ID == 0) {
        (UPPER_TICK, LOWER_TICK) = _adjustTicks(LAST_TWAP_TICK);
        // emit RepackNFTtwap(twap, UPPER_TICK, LOWER_TICK); 
        // (amount0, amount1) = _swap(amount0, amount1);
        // emit RepackMintingNFT(
        //     UPPER_TICK, LOWER_TICK, amount0, amount1
        // );
        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({token0: USDC, 
                token1: WETH, fee: POOL_FEE, tickLower: LOWER_TICK, 
                tickUpper: UPPER_TICK, amount0Desired: amount0, 
                amount1Desired: amount1, amount0Min: 0, amount1Min: 0, 
                recipient: address(this), deadline: block.timestamp + 
                1 minutes}); (ID,,,) = NFPM.mint(params); // V3 NFT
        } // else no need to repack NFT, need to collect LP fees
        else { (uint collected0, uint collected1) = _collect(); 
            amount0 += collected0; amount1 += collected1;
            // emit RepackNFTamountsAfterCollect(amount0, amount1);
            pledges[address(this)].weth.debit += collected1;
            pledges[address(this)].work.debit += collected0;
            // (amount0, amount1) = _swap(amount0, amount1);
            // FIXME amount1 isn't getting split into amount0
            // emit RepackNFTamountsAfterSwap(amount0, amount1);
            NFPM.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams(
                    ID, amount0, amount1, 0, 0, block.timestamp
                )
            );
        }
    }
}
