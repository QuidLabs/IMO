
pragma solidity 0.8.25;
import {Script} from "../lib/forge-std/src/Script.sol";
import {mockVault} from "../src/mockVault.sol";
import {mockToken} from "../src/mockToken.sol";
import "../lib/forge-std/src/console.sol"; // TODO delete

import {Quid} from "../src/QD.sol";
import {MO} from "../src/MOulinette.sol";
import {WETH} from "../lib/solmate/src/tokens/WETH.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {ERC4626} from "../lib/solmate/src/tokens/ERC4626.sol";
import {IUniswapV3Pool} from "../src/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "../src/interfaces/IUniswapV3Factory.sol";
// import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol"; // TODO used on L1 mainnet
import {IV3SwapRouter} from "../src/interfaces/IV3SwapRouter.sol"; // used on Sepolia and Taiko...
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

contract Deploy is Script {
    Quid public quid;
    MO public moulinette; // TODO L1 mainnet
    mockToken public USDC;
    mockToken public DAI; // = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    mockVault public SDAI; // = ERC4626(0x83F20F44975D03b1b09e64809B757c47f942BEeA);
    mockToken public FRAX; // = ERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    mockVault public SFRAX; // = ERC4626(0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32);
    mockToken public USDE; // = ERC20(0x4c9EDD5852cd905f086C759E8383e09bff1E68B3);
    mockVault public SUSDE; // = ERC4626(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);

    IUniswapV3Factory public factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    IV3SwapRouter public router = IV3SwapRouter(0xd1AAE39293221B77B0C71fBD6dCb7Ea29Bb5B166);
    // Sepolia : 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E
    // Taiko : 0xdD489C75be1039ec7d843A6aC2Fd658350B067Cf
    INonfungiblePositionManager public nfpm = INonfungiblePositionManager(0xB7F724d6dDDFd008eFf5cc2834edDE5F9eF0d075);
    // Sepolia : 0x1238536071E1c677A632429e3655c799b22cDA52
    // Taiko : 0x8B3c541c30f9b29560f56B9E44b59718916B69EF
    IUniswapV3Pool public pool = IUniswapV3Pool(0xBeAD5792bB6C299AB11Eaa425aC3fE11ebA47b3B);
    // Sepolia : 0x3289680dD4d6C10bb19b899729cda5eEF58AEfF1
    // Taiko : 0xE47a76e15a6F3976c8Dc070B3a54C7F7083D668B
    WETH public weth = WETH(payable(0x4200000000000000000000000000000000000006));
    // Sepolia : 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14
    // Taiko : 0xA51894664A773981C6C112C43ce576f315d5b1B6

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
       
        // USDC = new mockToken(6);
        // USDC.mint();
        // weth.deposit{value: 2 ether}();

        DAI = new mockToken(18);
        SDAI = new mockVault(DAI);
        FRAX = new mockToken(18);
        SFRAX = new mockVault(FRAX);
        USDE = new mockToken(18);
        SUSDE = new mockVault(USDE);

        // factory.getPool(0x31d0220469e10c4E71834a79b1f276d740d3768F, address(weth), 500);
        // TODO some way to hardcode the order of token0 and token1
        // pool = IUniswapV3Pool(factory.createPool(
        //     address(weth), address(USDC), 500));
        // https://etherscan.io/address/0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640#readContract#F11
        // pool.initialize(1321184935443179556068722157521329);
        
        // USDC.approve(address(nfpm), type(uint256).max);
        // weth.approve(address(nfpm), type(uint256).max);

        moulinette = new MO(//Moulinette 
            address(weth), address(nfpm), 
            address(pool), address(router)
        );

        // nfpm.mint(INonfungiblePositionManager.MintParams({ 
        //     token0: address(USDC), token1: address(weth),
        //     fee: 500, tickLower: -887_200, tickUpper: 887_200,
        //     amount0Desired: 9000000000, amount1Desired: 2 ether,
        //     amount0Min: 0, amount1Min: 0, 
        //     recipient: 0xBE80666aA26710c2b2c3FD40c6663A013600D9b6,
        //     deadline: block.timestamp + 3600
        // }));

        quid = new Quid(address(moulinette), 
            address(USDE), address(SUSDE),
            address(FRAX), address (SFRAX),
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
