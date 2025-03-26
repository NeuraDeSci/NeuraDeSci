// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface INDSToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @title NeuroScienceDAO
 * @dev Governance contract for NeuraDeSci platform
 */
contract NeuroScienceDAO is AccessControl, Pausable {
    using Counters for Counters.Counter;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CORE_TEAM_ROLE = keccak256("CORE_TEAM_ROLE");
    
    // Token contract
    INDSToken public ndsToken;
    
    // Proposal counter
    Counters.Counter private _proposalIds;
    
    // Voting parameters
    uint256 public votingPeriod = 7 days;
    uint256 public executionDelay = 2 days;
    uint256 public quorumThreshold = 100000 * 10**18; // 100,000 NDS tokens
    uint256 public approvalThreshold = 51; // 51% majority
    
    // Vote types
    enum VoteType { Against, For, Abstain }
    
    // Proposal types
    enum ProposalType { 
        GeneralGovernance, 
        FundingAllocation, 
        ProtocolUpgrade, 
        GrantApproval,
        ResearchPriority,
        MembershipChange
    }
    
    // Proposal status
    enum ProposalStatus { 
        Active, 
        Canceled, 
        Defeated, 
        Succeeded, 
        Queued, 
        Expired, 
        Executed 
    }
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsHash; // For detailed proposal content
        uint256 startTime;
        uint256 endTime;
        ProposalType proposalType;
        ProposalStatus status;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
        mapping(address => VoteType) voteType;
        address[] voters;
        bytes callData; // For on-chain actions
        address targetContract; // For on-chain actions
        uint256 executionTime;
    }
    
    // Mapping from proposal id to Proposal
    mapping(uint256 => Proposal) private _proposals;
    
    // DAO Treasury
    uint256 public treasuryBalance;
    
    // Research grant tracking
    struct Grant {
        uint256 id;
        address recipient;
        uint256 amount;
        string title;
        string description;
        uint256 approvalTime;
        uint256 expirationTime;
        bool claimed;
    }
    
    // Grant counter
    Counters.Counter private _grantIds;
    
    // Mapping from grant id to Grant
    mapping(uint256 => Grant) private _grants;
    
    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title);
    event VoteCast(uint256 indexed proposalId, address indexed voter, VoteType voteType, uint256 weight);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus status);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsDeposited(address indexed from, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event GrantCreated(uint256 indexed grantId, address indexed recipient, uint256 amount);
    event GrantClaimed(uint256 indexed grantId, address indexed recipient, uint256 amount);
    
    constructor(address ndsTokenAddress) {
        require(ndsTokenAddress != address(0), "Invalid token address");
        ndsToken = INDSToken(ndsTokenAddress);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(CORE_TEAM_ROLE, msg.sender);
    }
    
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    /**
     * @dev Create a new proposal
     */
    function createProposal(
        string memory title,
        string memory description,
        string memory ipfsHash,
        ProposalType proposalType,
        bytes memory callData,
        address targetContract
    ) public whenNotPaused returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(ndsToken.balanceOf(msg.sender) >= 1000 * 10**18, "Insufficient tokens to create proposal");
        
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();
        
        Proposal storage newProposal = _proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.title = title;
        newProposal.description = description;
        newProposal.ipfsHash = ipfsHash;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingPeriod;
        newProposal.proposalType = proposalType;
        newProposal.status = ProposalStatus.Active;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.abstainVotes = 0;
        newProposal.callData = callData;
        newProposal.targetContract = targetContract;
        
        emit ProposalCreated(newProposalId, msg.sender, title);
        
        return newProposalId;
    }
    
    /**
     * @dev Cast a vote on a proposal
     */
    function castVote(uint256 proposalId, VoteType vote) public whenNotPaused {
        require(_proposals[proposalId].id != 0, "Proposal does not exist");
        require(_proposals[proposalId].status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp < _proposals[proposalId].endTime, "Voting period has ended");
        require(!_proposals[proposalId].hasVoted[msg.sender], "Already voted");
        
        uint256 weight = ndsToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");
        
        Proposal storage proposal = _proposals[proposalId];
        
        if (vote == VoteType.For) {
            proposal.forVotes += weight;
        } else if (vote == VoteType.Against) {
            proposal.againstVotes += weight;
        } else {
            proposal.abstainVotes += weight;
        }
        
        proposal.hasVoted[msg.sender] = true;
        proposal.voteType[msg.sender] = vote;
        proposal.voters.push(msg.sender);
        
        emit VoteCast(proposalId, msg.sender, vote, weight);
    }
    
    /**
     * @dev Finalize a proposal after voting period ends
     */
    function finalizeProposal(uint256 proposalId) public whenNotPaused {
        require(_proposals[proposalId].id != 0, "Proposal does not exist");
        require(_proposals[proposalId].status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp >= _proposals[proposalId].endTime, "Voting period not ended");
        
        Proposal storage proposal = _proposals[proposalId];
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        
        if (totalVotes < quorumThreshold) {
            proposal.status = ProposalStatus.Defeated;
            emit ProposalStatusChanged(proposalId, ProposalStatus.Defeated);
            return;
        }
        
        uint256 approvalPercentage = (proposal.forVotes * 100) / (proposal.forVotes + proposal.againstVotes);
        
        if (approvalPercentage >= approvalThreshold) {
            proposal.status = ProposalStatus.Succeeded;
            proposal.executionTime = block.timestamp + executionDelay;
            emit ProposalStatusChanged(proposalId, ProposalStatus.Succeeded);
        } else {
            proposal.status = ProposalStatus.Defeated;
            emit ProposalStatusChanged(proposalId, ProposalStatus.Defeated);
        }
    }
    
    /**
     * @dev Execute a successful proposal
     */
    function executeProposal(uint256 proposalId) public whenNotPaused {
        require(_proposals[proposalId].id != 0, "Proposal does not exist");
        require(_proposals[proposalId].status == ProposalStatus.Succeeded, "Proposal not successful");
        require(block.timestamp >= _proposals[proposalId].executionTime, "Execution delay not passed");
        
        Proposal storage proposal = _proposals[proposalId];
        
        // If there is calldata and a target contract, execute the call
        if (proposal.targetContract != address(0) && proposal.callData.length > 0) {
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "Proposal execution failed");
        }
        
        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(proposalId);
        emit ProposalStatusChanged(proposalId, ProposalStatus.Executed);
    }
    
    /**
     * @dev Cancel a proposal (only proposer or admin)
     */
    function cancelProposal(uint256 proposalId) public whenNotPaused {
        require(_proposals[proposalId].id != 0, "Proposal does not exist");
        require(_proposals[proposalId].status == ProposalStatus.Active, "Proposal is not active");
        require(
            _proposals[proposalId].proposer == msg.sender || hasRole(ADMIN_ROLE, msg.sender),
            "Only proposer or admin can cancel"
        );
        
        _proposals[proposalId].status = ProposalStatus.Canceled;
        emit ProposalStatusChanged(proposalId, ProposalStatus.Canceled);
    }
    
    /**
     * @dev Deposit funds to the DAO treasury
     */
    function depositFunds(uint256 amount) public whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(ndsToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        treasuryBalance += amount;
        emit FundsDeposited(msg.sender, amount);
    }
    
    /**
     * @dev Withdraw funds from the DAO treasury (only through governance)
     */
    function withdrawFunds(address to, uint256 amount) public onlyRole(ADMIN_ROLE) whenNotPaused {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= treasuryBalance, "Insufficient treasury balance");
        
        treasuryBalance -= amount;
        require(ndsToken.transfer(to, amount), "Transfer failed");
        
        emit FundsWithdrawn(to, amount);
    }
    
    /**
     * @dev Create a research grant (approved through governance)
     */
    function createGrant(
        address recipient,
        uint256 amount,
        string memory title,
        string memory description,
        uint256 durationDays
    ) public onlyRole(ADMIN_ROLE) whenNotPaused {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= treasuryBalance, "Insufficient treasury balance");
        
        _grantIds.increment();
        uint256 newGrantId = _grantIds.current();
        
        Grant storage newGrant = _grants[newGrantId];
        newGrant.id = newGrantId;
        newGrant.recipient = recipient;
        newGrant.amount = amount;
        newGrant.title = title;
        newGrant.description = description;
        newGrant.approvalTime = block.timestamp;
        newGrant.expirationTime = block.timestamp + (durationDays * 1 days);
        newGrant.claimed = false;
        
        emit GrantCreated(newGrantId, recipient, amount);
    }
    
    /**
     * @dev Claim a research grant
     */
    function claimGrant(uint256 grantId) public whenNotPaused {
        require(_grants[grantId].id != 0, "Grant does not exist");
        require(_grants[grantId].recipient == msg.sender, "Not the grant recipient");
        require(!_grants[grantId].claimed, "Grant already claimed");
        require(block.timestamp <= _grants[grantId].expirationTime, "Grant expired");
        
        Grant storage grant = _grants[grantId];
        uint256 amount = grant.amount;
        
        require(amount <= treasuryBalance, "Insufficient treasury balance");
        
        treasuryBalance -= amount;
        grant.claimed = true;
        
        require(ndsToken.transfer(msg.sender, amount), "Transfer failed");
        
        emit GrantClaimed(grantId, msg.sender, amount);
    }
    
    /**
     * @dev Get proposal details
     */
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory description,
        uint256 startTime,
        uint256 endTime,
        ProposalType proposalType,
        ProposalStatus status,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes,
        uint256 voterCount,
        uint256 executionTime
    ) {
        require(_proposals[proposalId].id != 0, "Proposal does not exist");
        
        Proposal storage proposal = _proposals[proposalId];
        
        return (
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.startTime,
            proposal.endTime,
            proposal.proposalType,
            proposal.status,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.abstainVotes,
            proposal.voters.length,
            proposal.executionTime
        );
    }
    
    /**
     * @dev Get grant details
     */
    function getGrantDetails(uint256 grantId) public view returns (
        uint256 id,
        address recipient,
        uint256 amount,
        string memory title,
        string memory description,
        uint256 approvalTime,
        uint256 expirationTime,
        bool claimed
    ) {
        require(_grants[grantId].id != 0, "Grant does not exist");
        
        Grant storage grant = _grants[grantId];
        
        return (
            grant.id,
            grant.recipient,
            grant.amount,
            grant.title,
            grant.description,
            grant.approvalTime,
            grant.expirationTime,
            grant.claimed
        );
    }
    
    /**
     * @dev Check if an address has voted on a proposal
     */
    function hasVoted(uint256 proposalId, address voter) public view returns (bool) {
        require(_proposals[proposalId].id != 0, "Proposal does not exist");
        return _proposals[proposalId].hasVoted[voter];
    }
    
    /**
     * @dev Get the vote type of an address on a proposal
     */
    function getVoteType(uint256 proposalId, address voter) public view returns (VoteType) {
        require(_proposals[proposalId].id != 0, "Proposal does not exist");
        require(_proposals[proposalId].hasVoted[voter], "Address has not voted");
        return _proposals[proposalId].voteType[voter];
    }
    
    /**
     * @dev Update governance parameters (only through governance)
     */
    function updateGovernanceParams(
        uint256 newVotingPeriod,
        uint256 newExecutionDelay,
        uint256 newQuorumThreshold,
        uint256 newApprovalThreshold
    ) public onlyRole(ADMIN_ROLE) whenNotPaused {
        require(newVotingPeriod > 0, "Voting period must be greater than 0");
        require(newApprovalThreshold > 0 && newApprovalThreshold <= 100, "Invalid approval threshold");
        
        votingPeriod = newVotingPeriod;
        executionDelay = newExecutionDelay;
        quorumThreshold = newQuorumThreshold;
        approvalThreshold = newApprovalThreshold;
    }
} 