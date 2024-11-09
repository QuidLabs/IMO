// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.25;

import {ERC4626} from "lib/solmate/src/tokens/ERC4626.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract mockVault is ERC4626 { 
    
    uint constant public WAD = 1e18; 

    // Pass the underlying asset (ERC20 token) to ERC4626 constructor
    constructor(ERC20 asset) ERC4626(asset, "mockVault", "mockShares") {}


    function totalAssets() public view override returns (uint256) {
        return asset.totalSupply();
    }

    function mint() external {
        _mint(msg.sender, WAD * 10000);
    }

}