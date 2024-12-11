// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25; // evm: london
import {Quid} from "../src/QD.sol";
import {MO} from "../src/MOulinette.sol";

import {mockVault} from "../src/mockVault.sol";
import {mockToken} from "../src/mockToken.sol";

import "../src/interfaces/IERC721.sol";
import "lib/forge-std/src/console.sol"; // TODO delete
import {Test} from "../lib/forge-std/src/Test.sol";

import {WETH} from "../lib/solmate/src/tokens/WETH.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {ERC4626} from "../lib/solmate/src/tokens/ERC4626.sol";
import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "../src/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

interface ICollection is IERC721 {
    function latestTokenId()
    external view returns (uint);
} 
contract MainnetFork is Test {
    Quid public quid;
    MO public moulinette;
    mockToken public DAI; // = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    mockVault public SDAI; // = ERC4626(0x83F20F44975D03b1b09e64809B757c47f942BEeA);
    mockToken public FRAX; // = ERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    mockVault public SFRAX; // = ERC4626(0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32);
    mockToken public USDE; // = ERC20(0x4c9EDD5852cd905f086C759E8383e09bff1E68B3);
    mockVault public SUSDE; // = ERC4626(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);

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
    uint public dub_dub_in_eth = 10000000000000000; // ~$40
    
    function setUp() public {
        uint256 mainnetFork = vm.createFork("https://rpc.ankr.com/eth", 21346033);
        vm.selectFork(mainnetFork);

        vm.deal(User01, 1_000_000_000_000_000 ether);
        vm.deal(User02, 1_000_000_000_000_000 ether);
        vm.deal(User03, 1_000_000_000_000_000 ether);
        
        DAI = new mockToken(18);
        // SDAI = new mockVault(DAI);
        // FRAX = new mockToken(18);
        // SFRAX = new mockVault(FRAX);
        USDE = new mockToken(18);
        SUSDE = new mockVault(USDE);
        USDS = new mockToken(18);
        SUSDS = new mockToken(USDE);

        moulinette = new MO(// Moulinette 
            address(weth), address(usdc), 
            address(nfpm), address(pool), 
            address(router)
        );
        quid = new Quid(address(moulinette), 
            address(usdc), address(USDE), 
            address(SUSDE), /* address(FRAX), address (SFRAX),
            address (SDAI), */ address(DAI),
            address(USDS), address(SUSDS)
        );

        moulinette.setQuid(address(quid));
        moulinette.set_price_eth(false, true);
    }
    
    function testEverything() public {
        uint weth_debit; uint weth_credit; 
        uint work_debit; uint work_credit;
        uint quid_debit; uint quid_credit;

        // TODO simulate a large transfer from 
        // large holder of USDe to the test account
        vm.startPrank(User01); USDE.mint();
        weth.deposit{value: 1_000_000 ether}();

        USDE.approve(address(quid), type(uint256).max);
        quid.mint(User01, half_a_rack, address(USDE));
        quid.mint(User01, half_a_rack, address(USDE));

        uint minted = quid.balanceOf(User01);
        assertEq(minted, rack);

        (quid_credit, 
         quid_debit) = moulinette.get_info(User01);
        console.log("User1...before transfer", quid_credit, quid_debit);

        uint a; uint b; uint c; uint d;
        (work_debit, work_credit, 
         weth_debit, weth_credit) = moulinette.get_more_info(User01);
        quid.transfer(User02, grant);
        vm.stopPrank(); // exit User1 context

        // transfer backward 
        vm.startPrank(User02); 
        quid.transfer(User01, grant);
        vm.stopPrank();
       
        (a,b,c,d) = moulinette.get_more_info(User01);
        // and verify that carry.debit
        // before and after are the same
        assertEq(a, work_debit);
        assertEq(b, work_credit);
        assertEq(c, weth_debit);
        assertEq(d, weth_credit);
        uint beforeBatch = quid.currentBatch();
        
        // Simulate passage of time
        vm.warp(block.timestamp + 14 days);
        
        vm.startPrank(User02);
        USDE.mint();
        weth.deposit{value: 1_000_000 ether}();

        weth.approve(address(moulinette), type(uint256).max);
        USDE.approve(address(quid), type(uint256).max);
        quid.mint(User02, bill, address(USDE));

        minted = quid.balanceOf(User02);

        (quid_credit, 
         quid_debit) = moulinette.get_info(User02); 
        console.log("User2...", quid_credit, quid_debit); 

        vm.stopPrank(); // exit User2 context

        (quid_credit, quid_debit) = moulinette.get_info(User01);
        console.log("User1...after transfer", quid_credit, quid_debit);
        
        vm.startPrank(User01);
        
        weth.approve(address(moulinette), dub_dub_in_eth);
        moulinette.deposit(User01, dub_dub_in_eth, false);
        
        (work_debit, work_credit, 
         weth_debit, weth_credit) = moulinette.get_more_info(User01);

        console.log("User1...more_info beforeFOLD", 
            work_debit, work_credit, weth_debit
        );
        moulinette.fold(User01, dub_dub_in_eth, false);

        (work_debit, work_credit, 
         weth_debit, weth_credit) = moulinette.get_more_info(User01);

        console.log("User1...more_info AFTERfold", 
            work_debit, work_credit, weth_debit
        );
        
        uint256 balanceBefore = User01.balance;
        console.log("user1BalanceBefore withdraw ETH...", balanceBefore);
        moulinette.withdraw(dub_dub_in_eth, false);

        uint256 balanceAfter = User01.balance;
        console.log("user1BalanceAFTER withdraw ETH...", balanceAfter);
        vm.stopPrank(); // TODO no deductible if fold without price drop

        vm.startPrank(User03);

        uint thirtyThree = 33000000000000000000;
        moulinette.withdraw{value: dub_dub_in_eth}(thirtyThree, true);

        (work_debit, work_credit, 
         weth_debit, weth_credit) = moulinette.get_more_info(User03);

        console.log("User3...more_info AFTER borrow", 
            work_debit, work_credit, weth_debit
        );
        console.log("QD that was minted for User3...", quid.balanceOf(User03));

        vm.stopPrank();
        console.log("price before drop", moulinette.getPrice(42));
        moulinette.set_price_eth(false, false);
        moulinette.set_price_eth(false, false);
        console.log("price AFTER drop", moulinette.getPrice(42));
        moulinette.fold(User03, 1, false); // for a liquidation amount variable is irrelevant

        (work_debit, work_credit, 
         weth_debit, weth_credit) = moulinette.get_more_info(User03);

        console.log("User3...more_info AFTER liquidation (1st)", 
            work_debit, work_credit, weth_debit
        );

        vm.warp(block.timestamp + 61 minutes);

        moulinette.fold(User03, 1, false); // for a liquidation amount variable is irrelevant
         (work_debit, work_credit, 
         weth_debit, weth_credit) = moulinette.get_more_info(User03);

        console.log("User3...more_info AFTER liquidation (1 hour later)", 
            work_debit, work_credit, weth_debit
        );


        // TODO 
        // assertEq(minted, rack);

        /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
        /*                       LOTTERY TESTING                      */
        /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

        vm.startPrank(User01);
        quid.vote(77);
        vm.stopPrank();
        
        vm.startPrank(User02);
        quid.vote(77);
        vm.stopPrank();
        
        vm.startPrank(User03);
        quid.vote(77);
        vm.stopPrank();
        
        vm.startPrank(User04);
        quid.vote(77);
        vm.stopPrank();
        
        vm.startPrank(User05);
        quid.vote(77);
        vm.stopPrank();
        
        vm.startPrank(User06);
        quid.vote(77);
        vm.stopPrank();
        
        vm.startPrank(User07);
        quid.vote(77);
        vm.stopPrank();
        
        vm.startPrank(User08);
        quid.vote(77);
        vm.stopPrank();
        
        vm.startPrank(User09);
        quid.vote(77);
        vm.stopPrank();

        vm.warp(block.timestamp + 34 days);

        vm.startPrank(0x42cc020Ef5e9681364ABB5aba26F39626F1874A4);
        F8N.approve(address(quid), 16508);
        vm.stopPrank();

        uint avg_roi_before = quid.AVG_ROI();
        
        vm.startPrank(address(quid));
        bytes32 seed = 0xfecf91618d752d88c3c7ed03b6040823a43b4a88edd2372a0a07aa348780c85b;
        F8N.safeTransferFrom(0x42cc020Ef5e9681364ABB5aba26F39626F1874A4,
            address(quid), 16508, abi.encode(seed));
        assertEq(F8N.ownerOf(16508), 0x42cc020Ef5e9681364ABB5aba26F39626F1874A4);
        // ^^^^^ checks that the NFT was sent back properly 
        vm.stopPrank();

        uint avg_roi_after = quid.AVG_ROI();
        uint afterBatch = quid.currentBatch();
        assertNotEq(beforeBatch, afterBatch);
        assertNotEq(avg_roi_before, avg_roi_after);
    }

    /*
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