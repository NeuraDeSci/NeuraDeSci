// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title ResearchDataRegistry
 * @dev Registry for managing research data in the NeuraDeSci platform
 */
contract ResearchDataRegistry is AccessControl, Pausable {
    using Counters for Counters.Counter;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 public constant RESEARCHER_ROLE = keccak256("RESEARCHER_ROLE");
    
    Counters.Counter private _datasetIds;
    
    enum DatasetStatus { Pending, Approved, Rejected, Archived }
    enum DatasetAccessType { Public, Restricted, Private }
    
    struct Dataset {
        uint256 id;
        address owner;
        string title;
        string description;
        string ipfsHash;
        string[] keywords;
        DatasetStatus status;
        DatasetAccessType accessType;
        string[] accessControlList; // DID identifiers of entities with access
        uint256 timestamp;
        uint256 size; // in bytes
        string dataType; // e.g., "fMRI", "EEG", etc.
        string license;
        uint256 citationCount;
        mapping(address => bool) hasAccessed; // Track who has accessed
        mapping(uint256 => Contribution) contributions;
        uint256 contributionCount;
    }
    
    struct Contribution {
        address contributor;
        string contributionType; // e.g., "Data Collection", "Analysis", etc.
        uint256 timestamp;
        string details;
    }
    
    struct DatasetMetadata {
        uint256 id;
        address owner;
        string title;
        string description;
        string ipfsHash;
        string[] keywords;
        DatasetStatus status;
        DatasetAccessType accessType;
        uint256 timestamp;
        string dataType;
        string license;
        uint256 citationCount;
        uint256 contributionCount;
    }
    
    // Mapping from dataset ID to Dataset
    mapping(uint256 => Dataset) private _datasets;
    
    // Mapping from researcher address to their dataset IDs
    mapping(address => uint256[]) private _researcherDatasets;
    
    // Events
    event DatasetRegistered(uint256 indexed datasetId, address indexed owner, string ipfsHash);
    event DatasetStatusChanged(uint256 indexed datasetId, DatasetStatus newStatus);
    event DatasetAccessed(uint256 indexed datasetId, address indexed accessor);
    event ContributionAdded(uint256 indexed datasetId, address indexed contributor, string contributionType);
    event DatasetCited(uint256 indexed datasetId, address indexed citer);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    /**
     * @dev Register a new dataset
     */
    function registerDataset(
        string memory title,
        string memory description,
        string memory ipfsHash,
        string[] memory keywords,
        DatasetAccessType accessType,
        string[] memory accessControlList,
        uint256 size,
        string memory dataType,
        string memory license
    ) public whenNotPaused returns (uint256) {
        require(bytes(ipfsHash).length > 0, "IPFS hash is required");
        
        _datasetIds.increment();
        uint256 newDatasetId = _datasetIds.current();
        
        Dataset storage newDataset = _datasets[newDatasetId];
        newDataset.id = newDatasetId;
        newDataset.owner = msg.sender;
        newDataset.title = title;
        newDataset.description = description;
        newDataset.ipfsHash = ipfsHash;
        newDataset.keywords = keywords;
        newDataset.status = DatasetStatus.Pending;
        newDataset.accessType = accessType;
        newDataset.accessControlList = accessControlList;
        newDataset.timestamp = block.timestamp;
        newDataset.size = size;
        newDataset.dataType = dataType;
        newDataset.license = license;
        newDataset.citationCount = 0;
        newDataset.contributionCount = 0;
        
        _researcherDatasets[msg.sender].push(newDatasetId);
        
        // Add the owner as the first contributor
        _addContribution(newDatasetId, msg.sender, "Dataset Creation", "Initial dataset registration");
        
        // Grant researcher role if they don't have it yet
        if (!hasRole(RESEARCHER_ROLE, msg.sender)) {
            _grantRole(RESEARCHER_ROLE, msg.sender);
        }
        
        emit DatasetRegistered(newDatasetId, msg.sender, ipfsHash);
        
        return newDatasetId;
    }
    
    /**
     * @dev Update dataset status
     */
    function updateDatasetStatus(uint256 datasetId, DatasetStatus newStatus) 
        public 
        onlyRole(CURATOR_ROLE)
        whenNotPaused
    {
        require(_datasets[datasetId].id != 0, "Dataset does not exist");
        _datasets[datasetId].status = newStatus;
        
        emit DatasetStatusChanged(datasetId, newStatus);
    }
    
    /**
     * @dev Record dataset access
     */
    function accessDataset(uint256 datasetId) 
        public 
        whenNotPaused 
        returns (string memory)
    {
        require(_datasets[datasetId].id != 0, "Dataset does not exist");
        require(_datasets[datasetId].status == DatasetStatus.Approved, "Dataset not approved");
        
        // Access control check
        if (_datasets[datasetId].accessType == DatasetAccessType.Private) {
            require(msg.sender == _datasets[datasetId].owner, "No access to private dataset");
        } 
        else if (_datasets[datasetId].accessType == DatasetAccessType.Restricted) {
            bool hasAccess = false;
            if (msg.sender == _datasets[datasetId].owner) {
                hasAccess = true;
            } else {
                // Check if sender's DID is in the access control list
                // This is simplified - in a real implementation, you'd check DIDs
                string memory senderDID = addressToDID(msg.sender);
                for (uint i = 0; i < _datasets[datasetId].accessControlList.length; i++) {
                    if (keccak256(abi.encodePacked(_datasets[datasetId].accessControlList[i])) == 
                        keccak256(abi.encodePacked(senderDID))) {
                        hasAccess = true;
                        break;
                    }
                }
            }
            require(hasAccess, "No access to restricted dataset");
        }
        
        // Record access if not already recorded
        if (!_datasets[datasetId].hasAccessed[msg.sender]) {
            _datasets[datasetId].hasAccessed[msg.sender] = true;
        }
        
        emit DatasetAccessed(datasetId, msg.sender);
        
        // Return the IPFS hash for the client to fetch the data
        return _datasets[datasetId].ipfsHash;
    }
    
    /**
     * @dev Add a contribution to a dataset
     */
    function addContribution(
        uint256 datasetId, 
        string memory contributionType,
        string memory details
    ) 
        public 
        whenNotPaused 
    {
        require(_datasets[datasetId].id != 0, "Dataset does not exist");
        require(
            _datasets[datasetId].owner == msg.sender || 
            hasRole(CURATOR_ROLE, msg.sender),
            "Only owner or curator can add contributions"
        );
        
        _addContribution(datasetId, msg.sender, contributionType, details);
    }
    
    /**
     * @dev Internal function to add a contribution
     */
    function _addContribution(
        uint256 datasetId,
        address contributor,
        string memory contributionType,
        string memory details
    ) 
        internal 
    {
        uint256 contributionId = _datasets[datasetId].contributionCount;
        _datasets[datasetId].contributionCount++;
        
        Contribution storage newContribution = _datasets[datasetId].contributions[contributionId];
        newContribution.contributor = contributor;
        newContribution.contributionType = contributionType;
        newContribution.timestamp = block.timestamp;
        newContribution.details = details;
        
        emit ContributionAdded(datasetId, contributor, contributionType);
    }
    
    /**
     * @dev Cite a dataset
     */
    function citeDataset(uint256 datasetId) 
        public 
        whenNotPaused 
    {
        require(_datasets[datasetId].id != 0, "Dataset does not exist");
        require(_datasets[datasetId].status == DatasetStatus.Approved, "Dataset not approved");
        
        _datasets[datasetId].citationCount++;
        
        emit DatasetCited(datasetId, msg.sender);
    }
    
    /**
     * @dev Get dataset metadata
     */
    function getDatasetMetadata(uint256 datasetId) 
        public 
        view 
        returns (DatasetMetadata memory) 
    {
        require(_datasets[datasetId].id != 0, "Dataset does not exist");
        
        Dataset storage dataset = _datasets[datasetId];
        
        DatasetMetadata memory metadata = DatasetMetadata({
            id: dataset.id,
            owner: dataset.owner,
            title: dataset.title,
            description: dataset.description,
            ipfsHash: dataset.ipfsHash,
            keywords: dataset.keywords,
            status: dataset.status,
            accessType: dataset.accessType,
            timestamp: dataset.timestamp,
            dataType: dataset.dataType,
            license: dataset.license,
            citationCount: dataset.citationCount,
            contributionCount: dataset.contributionCount
        });
        
        return metadata;
    }
    
    /**
     * @dev Get a researcher's datasets
     */
    function getResearcherDatasets(address researcher) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return _researcherDatasets[researcher];
    }
    
    /**
     * @dev Get contribution details
     */
    function getContribution(uint256 datasetId, uint256 contributionId) 
        public 
        view 
        returns (address, string memory, uint256, string memory) 
    {
        require(_datasets[datasetId].id != 0, "Dataset does not exist");
        require(contributionId < _datasets[datasetId].contributionCount, "Contribution does not exist");
        
        Contribution storage contribution = _datasets[datasetId].contributions[contributionId];
        
        return (
            contribution.contributor,
            contribution.contributionType,
            contribution.timestamp,
            contribution.details
        );
    }
    
    /**
     * @dev Convert an address to a mock DID (for demo purposes)
     * In a real implementation, you would use a proper DID resolver
     */
    function addressToDID(address addr) 
        internal 
        pure 
        returns (string memory) 
    {
        return string(abi.encodePacked("did:ethr:", toHexString(addr)));
    }
    
    /**
     * @dev Convert an address to a hex string
     */
    function toHexString(address addr) 
        internal 
        pure 
        returns (string memory) 
    {
        bytes memory buffer = new bytes(42);
        buffer[0] = '0';
        buffer[1] = 'x';
        
        address curr = addr;
        for (uint256 i = 41; i > 1; --i) {
            buffer[i] = toHexChar(uint8(uint256(curr) & 0xf));
            curr = address(uint160(uint256(curr)) / 16);
        }
        
        return string(buffer);
    }
    
    /**
     * @dev Convert a byte to its ASCII hex character
     */
    function toHexChar(uint8 value) 
        internal 
        pure 
        returns (bytes1) 
    {
        if (value < 10) {
            return bytes1(uint8(bytes1('0')) + value);
        } else {
            return bytes1(uint8(bytes1('a')) + value - 10);
        }
    }
} 