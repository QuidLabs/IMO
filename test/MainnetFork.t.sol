// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.8;

import {Test} from "../lib/forge-std/src/Test.sol";
import {mockVault} from "../src/mockVault.sol";
import {mockToken} from "../src/mockToken.sol";
import {MO} from "../src/MOulinette.sol";
import {Quid} from "../src/QD.sol";
import "../src/interfaces/IERC721.sol";
import "lib/forge-std/src/console.sol"; // TODO delete
import {WETH} from "../lib/solmate/src/tokens/WETH.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {IUniswapV3Pool} from "../src/interfaces/IUniswapV3Pool.sol";
import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol";
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

interface ICollection is IERC721 {
    function latestTokenId()
    external view returns (uint);
} 
contract MainnetFork is Test {
    Quid public quid;
    MO public moulinette;
    mockVault public sUSDe;
    mockToken public USDe;
    address public chainlink = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    ICollection public F8N = ICollection(0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405); 
    ISwapRouter public router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    INonfungiblePositionManager public nfpm = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IUniswapV3Pool public pool = IUniswapV3Pool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);
    WETH public weth = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));    
    ERC20 public usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    
    address public User01 = address(0x1);
    address public User02 = address(0x2);
    address public User03 = address(0x3);
    address public User04 = address(0x4);
    address public User05 = address(0x5);

    uint public half_a_rock = 500000000000000000000000; // $500k
    uint public rack = 1000000000000000000000; // $1000
    uint public bill = 100000000000000000000; // $100
    uint public grant = 50000000000000000000; // $50
    uint public jackson_in_ETH = 1000000000000000; // $26
    
    function setUp() public {
        uint256 mainnetFork = vm.createFork("https://rpc.ankr.com/eth", 21082583);
        vm.selectFork(mainnetFork);

        vm.deal(User01, 1_000_000 ether);
        vm.deal(User02, 1_000_000 ether);
        
        USDe = new mockToken();
        sUSDe = new mockVault(USDe);

        moulinette = new MO(
            address(USDe), address(sUSDe), 
            address(weth), address(nfpm), 
            address(pool), address(router)
        );
        quid = new Quid(address(moulinette), chainlink);
        moulinette.setQuid(address(quid));

        quid.restart();
        moulinette.set_price_eth(false, true);
    }
    
    function testEverything() public {
        uint weth_debit; uint weth_credit; 
        uint work_debit; uint work_credit;
        uint quid_debit; uint quid_credit;

        vm.startPrank(User01);
        USDe.mint();
        weth.deposit{value: 1_000_000 ether}();

        weth.approve(address(moulinette), type(uint256).max);
        USDe.approve(address(moulinette), type(uint256).max);

        moulinette.deposit(User01, bill, address(USDe), false);

        uint minted = quid.balanceOf(User01);
        assertEq(minted, bill);

        (quid_credit, 
         quid_debit) = moulinette.get_info(User01);
        console.log("User1...before transfer", quid_credit, quid_debit);

        quid.transfer(User02, grant);

        vm.stopPrank(); // exit User1 context

        // Simulate passage of time
        vm.warp(block.timestamp + 14 days);
        
        vm.startPrank(User02);
        USDe.mint();
        weth.deposit{value: 1_000_000 ether}();

        weth.approve(address(moulinette), type(uint256).max);
        USDe.approve(address(moulinette), type(uint256).max);

        moulinette.deposit(User02, bill, address(USDe), false);

        minted = quid.balanceOf(User02);

        (quid_credit, 
         quid_debit) = moulinette.get_info(User02); 
        console.log("User2...", quid_credit, quid_debit); 

        vm.stopPrank(); // exit User2 context

        (quid_credit, quid_debit) = moulinette.get_info(User01);
        console.log("User1...after transfer", quid_credit, quid_debit);
        
        vm.startPrank(User01);
        
        weth.approve(address(moulinette), jackson_in_ETH);
        moulinette.deposit(User01, jackson_in_ETH, address(weth), false);
        
        (work_debit, work_credit, 
         weth_debit, weth_credit) = moulinette.get_more_info(User01);

        console.log("User1...more_info beforeFOLD", 
            work_debit, work_credit, weth_debit
        );
        moulinette.fold(User01, jackson_in_ETH, false);

        (work_debit, work_credit, 
         weth_debit, weth_credit) = moulinette.get_more_info(User01);

        console.log("User1...more_info AFTERfold", 
            work_debit, work_credit, weth_debit
        );
        vm.stopPrank();
    }

    /*
        vm.startPrank(0x42cc020Ef5e9681364ABB5aba26F39626F1874A4);
        F8N.approve(address(moulinette), 16508);
        F8N.transferFrom(0x42cc020Ef5e9681364ABB5aba26F39626F1874A4,
            address(moulinette), 16508);
        vm.stopPrank();

        assertGt(amountOut, 0);

         vm.expectRevert(FoldCaptiveStaking.AlreadyInitialized.selector);

         /// @dev Ensure the contract is protected against reentrancy attacks.
        function testReentrancy() public {
            testAddLiquidity();

            // Create a reentrancy attack contract and attempt to exploit the staking contract
            ReentrancyAttack attack = new ReentrancyAttack(payable(address(foldCaptiveStaking)));
            fold.transfer(address(attack), 1 ether);
            weth.transfer(address(attack), 1 ether);

            vm.expectRevert();
            attack.attack();
        }
    */
}

// Reentrancy attack contract
/*
contract ReentrancyAttack {
    FoldCaptiveStaking public staking;

    constructor(address payable _staking) {
        staking = FoldCaptiveStaking(_staking);
    }

    function attack() public {
        staking.deposit(1 ether, 1 ether, 0);
        staking.withdraw(1);
    }

    receive() external payable {
        staking.withdraw(1);
    }
} */