// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import {Script, console} from "forge-std/Script.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
    }
}
