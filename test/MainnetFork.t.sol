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
import {ERC4626} from "../lib/solmate/src/tokens/ERC4626.sol";
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
    
    ERC20 public DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC4626 public SDAI = ERC4626(0x83F20F44975D03b1b09e64809B757c47f942BEeA);
    ERC20 public FRAX = ERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    ERC4626 public SFRAX = ERC4626(0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32);
    // ERC20 public USDE = ERC20(0x4c9EDD5852cd905f086C759E8383e09bff1E68B3);
    // ERC4626 SUSDE = ERC4626(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);
    
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
    address public User06 = address(0x6);
    address public User07 = address(0x7);
    address public User08 = address(0x8);
    address public User09 = address(0x9);
    address public User10 = address(0x10);
    address public User11 = address(0x11);
    address public User12 = address(0x12);
    address public User13 = address(0x13);
    address public User14 = address(0x14);
    address public User15 = address(0x15);
    address public User16 = address(0x16);
    address public User17 = address(0x17);

    uint public half_a_rock = 500000000000000000000000; // $500k
    uint public rack = 1000000000000000000000; // $1000
    uint public bill = 100000000000000000000; // $100
    uint public half_a_rack = 500000000000000000000; // $500
    uint public grant = 50000000000000000000; // $50
    uint public jackson_in_ETH = 1000000000000000; // ~$26
    
    function setUp() public {
        uint256 mainnetFork = vm.createFork("https://rpc.ankr.com/eth", 21082583);
        vm.selectFork(mainnetFork);

        vm.deal(User01, 1_000_000 ether);
        vm.deal(User02, 1_000_000 ether);
        
        USDe = new mockToken();
        sUSDe = new mockVault(USDe);
        // FRAX = new mockToken();
        // sFRAX = new mockVault(FRAX);
        // DAI = new mockToken();
        // sDAI = new mockVault(DAI);

        moulinette = new MO(
            address(weth), address(nfpm), 
            address(pool), address(router)
        );
        quid = new Quid(
            address(moulinette), chainlink, 
            address(USDe), address(sUSDe),
            address(FRAX), address (SFRAX),
            address (SDAI), address (DAI)
        );

        moulinette.setQuid(address(quid));
        quid.restart();
        quid.set_price_eth(false, true);
    }
    
    function testEverything() public {
        uint weth_debit; uint weth_credit; 
        uint work_debit; uint work_credit;
        uint quid_debit; uint quid_credit;

        vm.startPrank(User01);
        USDe.mint();
        weth.deposit{value: 1_000_000 ether}();

        weth.approve(address(moulinette), type(uint256).max);
        USDe.approve(address(quid), type(uint256).max);

        quid.mint(User01, half_a_rack, address(USDe));
        quid.mint(User01, half_a_rack, address(USDe));

        uint minted = quid.balanceOf(User01);
        assertEq(minted, rack);

        (quid_credit, 
         quid_debit) = moulinette.get_info(User01);
        console.log("User1...before transfer", quid_credit, quid_debit);

        quid.transfer(User02, grant);
        vm.stopPrank(); // exit User1 context

        // TODO transfer back and verify that carry.debit before and after are the same

        // Simulate passage of time
        vm.warp(block.timestamp + 14 days);
        
        vm.startPrank(User02);
        USDe.mint();
        weth.deposit{value: 1_000_000 ether}();

        weth.approve(address(moulinette), type(uint256).max);
        USDe.approve(address(quid), type(uint256).max);
        quid.mint(User02, bill, address(USDe));

        minted = quid.balanceOf(User02);

        (quid_credit, 
         quid_debit) = moulinette.get_info(User02); 
        console.log("User2...", quid_credit, quid_debit); 

        vm.stopPrank(); // exit User2 context

        (quid_credit, quid_debit) = moulinette.get_info(User01);
        console.log("User1...after transfer", quid_credit, quid_debit);
        
        vm.startPrank(User01);
        
        weth.approve(address(moulinette), jackson_in_ETH);
        moulinette.deposit(User01, jackson_in_ETH, false);
        
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



        /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
        /*                       LOTTERY TESTING                      */
        /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/


        vm.startPrank(User01);

        quid.vote(77);

        vm.stopPrank();


        // vm.startPrank(User01);

        // quid.vote(77);

        // vm.stopPrank();
        // vm.startPrank(User02);

        // quid.vote(77);

        // vm.stopPrank();
        // vm.startPrank(User03);

        // quid.vote(77);

        // vm.stopPrank();
        // vm.startPrank(User04);

        // quid.vote(77);

        // vm.stopPrank();
        // vm.startPrank(User05);

        // quid.vote(77);

        // vm.stopPrank();
        // vm.startPrank(User06);

        // quid.vote(77);

        // vm.stopPrank();
        // vm.startPrank(User07);

        // quid.vote(77);

        // vm.stopPrank();
        // vm.startPrank(User08);

        // quid.vote(77);

        // vm.stopPrank();
        // vm.startPrank(User09);

        // quid.vote(77);

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