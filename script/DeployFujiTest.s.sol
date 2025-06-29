// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {WorkflowManager} from "../src/WorkflowManager.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployFujiTest is Script {
    // Avalanche Fuji Testnet Configuration (Updated 2025)
    address constant FUJI_AUTOMATION_REGISTRY = 0x819B58A646CDd8289275A87653a2aA4902b14fe6; // Registry v2.3
    address constant FUJI_AUTOMATION_REGISTRAR = 0xD23D3D1b81711D75E1012211f1b65Cc7dBB474e2; // Registrar v2.3
    address constant FUJI_LINK_TOKEN = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address constant FUJI_AVAX_USD_PRICE_FEED = 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD; // Real ~$18 feed
    
    function run() external {
        console.log("========================================");
        console.log("   FUJI TESTNET DEPLOYMENT SCRIPT      ");
        console.log("   Chainlink Automation v2.3           ");
        console.log("========================================");
        
        vm.startBroadcast();
        
        address deployer = msg.sender;
        console.log("Deployer:", deployer);
        console.log("Deployer Balance:", deployer.balance / 1e18, "AVAX");
        console.log("Chain ID:", block.chainid);
        console.log("Expected Chain ID: 43113 (Fuji)");
        
        require(block.chainid == 43113, "Not Fuji testnet!");
        
        // 1. Deploy implementation contract
        console.log("\n1. Deploying WorkflowManager Implementation...");
        WorkflowManager implementation = new WorkflowManager();
        console.log("   Implementation deployed at:", address(implementation));
        
        // 2. Prepare initialization data
        console.log("\n2. Preparing initialization data...");
        bytes memory initData = abi.encodeWithSelector(
            WorkflowManager.initialize.selector,
            FUJI_AUTOMATION_REGISTRY, // Registry v2.3
            FUJI_AUTOMATION_REGISTRAR, // Registrar v2.3
            FUJI_LINK_TOKEN // LINK token address
        );
        
        // 3. Deploy proxy
        console.log("\n3. Deploying ERC1967 Proxy...");
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("   Proxy deployed at:", address(proxy));
        
        // 4. Verify deployment
        console.log("\n4. Verifying deployment...");
        WorkflowManager workflowManager = WorkflowManager(address(proxy));
        
        address owner = workflowManager.owner();
        address registry = address(workflowManager.s_automationRegistry());
        address registrar = address(workflowManager.s_automationRegistrar());
        address linkToken = address(workflowManager.s_linkToken());
        console.log("   Contract Owner:", owner);
        console.log("   Automation Registry:", registry);
        console.log("   Automation Registrar:", registrar);
        console.log("   LINK Token:", linkToken);
        console.log("   Version: v2.3 with Registrar Support");
        
        vm.stopBroadcast();
        
        // 5. Summary & MVP Test Info
        console.log("\n========================================");
        console.log("      FUJI DEPLOYMENT SUMMARY          ");
        console.log("========================================");
        console.log("Network: Avalanche Fuji Testnet");
        console.log("Chain ID:", block.chainid);
        console.log("Implementation:", address(implementation));
        console.log("Proxy (Main Contract):", address(proxy));
        console.log("Owner:", owner);
        console.log("Registry (v2.3):", registry);
        console.log("Registrar (v2.3):", registrar);
        console.log("LINK Token:", linkToken);
        
        console.log("\n========================================");
        console.log("      MVP TEST CONFIGURATION           ");
        console.log("========================================");
        console.log("LINK Token:", FUJI_LINK_TOKEN);
        console.log("AVAX/USD Price Feed:", FUJI_AVAX_USD_PRICE_FEED);
        console.log("Automation Registry:", FUJI_AUTOMATION_REGISTRY);
        console.log("Automation Registrar:", FUJI_AUTOMATION_REGISTRAR);
        
        console.log("\nUSEFUL LINKS:");
        console.log("Testnet Snowtrace:");
        console.log("   Implementation: https://testnet.snowtrace.io/address/", address(implementation));
        console.log("   Proxy: https://testnet.snowtrace.io/address/", address(proxy));
        console.log("   Chainlink Automation: https://automation.chain.link/fuji");
        console.log("   Faucets: https://faucets.chain.link/fuji");
        
        console.log("\nMVP WORKFLOW CONFIG:");
        console.log("Price Node: Monitor AVAX < $5.00");
        console.log("Worker Node: Execute when triggered");
        console.log("Swap Node: LINK -> AVAX on DEX");
        
        console.log("\nENV VARIABLES TO SET:");
        console.log("FUJI_IMPLEMENTATION_ADDRESS=", address(implementation));
        console.log("FUJI_PROXY_ADDRESS=", address(proxy));
        console.log("FUJI_AUTOMATION_REGISTRY=", FUJI_AUTOMATION_REGISTRY);
        console.log("FUJI_AUTOMATION_REGISTRAR=", FUJI_AUTOMATION_REGISTRAR);
        console.log("FUJI_LINK_TOKEN=", FUJI_LINK_TOKEN);
        console.log("FUJI_AVAX_USD_PRICE_FEED=", FUJI_AVAX_USD_PRICE_FEED);
    }
} 