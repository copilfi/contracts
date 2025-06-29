// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// All imports now point to the upgradeable versions where applicable
import "chainlink/src/v0.8/automation/AutomationCompatible.sol";
import "chainlink/src/v0.8/data-feeds/interfaces/IDecimalAggregator.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "chainlink/src/v0.8/automation/interfaces/v2_3/IAutomationRegistryMaster2_3.sol";
import "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// AutomationRegistrar v2.3 Interface for programmatic upkeep registration
interface AutomationRegistrarInterface {
    struct RegistrationParams {
        string name;
        bytes encryptedEmail;
        address upkeepContract;
        uint32 gasLimit;
        address adminAddress;
        uint8 triggerType;
        bytes checkData;
        bytes triggerConfig;
        bytes offchainConfig;
        uint96 amount;
    }
    
    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

/**
 * @title WorkflowManager v4 (Upgradeable with LINK Support)
 * @author Copil Team
 * @notice This contract is now upgradeable using the UUPS proxy pattern with LINK token support.
 */
contract WorkflowManager is Initializable, AutomationCompatibleInterface, OwnableUpgradeable, UUPSUpgradeable {
    enum TriggerType { GREATER_THAN, LESS_THAN }

    struct Workflow {
        uint256 workflowId;      // ID from our backend DB
        bool isActive;           // Flag to pause/resume the workflow
        address triggerSource;   // Address of the on-chain data source (e.g., a Chainlink Price Feed)
        TriggerType triggerType; // The condition to check (e.g., price is > or < target)
        int256 triggerTargetValue; // The target value for the trigger (e.g., 100000 * 10**8 for a price feed)
        bytes32 commitmentHash;  // keccak256 hash of the off-chain action payload, ensuring integrity
    }

    mapping(uint256 => Workflow) public s_workflows; // upkeepId => Workflow
    IAutomationRegistryMaster2_3 public s_automationRegistry;
    AutomationRegistrarInterface public s_automationRegistrar;
    IERC20 public s_linkToken;

    event WorkflowRegistered(uint256 indexed upkeepId, uint256 indexed workflowId, bytes32 commitmentHash);
    event ActionRequired(uint256 indexed upkeepId, bytes32 indexed commitmentHash);
    event WorkflowPaused(uint256 indexed upkeepId);
    event WorkflowResumed(uint256 indexed upkeepId);
    event LinkApproved(address indexed spender, uint256 amount);
    
    error OnlyAutomationRegistry(address caller);
    error WorkflowNotActive(uint256 upkeepId);
    error InvalidTriggerSource(address source);
    error InsufficientLinkBalance(uint256 required, uint256 available);
    error LinkApprovalFailed();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address registryAddress, address registrarAddress, address linkTokenAddress) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        s_automationRegistry = IAutomationRegistryMaster2_3(payable(registryAddress));
        s_automationRegistrar = AutomationRegistrarInterface(registrarAddress);
        s_linkToken = IERC20(linkTokenAddress);
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Approve LINK tokens to the automation registrar
     * @param amount Amount of LINK tokens to approve
     */
    function approveLinkToRegistrar(uint256 amount) external onlyOwner {
        bool success = s_linkToken.approve(address(s_automationRegistrar), amount);
        if (!success) {
            revert LinkApprovalFailed();
        }
        emit LinkApproved(address(s_automationRegistrar), amount);
    }
    
    /**
     * @notice LEGACY: Approve LINK tokens to the automation registry
     * @param amount Amount of LINK tokens to approve
     */
    function approveLinkToRegistry(uint256 amount) external onlyOwner {
        bool success = s_linkToken.approve(address(s_automationRegistry), amount);
        if (!success) {
            revert LinkApprovalFailed();
        }
        emit LinkApproved(address(s_automationRegistry), amount);
    }

    /**
     * @notice Get current LINK balance of this contract
     */
    function getLinkBalance() external view returns (uint256) {
        return s_linkToken.balanceOf(address(this));
    }

    /**
     * @notice Get current LINK allowance to automation registry (LEGACY)
     */
    function getLinkAllowance() external view returns (uint256) {
        return s_linkToken.allowance(address(this), address(s_automationRegistry));
    }
    
    /**
     * @notice Get current LINK allowance to automation registrar
     */
    function getLinkAllowanceRegistrar() external view returns (uint256) {
        return s_linkToken.allowance(address(this), address(s_automationRegistrar));
    }

