// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import {Test, console} from "forge-std/Test.sol";
import {mockVault} from "../src/mockVault.sol";
import {mockToken} from "../src/mockToken.sol";
import {MO} from "../src/MOulinette.sol";
import {Quid} from "../src/QD.sol";

import {WETH} from "lib/solmate/src/tokens/WETH.sol";
import {IUniswapV3Pool} from "../src/interfaces/IUniswapV3Pool.sol";
import {IV3SwapRouter} from "../src/interfaces/IV3SwapRouter.sol";
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

contract MainTest is Test {
    Quid public quid;
    MO public moulinette;
    mockVault public sUSDe;
    mockToken public USDe;

    IV3SwapRouter public router = IV3SwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    INonfungiblePositionManager public nfpm = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IUniswapV3Pool public pool = IUniswapV3Pool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);
    WETH public weth = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));    

    address public User01 = address(0x1);
    address public User02 = address(0x2);
    address public User02 = address(0x3);
    address public User02 = address(0x4);
    address public User02 = address(0x5);

    uint public half_a_rock = 500000000000000000000000; // $500k
    uint public rack = 1000000000000000000000; // $1000
    uint public bill = 100000000000000000000; // $100
    uint public grant = 50000000000000000000; // $50
    
    function setUp() public {
        uint256 mainnetFork = vm.createFork("https://rpc.ankr.com/eth", 20185705);
        vm.selectFork(mainnetFork);
        address self = address(this);

        vm.deal(address(this), 1_000_000 ether);
        weth.deposit{value: 1_000_000 ether}();

        vm.deal(User01, 1_000_000 ether);
        vm.deal(User02, 1_000_000 ether);
        
        USDe = new mockToken();
        sUSDe = new mockVault(USDe);

        USDe.mint(User01);
        USDe.mint(User02);
        USDe.mint(User03);
        USDe.mint(User04);
        USDe.mint(User05);

        moulinette = new MO(
            address(USDe), address(sUSDe), 
            address(weth), address(nfpm), 
            address(pool), address(router)
        );
        quid = new Quid(address(moulinette));
        moulinette.setQuid(address(quid));

        quid.restart();
        moulinette.set_price_eth(false, true);
    }
    
    function testDiscountedMint() public {
        vm.startPark(User01);
        
        weth.deposit{value: 1_000_000 ether}();

        weth.approve(address(moulinette), type(uint256).max);
        USDe.approve(address(moulinette), type(uint256).max);

        moulinette.deposit(User01, bill, address(USDe), false);

        uint minted = quid.balanceOf(User01);
        assertEq(minted, bill);

        vm.stopPrank();

        // Simulate passage of time
        vm.warp(block.timestamp + 14 days);
        
        vm.startPark(User02);
        
        weth.deposit{value: 1_000_000 ether}();

        weth.approve(address(moulinette), type(uint256).max);
        USDe.approve(address(moulinette), type(uint256).max);

        moulinette.deposit(User02, bill, address(USDe), false);

        minted = quid.balanceOf(User02);
        assertEq(amount, bill);
        
        vm.stopPrank();
    }
}
