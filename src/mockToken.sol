// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.25;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract mockToken is ERC20 {

    uint constant public WAD = 1e18;

    // Pass the underlying asset (ERC20 token) to ERC4626 constructor
    constructor() ERC20("mock", "mock", 18) {}

    function mint() external {
        _mint(msg.sender, WAD * 10000);
    }

}

