/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

// import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
// import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
// import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
// import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
// import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
// import { TokenConfig, LiquidityManagement, HookFlags, 
//     AddLiquidityKind, RemoveLiquidityKind, AddLiquidityParams
// } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
// import { MinimalRouter } from "./MinimalRouter.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ERC721} from "lib/solmate/src/tokens/ERC721.sol";
import {Owned} from "lib/solmate/src/auth/Owned.sol";
import {WETH} from "lib/solmate/src/tokens/WETH.sol";
// import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";

contract QuidHook is Owned(msg.sender) {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for WETH;

}