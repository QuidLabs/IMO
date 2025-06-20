
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol"; // TODO 

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IERC4626} from "forge-std/interfaces/IERC4626.sol";

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";

import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
// import {HookFee} from "../src/examples/HookFee.sol";

import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {IUniswapV3Pool} from "../src/imports/v3/IUniswapV3Pool.sol";
import {ISwapRouter} from "../src/imports/v3/ISwapRouter.sol";
// import {IV3SwapRouter as ISwapRouter} from "../src/imports/V3/IV3SwapRouter.sol";

import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";

import {Fixtures} from "./utils/Fixtures.sol";
import {Auxiliary} from "../src/Auxiliary.sol";
import {Router} from "../src/Router.sol";
import {Basket} from "../src/Basket.sol";

contract RouterTest is Test, Fixtures {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    uint public constant WAD = 1e18;
    uint public constant USDC_PRECISION = 1e6;

    address public User01 = address(0x1);
    address public User02 = address(0x2);

    ISwapRouter public V3router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV3Pool public V3pool = IUniswapV3Pool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);
    
    address[] public STABLECOINS;

    address public aavePool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2; // IPool
    address public aaveData = 0x3F78BBD206e4D3c504Eb854232EdA7e47E9Fd8FC; // // IUiPoolDataProvider
    address public aaveAddr = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e; // // IPoolAddressesProvider
    IERC20 public GHO = IERC20(0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f);

    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public USDS = IERC20(0xdC035D45d973E3EC169d2276DDab16f1e407384F);
    IERC20 public USDE = IERC20(0x4c9EDD5852cd905f086C759E8383e09bff1E68B3);
    IERC20 public CRVUSD = IERC20(0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E);
    IERC20 public FRAX = IERC20(0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29);
    
    address[] public VAULTS;
    IERC4626 public gauntletWETHvault = IERC4626(0x4881Ef0BF6d2365D3dd6499ccd7532bcdBCE0658);
    IERC4626 public smokehouseUSDCvault = IERC4626(0xBEeFFF209270748ddd194831b3fa287a5386f5bC);
    IERC4626 public smokehouseUSDTvault = IERC4626(0xA0804346780b4c2e3bE118ac957D1DB82F9d7484);

    // unlike other vaults, SGHO has its own interface (similar to ERC4626)
    IERC20 public SGHO = IERC20(0x1a88Df1cFe15Af22B3c4c783D4e6F7F9e0C1885d);
    IERC4626 public SDAI = IERC4626(0x83F20F44975D03b1b09e64809B757c47f942BEeA);
    IERC4626 public SFRAX = IERC4626(0xcf62F905562626CfcDD2261162a51fd02Fc9c5b6);
    IERC4626 public SUSDS = IERC4626(0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD);
    IERC4626 public SUSDE = IERC4626(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);
    IERC4626 public SCRVUSD = IERC4626(0x0655977FEb2f289A4aB78af67BAB0d17aAb84367);

    Basket public QUID;
    Auxiliary public AUX;
    Router public V4router;
    uint SWAP_COST = 1817119;
    uint stack = 10000 * USDC_PRECISION;
    function setUp() public {
        STABLECOINS = [
            address(USDC), address(USDT),
            address(DAI), address(USDS), 
            address(FRAX), address(USDE), 
            address(CRVUSD), address(GHO)
        ]; // ordering is very important!
        VAULTS = [
            address(smokehouseUSDCvault),
            address(smokehouseUSDTvault),
            address(SDAI), address(SUSDS), 
            address(SFRAX), address(SUSDE), 
            address(SCRVUSD), address(SGHO)
        ];
        uint mainnetFork = vm.createFork(
            "https://ethereum-rpc.publicnode.com",
            22209699); vm.selectFork(mainnetFork);
        
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();
        deployAndApprovePosm(manager); 
        
        vm.deal(address(this), 10000 ether);
        vm.deal(User01, 10000 ether);
        
        V4router = new Router(manager);
        AUX = new Auxiliary(address(V4router),
            address(V3pool), address(V3router),
            address(gauntletWETHvault), 
            aavePool, aaveData, aaveAddr);
        QUID = new Basket(address(V4router),
            address(AUX), STABLECOINS, VAULTS);

        vm.startPrank(0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341);
        USDC.transfer(address(AUX), 1 * USDC_PRECISION);
        USDC.transfer(User01, 1000000 * USDC_PRECISION); 
        vm.stopPrank();
        
        V4router.setup(address(QUID),
        address(AUX), address(V3pool));
        
        AUX.setQuid{value: 1 wei}(address(QUID));   

        vm.startPrank(User01);
        USDC.approve(address(QUID), 5 * stack);
        QUID.mint(User01, 50000 * WAD, address(USDC), 0);
        vm.stopPrank();
    }

    function testRegularSwaps() public {    
        vm.startPrank(User01);

        V4router.deposit{value: 25 ether}(0); // ADD LIQUIDITY TO POOL
        uint balanceBefore = User01.balance; // USDC.balanceOf(User01);

        // TEST OUT OF RANGE with ETH (above price)
        uint id = V4router.outOfRange{value: 1 ether}(0,
                            address(0), 400, 100);

        // USDC.approve(address(QUID), stack / 10);
        /* uint id = V4router.outOfRange(stack / 10,
                        address(USDC), -4000, 100); */ // below price with USDC works!

        uint balanceAfter = User01.balance; // USDC.balanceOf(User01);
        // assertApproxEqAbs(balanceBefore - balanceAfter, stack/10, 100);
        assertApproxEqAbs(balanceBefore - balanceAfter, 1 ether, 100);

        V4router.reclaim(id, 100);

        balanceAfter = User01.balance; // USDC.balanceOf(User01)
        assertApproxEqAbs(balanceBefore, balanceAfter, 108323224883144);

        uint price = AUX.getPrice(0, false);
        uint expectingToBuy = price / 1e12;
        uint USDCbalanceBefore = USDC.balanceOf(User01);

        AUX.swap{value: 1 ether}(address(USDC), false, 0, 2);
       
        vm.roll(vm.getBlockNumber() + 1);
        AUX.clearSwaps();

        uint USDCbalanceAfter = USDC.balanceOf(User01);
        assertApproxEqAbs(USDCbalanceAfter - USDCbalanceBefore, 
                                expectingToBuy, 1501571);

        price = AUX.getPrice(0, false);
        balanceBefore = User01.balance;
        // note, we're not approving the router!
        USDC.approve(address(QUID), (price / 1e12) * 4); 
        // but Basket, because QUID does transferFrom

        AUX.swap{value: SWAP_COST}(address(USDC), true, price / 1e12, 2);
        AUX.swap{value: SWAP_COST}(address(USDC), true, price / 1e12, 2);
        AUX.swap{value: SWAP_COST}(address(USDC), true, price / 1e12, 2);
        AUX.swap{value: SWAP_COST}(address(USDC), true, price / 1e12, 2);
        
        vm.roll(vm.getBlockNumber() + 1);
        AUX.clearSwaps();

        balanceAfter = User01.balance;
        assertApproxEqAbs(balanceAfter - balanceBefore, 
                            4 ether, 5045994876106820); // $9 fee 

        USDCbalanceBefore = USDC.balanceOf(User01);
        
        AUX.swap{value: 100 ether}(address(USDC), false, 0, 2);
        
        vm.roll(vm.getBlockNumber() + 1);
        AUX.clearSwaps();
        
        expectingToBuy = 100 ether * price / 1e30;

        USDCbalanceAfter = USDC.balanceOf(User01);

        assertApproxEqAbs(USDCbalanceAfter - USDCbalanceBefore,
                            expectingToBuy, 496504224); // $491 fee
                                                        // on a 75ETH sale
                                                        // is ~ 0.4%
        // TODO remove ETH
        vm.stopPrank();
    }

    // testing ability is limited because we can't
    // simulate a price drop inside the Univ3 pool
    function testWithdrawAndLeveragedSwaps() public {
        vm.startPrank(User01);
        V4router.deposit{value: 25 ether}(0);

        uint balanceBefore = User01.balance;
        V4router.withdraw(1 ether);
        uint balanceAfter = User01.balance;

        assertApproxEqAbs(balanceAfter - balanceBefore, 1 ether, 100000);

        address[] memory whose = new address[](1);
        whose[0] = User01;

        bool[] memory direction = new bool[](1);
        direction[0] = true;

        // uint price = AUX.getPrice(0, false);
        // uint expectingToBuy = price * 1 ether;
        // expectingToBuy += expectingToBuy / 25;
        // ^ leveraged swaps give a boosted gain

        AUX.leverOneForZero{value: 1 ether + 3524821}(0);

        // Simulate spike in price
        AUX.set_price_eth(true);

        // We will get "Too little received"
        // because the simulated price spike
        // will not correspond to pool price
        AUX.unwind(whose, direction);

        USDC.approve(address(QUID), stack / 10);
        AUX.leverZeroForOne{value : 3524821}(stack / 10,
                            address(USDC));
        vm.stopPrank();
    }
    
    function testRedeem() public {
        vm.startPrank(User01);

        uint USDCbalanceBefore = USDC.balanceOf(User01);
        // amount hasn't matured yet, min 1 month maturity
        AUX.redeem(1000 * WAD);

        uint USDCbalanceAfter = USDC.balanceOf(User01);
        assertApproxEqAbs(USDCbalanceAfter,
                          USDCbalanceBefore, 1);

        vm.warp(vm.getBlockTimestamp() + 30 days);
        AUX.redeem(1000 * WAD);

        USDCbalanceAfter = USDC.balanceOf(User01);
        assertApproxEqAbs(USDCbalanceAfter -
            USDCbalanceBefore, stack / 10, 1);

        vm.stopPrank();
    } 
}
