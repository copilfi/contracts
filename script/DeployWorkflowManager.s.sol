// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WorkflowManager} from "../src/WorkflowManager.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployWorkflowManager is Script {
    // Network-specific Chainlink Automation Registry addresses
    mapping(uint256 => address) private automationRegistries;
    
    function setUp() public {
        // Avalanche Fuji Testnet
        automationRegistries[43113] = 0x07F697262a4d3f35Ff5518131372a29a518f8F20;
        
        // Avalanche Mainnet  
        automationRegistries[43114] = 0xe6aE229FbBfAcd17cf17dD3eFD0E1F3c1d9b4F0f;
        
        // Add more networks as needed
        // Ethereum Mainnet: 0x02777053d6764996e594c3E88AF1D58D5363a2e6
        // Ethereum Sepolia: 0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad
    }

    function run() external returns (address proxyAddress, address adminAddress, address implementationAddress) {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        uint256 chainId = block.chainid;
        
        // Get the automation registry for current chain
        address automationRegistry = automationRegistries[chainId];
        require(automationRegistry != address(0), "Automation registry not configured for this chain");
        
        console.log("Deploying to chain ID:", chainId);
        console.log("Using Automation Registry:", automationRegistry);
        
        if (deployerPrivateKey == 0) {
            vm.startBroadcast();
        } else {
            vm.startBroadcast(deployerPrivateKey);
        }

        // 1. Deploy the implementation contract
        WorkflowManager implementation = new WorkflowManager();
        implementationAddress = address(implementation);
        console.log("Implementation deployed at:", implementationAddress);

        // 2. Deploy the ProxyAdmin, setting the sender as the owner
        ProxyAdmin admin = new ProxyAdmin(msg.sender);
        adminAddress = address(admin);
        console.log("ProxyAdmin deployed at:", adminAddress);

        // 3. Prepare the initialization data
        bytes memory data = abi.encodeWithSelector(
            WorkflowManager.initialize.selector,
            automationRegistry
        );

        // 4. Deploy the TransparentUpgradeableProxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementationAddress,
            adminAddress,
            data
        );
        proxyAddress = address(proxy);
        console.log("WorkflowManager proxy deployed at:", proxyAddress);
        
        // 5. Output deployment information
        console.log("====================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("====================================");
        console.log("Chain ID:", chainId);
        console.log("Implementation:", implementationAddress);
        console.log("ProxyAdmin:", adminAddress);
        console.log("Proxy (Main Contract):", proxyAddress);
        console.log("Automation Registry:", automationRegistry);
        console.log("Deployer:", msg.sender);
        console.log("====================================");
        
        // 6. Save deployment information to .env format
        console.log("Add these to your .env file:");
        console.log("WORKFLOW_MANAGER_CONTRACT_ADDRESS=", proxyAddress);
        console.log("WORKFLOW_MANAGER_PROXY_ADMIN=", adminAddress);
        console.log("WORKFLOW_MANAGER_IMPLEMENTATION=", implementationAddress);
        
        vm.stopBroadcast();
    }
    
    // Function to upgrade implementation (for future use)
    function upgradeImplementation(address proxyAddress, address newImplementation) external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        
        if (deployerPrivateKey == 0) {
            vm.startBroadcast();
        } else {
            vm.startBroadcast(deployerPrivateKey);
        }
        
        // Get the ProxyAdmin address (should be stored in .env)
        address proxyAdminAddress = vm.envAddress("WORKFLOW_MANAGER_PROXY_ADMIN");
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        
        // Upgrade the proxy to point to new implementation
        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(proxyAddress),
            newImplementation,
            ""
        );
        
        console.log("Proxy upgraded to new implementation:", newImplementation);
        
        vm.stopBroadcast();
    }
} 