// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

contract VerifyContracts is Script {
    function run() external {
        // Get contract addresses from environment
        address implementationAddress = vm.envAddress("AVALANCHE_MAINNET_IMPLEMENTATION");
        address proxyAddress = vm.envAddress("AVALANCHE_MAINNET_WORKFLOW_MANAGER_CONTRACT_ADDRESS");
        address proxyAdminAddress = vm.envAddress("AVALANCHE_MAINNET_PROXY_ADMIN");
        
        console.log("====================================");
        console.log("SNOWTRACE VERIFICATION COMMANDS");
        console.log("====================================");
        
        console.log("1. Verify Implementation Contract:");
        console.log("forge verify-contract", implementationAddress, "src/WorkflowManager.sol:WorkflowManager");
        console.log("--verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan'");
        console.log("--etherscan-api-key 'verifyContract'");
        console.log("--num-of-optimizations 200");
        console.log("--compiler-version 0.8.28");
        console.log("");
        
        console.log("2. Verify ProxyAdmin Contract:");
        console.log("forge verify-contract", proxyAdminAddress, "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin");
        console.log("--verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan'");
        console.log("--etherscan-api-key 'verifyContract'");
        console.log("--num-of-optimizations 200");
        console.log("--compiler-version 0.8.28");
        console.log("");
        
        console.log("3. Verify Proxy Contract:");
        console.log("forge verify-contract", proxyAddress, "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy");
        console.log("--verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan'");
        console.log("--etherscan-api-key 'verifyContract'");
        console.log("--num-of-optimizations 200");
        console.log("--compiler-version 0.8.28");
        console.log("");
        
        console.log("====================================");
        console.log("Copy and run these commands one by one:");
        console.log("====================================");
    }
} 