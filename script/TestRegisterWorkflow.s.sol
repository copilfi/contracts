// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WorkflowManager} from "../src/WorkflowManager.sol";
import "chainlink/src/v0.8/automation/interfaces/v2_3/IAutomationRegistryMaster2_3.sol";

contract TestRegisterWorkflow is Script {
    WorkflowManager public workflowManager = WorkflowManager(0x45D7cFf37e48fC40ef74e3A8De4B3F16F7A0b16d);
    IAutomationRegistryMaster2_3 public registry = IAutomationRegistryMaster2_3(payable(0x819B58A646CDd8289275A87653a2aA4902b14fe6));
    
    function run() external {
        console.log("Testing Workflow Registration...");
        
        // Test registry interface
        console.log("Registry address:", address(registry));
        
        // Try to call the registry function directly with a simple test
        vm.startBroadcast(0xcb4d3be21aa358ca409930a36de0d02ac488f1eeab3df5fb993c62bccd90dc80);
        
        try registry.registerUpkeep(
            address(workflowManager), // target
            500000, // gasLimit
            0xb86310B82948a24eEd94b1764939f1fa20805d60, // admin
            0, // triggerType
            0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846, // billingToken (LINK)
            abi.encode(uint256(12345)), // checkData
            bytes(""), // triggerConfig
            bytes("") // offchainConfig
        ) returns (uint256 upkeepId) {
            console.log("Registry call successful, upkeepId:", upkeepId);
        } catch Error(string memory reason) {
            console.log("Registry call failed:", reason);
        } catch (bytes memory) {
            console.log("Registry call failed with unknown error");
        }
        
        vm.stopBroadcast();
    }
} 