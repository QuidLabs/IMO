
pragma solidity 0.8.25;
import {Script} from "../lib/forge-std/src/Script.sol";
import {mockVault} from "../src/mockVault.sol";
import {mockToken} from "../src/mockToken.sol";
import "../lib/forge-std/src/console.sol"; // TODO delete

import {Quid} from "../src/QD.sol";
import {MO} from "../src/MOulinette.sol";
import {WETH} from "../lib/solmate/src/tokens/WETH.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
// import {ERC4626} from "../lib/solmate/src/tokens/ERC4626.sol";
import {IUniswapV3Pool} from "../src/interfaces/IUniswapV3Pool.sol";
// import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol"; // This is is used on L1 mainnet
import {IV3SwapRouter} from "../src/interfaces/IV3SwapRouter.sol"; // used on Sepolia and Taiko...
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

contract Deploy is Script {
    Quid public quid;
    MO public moulinette;
    mockToken public DAI; // = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    mockVault public SDAI; // = ERC4626(0x83F20F44975D03b1b09e64809B757c47f942BEeA);
    // mockToken public FRAX; // = ERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    // mockVault public SFRAX; // = ERC4626(0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32);
    // mockToken public USDE; // = ERC20(0x4c9EDD5852cd905f086C759E8383e09bff1E68B3);
    // mockVault public SUSDE; // = ERC4626(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);

    IV3SwapRouter public router = IV3SwapRouter(0xdD489C75be1039ec7d843A6aC2Fd658350B067Cf);
    // Sepolia : 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E
    INonfungiblePositionManager public nfpm = INonfungiblePositionManager(0x8B3c541c30f9b29560f56B9E44b59718916B69EF);
    // Sepolia " 0x1238536071E1c677A632429e3655c799b22cDA52
    IUniswapV3Pool public pool = IUniswapV3Pool(0xE47a76e15a6F3976c8Dc070B3a54C7F7083D668B);
    // Sepolia : 0x3289680dD4d6C10bb19b899729cda5eEF58AEfF1
    WETH public weth = WETH(payable(0xA51894664A773981C6C112C43ce576f315d5b1B6));
    // Sepolia : 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        DAI = new mockToken();
        SDAI = new mockVault(DAI);
        // FRAX = new mockToken();
        // SFRAX = new mockVault(FRAX);
        // USDE = new mockToken();
        // SUSDE = new mockVault(USDE);

        moulinette = new MO(
            address(weth), address(nfpm), 
            address(pool), address(router)
        );
        quid = new Quid(
            address(moulinette), 
            // address(USDE), address(SUSDE),
            // address(FRAX), address (SFRAX),
            address (SDAI), address (DAI)
        );
        
        moulinette.setQuid(address(quid));
        moulinette.set_price_eth(false, true);
        
        console.log("Quid address...", address(quid));
        console.log("USDe address...", address(DAI));
        console.log("sUSDe address...", address(SDAI));
        console.log("Moulinette address...", address(moulinette));

        vm.stopBroadcast();
    }
}
