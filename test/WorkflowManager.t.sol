// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {WorkflowManager} from "../src/WorkflowManager.sol";
import {DeployWorkflowManager} from "../script/DeployWorkflowManager.s.sol";

contract WorkflowManagerTest is Test {
    WorkflowManager public workflowManager;
    address public owner;
    address public proxyAdmin;

    // This function is run before each test
    function setUp() public {
        DeployWorkflowManager deployer = new DeployWorkflowManager();
        (address proxyAddress, address adminAddress, address implementationAddress) = deployer.run();
        
        workflowManager = WorkflowManager(proxyAddress);
        proxyAdmin = adminAddress;
        owner = msg.sender;
    }

    // Test that the owner is set correctly during initialization
    function testOwnerIsSet() public {
        assertEq(workflowManager.owner(), owner);
    }

    // Test that a new workflow can be registered
    function testRegisterWorkflow() public {
        address mockTriggerSource = address(0x123);
        WorkflowManager.TriggerType triggerType = WorkflowManager.TriggerType.GREATER_THAN;
        int256 triggerTargetValue = 1000;
        bytes32 commitmentHash = keccak256("test_action");
        uint256 mockUpkeepId = 98765;

        // Mock the call to the Chainlink Registry
        // Get the address of the registry from the contract
        address registry = address(workflowManager.s_automationRegistry());
        // Prepare the expected calldata for the registerUpkeep function
        bytes memory expectedCalldata = abi.encodeWithSelector(
            workflowManager.s_automationRegistry().registerUpkeep.selector,
            address(workflowManager),
            3000000, // gasLimit
            owner, // admin
            bytes("") // checkData
        );
        // Tell the mock to return a specific upkeepId when called with that data
        vm.mockCall(registry, expectedCalldata, abi.encode(mockUpkeepId));

        // The 'owner' should be able to register a workflow
        vm.prank(owner);
        uint256 upkeepId = workflowManager.registerWorkflow(
            1, // workflowId
            mockTriggerSource,
            triggerType,
            triggerTargetValue,
            commitmentHash
        );

        // Check that a valid upkeepId is returned (the one from the mock)
        assertEq(upkeepId, mockUpkeepId);

        // Check if the workflow was actually stored
        // The public getter for a struct returns its fields individually.
        (uint256 storedWorkflowId, bool isActive, address storedTriggerSource, , ,) = workflowManager.s_workflows(upkeepId);
        
        assertEq(storedWorkflowId, 1);
        assertTrue(isActive);
        assertEq(storedTriggerSource, mockTriggerSource);
    }
} 