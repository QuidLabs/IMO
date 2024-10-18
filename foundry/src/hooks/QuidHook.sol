/// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.8;


import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";

/// contracts
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {Owned} from "lib/solmate/src/auth/Owned.sol";
import {WETH} from "lib/solmate/src/tokens/WETH.sol";

contract QuidHook is Owned(msg.sender) {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for WETH;

}