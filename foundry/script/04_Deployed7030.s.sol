//SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

// import {Script, console} from "forge-std/Script.sol";
import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";


import {
    TokenConfig,
    TokenType,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";

import { PoolHelpers, CustomPoolConfig, InitializationConfig } from "./PoolHelpers.sol";
// TODO hook and factory
/**
 * @title Deploy Constant Sum Pool
 * @notice Deploys, registers, and initializes a constant sum pool that uses a swap fee discount hook
 */
contract DeployConstantSumPool is PoolHelpers, ScaffoldHelpers {

    function setUp() public {}

    function run() public {
        vm.broadcast();
    }

}