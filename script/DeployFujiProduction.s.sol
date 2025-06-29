// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/WorkflowManager.sol";

/**
 * @title Deploy WorkflowManager v4 to Fuji Testnet (Production)
 * @notice Updated deployment with LINK token support
 */
contract DeployFujiProduction is Script {
    
    // Fuji Testnet addresses (Production)
    address constant FUJI_AUTOMATION_REGISTRY = 0x819B58A646CDd8289275A87653a2aA4902b14fe6;
    address constant FUJI_LINK_TOKEN = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    
    function run() external {
        string memory privateKeyString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        // Handle private key format
        if (bytes(privateKeyString).length == 64) {
            deployerPrivateKey = vm.parseUint(string(abi.encodePacked("0x", privateKeyString)));
        } else {
            deployerPrivateKey = vm.parseUint(privateKeyString);
        }
        
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("DEPLOYING WORKFLOWMANAGER V4 TO FUJI TESTNET");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Registry:", FUJI_AUTOMATION_REGISTRY);
        console.log("LINK Token:", FUJI_LINK_TOKEN);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy the implementation contract
        console.log("Deploying WorkflowManager Implementation v4...");
        WorkflowManager implementation = new WorkflowManager();
        console.log("Implementation Address:", address(implementation));
        
        // 2. Prepare initialization data with LINK token support
        bytes memory initData = abi.encodeWithSelector(
            WorkflowManager.initialize.selector,
            FUJI_AUTOMATION_REGISTRY,
            FUJI_LINK_TOKEN
        );
        
        // 3. Deploy the proxy contract
        console.log("Deploying UUPS Proxy...");
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("Proxy Address:", address(proxy));
        
        vm.stopBroadcast();
        
        // 4. Verify deployment
        console.log("DEPLOYMENT COMPLETE!");
        console.log("========================================");
        console.log("Contract Addresses:");
        console.log("   Implementation:", address(implementation));
        console.log("   Proxy (Use This):", address(proxy));
        console.log("   Owner:", deployer);
        
        console.log("Configuration:");
        console.log("   Automation Registry:", FUJI_AUTOMATION_REGISTRY);
        console.log("   LINK Token:", FUJI_LINK_TOKEN);
        console.log("   Network: Avalanche Fuji Testnet (43113)");
        
        console.log("Next Steps:");
        console.log("1. Fund proxy with LINK tokens");
        console.log("2. Test workflow registration");
        console.log("3. Update backend with new proxy address");
        
        // Save addresses for easy access
        string memory addressesJson = string(
            abi.encodePacked(
                "{\n",
                '  "implementation": "', vm.toString(address(implementation)), '",\n',
                '  "proxy": "', vm.toString(address(proxy)), '",\n',
                '  "owner": "', vm.toString(deployer), '",\n',
                '  "registry": "', vm.toString(FUJI_AUTOMATION_REGISTRY), '",\n',
                '  "linkToken": "', vm.toString(FUJI_LINK_TOKEN), '",\n',
                '  "network": "fuji",\n',
                '  "chainId": 43113\n',
                "}"
            )
        );
        
        vm.writeFile("deployment_addresses_v4.json", addressesJson);
        console.log("Addresses saved to: deployment_addresses_v4.json");
    }
} 