    function registerWorkflow(
        uint256 workflowId,
        address triggerSource,
        TriggerType triggerType,
        int256 triggerTargetValue,
        bytes32 commitmentHash
    ) external onlyOwner returns (uint256 upkeepId) {
        
        // Check LINK balance
        uint256 linkBalance = s_linkToken.balanceOf(address(this));
        uint256 requiredLink = 5 * 10**18; // 5 LINK minimum
        
        if (linkBalance < requiredLink) {
            revert InsufficientLinkBalance(requiredLink, linkBalance);
        }

        // Approve LINK tokens to the registrar for upkeep funding
        uint256 currentAllowance = s_linkToken.allowance(address(this), address(s_automationRegistrar));
        if (currentAllowance < requiredLink) {
            bool success = s_linkToken.approve(address(s_automationRegistrar), requiredLink * 2);
            if (!success) {
                revert LinkApprovalFailed();
            }
        }
        
        // Create registration parameters for the upkeep
        AutomationRegistrarInterface.RegistrationParams memory registrationParams = AutomationRegistrarInterface.RegistrationParams({
            name: string(abi.encodePacked("Copil Workflow #", uint2str(workflowId))),
            encryptedEmail: bytes(""), // Empty for programmatic registration
            upkeepContract: address(this), // This contract handles checkUpkeep and performUpkeep
            gasLimit: 500000, // Reasonable default gas limit
            adminAddress: owner(), // Contract owner will be the upkeep admin
            triggerType: 0, // 0 = Conditional upkeep (custom logic based)
            checkData: abi.encode(workflowId), // Workflow ID passed to checkUpkeep function
            triggerConfig: bytes(""), // Empty for conditional upkeeps
            offchainConfig: bytes(""), // Empty (used for gas price thresholds etc.)
            amount: uint96(requiredLink) // LINK funding amount for the upkeep
        });

        // Register the upkeep through the Chainlink Automation Registrar
        upkeepId = s_automationRegistrar.registerUpkeep(registrationParams);

        // Store workflow data in contract mapping
        s_workflows[upkeepId] = Workflow({
            workflowId: workflowId,
            isActive: true,
            triggerSource: triggerSource,
            triggerType: triggerType,
            triggerTargetValue: triggerTargetValue,
            commitmentHash: commitmentHash
        });

        emit WorkflowRegistered(upkeepId, workflowId, commitmentHash);
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint256 upkeepId = abi.decode(checkData, (uint256));
        Workflow memory workflow = s_workflows[upkeepId];
        
        if (!workflow.isActive) {
            upkeepNeeded = false;
        } else {
            IDecimalAggregator priceFeed = IDecimalAggregator(workflow.triggerSource);
            (, int256 currentPrice, , , ) = priceFeed.latestRoundData();

            if (workflow.triggerType == TriggerType.GREATER_THAN) {
                upkeepNeeded = currentPrice > workflow.triggerTargetValue;
            } else if (workflow.triggerType == TriggerType.LESS_THAN) {
                upkeepNeeded = currentPrice < workflow.triggerTargetValue;
            } else {
                upkeepNeeded = false;
            }
        }

        performData = abi.encode(upkeepId);
    }

    function performUpkeep(bytes calldata performData) external override {
        if (msg.sender != address(s_automationRegistry)) {
            revert OnlyAutomationRegistry(msg.sender);
        }

        uint256 upkeepId = abi.decode(performData, (uint256));
        Workflow storage workflow = s_workflows[upkeepId];
        
        // Deactivate the workflow to prevent it from re-triggering immediately.
        // The backend can re-activate it if it's a recurring task.
        workflow.isActive = false;

        emit ActionRequired(upkeepId, workflow.commitmentHash);
    }

    // --- Management Functions ---

    function pauseWorkflow(uint256 upkeepId) external onlyOwner {
        s_workflows[upkeepId].isActive = false;
        emit WorkflowPaused(upkeepId);
    }

    function resumeWorkflow(uint256 upkeepId) external onlyOwner {
        s_workflows[upkeepId].isActive = true;
        emit WorkflowResumed(upkeepId);
    }

    /**
     * @notice Emergency function to withdraw LINK tokens
     */
    function withdrawLink(uint256 amount) external onlyOwner {
        require(s_linkToken.transfer(owner(), amount), "LINK transfer failed");
    }

    /**
     * @notice Get workflow status and details
     */
    function getWorkflowStatus(uint256 upkeepId) external view returns (
        uint256 workflowId,
        bool isActive,
        address triggerSource,
        uint8 triggerType,
        int256 triggerTargetValue,
        bytes32 commitmentHash
    ) {
        Workflow memory workflow = s_workflows[upkeepId];
        return (
            workflow.workflowId,
            workflow.isActive,
            workflow.triggerSource,
            uint8(workflow.triggerType),
            workflow.triggerTargetValue,
            workflow.commitmentHash
        );
    }

    /**
     * @dev Helper function to convert uint to string for upkeep name generation
     */
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
} 