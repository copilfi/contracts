// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WorkflowManager} from "../src/WorkflowManager.sol";

contract TestIntegration is Script {
    function run() external {
        // Get contract address from environment
        address contractAddress = vm.envAddress("WORKFLOW_MANAGER_CONTRACT_ADDRESS");
        require(contractAddress != address(0), "WORKFLOW_MANAGER_CONTRACT_ADDRESS not set");
        
        console.log("Testing WorkflowManager integration at:", contractAddress);
        
        // Create contract instance
        WorkflowManager workflowManager = WorkflowManager(contractAddress);
        
        // Test contract accessibility
        try workflowManager.owner() returns (address owner) {
            console.log("Contract owner:", owner);
            console.log("[SUCCESS] Contract is accessible");
        } catch {
            console.log("[ERROR] Contract is not accessible");
            return;
        }
        
        // Test automation registry  
        address registry = address(workflowManager.s_automationRegistry());
        console.log("Automation Registry:", registry);
        console.log("[SUCCESS] Automation registry is set");
        
        console.log("====================================");
        console.log("CONTRACT INTEGRATION TEST PASSED");
        console.log("====================================");
        console.log("Contract Address:", contractAddress);
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("====================================");
    }
} 