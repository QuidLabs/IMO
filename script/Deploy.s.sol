// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import {Script} from "../lib/forge-std/src/Script.sol";
import {mockVault} from "../src/mockVault.sol";
import {mockToken} from "../src/mockToken.sol";
import "../lib/forge-std/src/console.sol"; // TODO delete

import {Quid} from "../src/QD.sol";
import {MO} from "../src/MOulinette.sol";
import {WETH} from "../lib/solmate/src/tokens/WETH.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {IUniswapV3Pool} from "../src/interfaces/IUniswapV3Pool.sol";
import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol";
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

contract Deploy is Script {
    Quid public quid;
    MO public moulinette;
    mockVault public sUSDe;
    mockToken public USDe;
    mockVault public sFRAX;
    mockToken public FRAX;
    mockVault public sDAI;
    mockToken public DAI;
    address public chainlink = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    // TODO the interface of the router is a bit different on mainnet than it is on Taiko
    ISwapRouter public router = ISwapRouter(0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E);
    // 0xdD489C75be1039ec7d843A6aC2Fd658350B067Cf 
    INonfungiblePositionManager public nfpm = INonfungiblePositionManager(0x1238536071E1c677A632429e3655c799b22cDA52);
    // 0x8B3c541c30f9b29560f56B9E44b59718916B69EF
    IUniswapV3Pool public pool = IUniswapV3Pool(0x3289680dD4d6C10bb19b899729cda5eEF58AEfF1);
    // 0xe47a76e15a6f3976c8dc070b3a54c7f7083d668b
    WETH public weth = WETH(payable(0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14));
    // 0xa51894664a773981c6c112c43ce576f315d5b1b6 

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        USDe = new mockToken();
        sUSDe = new mockVault(USDe);
        FRAX = new mockToken();
        sFRAX = new mockVault(FRAX);
        DAI = new mockToken();
        sDAI = new mockVault(DAI);


        moulinette = new MO(
            address(weth), address(nfpm), 
            address(pool), address(router)
        );
        quid = new Quid(
            address(moulinette), chainlink, 
            address(USDe), address(sUSDe),
            address(FRAX), address (sFRAX),
            address (sDAI), address (DAI)
        );
        
        moulinette.setQuid(address(quid));
        quid.restart();
        moulinette.set_price_eth(false, true);
        
        console.log("Quid address...", address(quid));
        console.log("USDe address...", address(USDe));
        console.log("sUSDe address...", address(sUSDe));
        console.log("Moulinette address...", address(moulinette));

        vm.stopBroadcast();
    }
}
