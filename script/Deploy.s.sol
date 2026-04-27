// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {OnchainNotes} from "../src/OnchainNotes.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        OnchainNotes onchainNotes = new OnchainNotes();
        vm.stopBroadcast();

        console.log("OnchainNotes deployed at:", address(onchainNotes));
    }
}
