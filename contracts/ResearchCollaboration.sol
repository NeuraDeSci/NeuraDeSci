// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IResearchDataRegistry {
    function getDatasetMetadata(uint256 datasetId) external view returns (
        uint256 id,
        address owner,
        string memory title,
        string memory description,
        string memory ipfsHash,
        string[] memory keywords,
        uint8 status,
        uint8 accessType,
        uint256 timestamp,
        string memory dataType,
        string memory license,
        uint256 citationCount,
        uint256 contributionCount
    );
}

/**
 * @title ResearchCollaboration
 * @dev Contract for managing research collaborations
 */
contract ResearchCollaboration is AccessControl, Pausable {
    using Counters for Counters.Counter;
    
    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SCIENTIFIC_COMMITTEE_ROLE = keccak256("SCIENTIFIC_COMMITTEE_ROLE");
    
    // Registry contract
    IResearchDataRegistry public dataRegistry;
    
    // Project counter
    Counters.Counter private _projectIds;
    
    // Project status
    enum ProjectStatus { 
        Draft, 
        Open, 
        InProgress, 
        UnderReview, 
        Completed, 
        Cancelled 
    }
    
    // Project visibility
    enum ProjectVisibility { 
        Public, 
        Limited, 
        Private 
    }
    
    // Project member role
    enum MemberRole { 
        PrincipalInvestigator, 
        CoInvestigator, 
        Researcher, 
        Contributor, 
        Reviewer 
    }
    
    // Project member
    struct ProjectMember {
        address memberAddress;
        MemberRole role;
        uint256 joinedAt;
        bool isActive;
    }
    
    // Project milestone
    struct Milestone {
        string title;
        string description;
        string ipfsHash; // For detailed content
        uint256 dueDate;
        bool isCompleted;
        uint256 completedAt;
        address completedBy;
    }
    
    // Research project
    struct Project {
        uint256 id;
        string title;
        string description;
        string ipfsHash; // For detailed project proposal
        ProjectStatus status;
        ProjectVisibility visibility;
        uint256 createdAt;
        uint256 updatedAt;
        uint256[] relatedDatasets;
        address[] memberAddresses;
        mapping(address => ProjectMember) members;
        mapping(uint256 => Milestone) milestones;
        uint256 milestoneCount;
        string[] disciplines; // e.g., "Neurology", "AI", etc.
        string[] keywords;
        string[] outputLinks; // Links to publications, etc.
    }
    
    // Project output
    struct ProjectOutput {
        uint256 projectId;
        string title;
        string description;
        string outputType; // e.g., "Publication", "Dataset", "Code", etc.
        string ipfsHash;
        string externalLink;
        uint256 publishedAt;
        address publishedBy;
    }
    
    // Mapping from project ID to Project
    mapping(uint256 => Project) private _projects;
    
    // Mapping from researcher address to their project IDs
    mapping(address => uint256[]) private _researcherProjects;
    
    // Project outputs
    mapping(uint256 => ProjectOutput[]) private _projectOutputs;
    
    // Project join requests
    struct JoinRequest {
        uint256 projectId;
        address requester;
        MemberRole proposedRole;
        string motivation;
        uint256 requestedAt;
        bool isProcessed;
        bool isAccepted;
        uint256 processedAt;
        address processedBy;
    }
    
    // Join request counter
    Counters.Counter private _joinRequestIds;
    
    // Mapping from request ID to JoinRequest
    mapping(uint256 => JoinRequest) private _joinRequests;
    
    // Mapping from project ID to join request IDs
    mapping(uint256 => uint256[]) private _projectJoinRequests;
    
    // Events
    event ProjectCreated(uint256 indexed projectId, address indexed creator, string title);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus status);
    event MemberAdded(uint256 indexed projectId, address indexed member, MemberRole role);
    event MemberRemoved(uint256 indexed projectId, address indexed member);
    event MilestoneAdded(uint256 indexed projectId, uint256 milestoneIndex, string title);
    event MilestoneCompleted(uint256 indexed projectId, uint256 milestoneIndex);
    event OutputAdded(uint256 indexed projectId, string title, string outputType);
    event JoinRequestCreated(uint256 indexed requestId, uint256 indexed projectId, address indexed requester);
    event JoinRequestProcessed(uint256 indexed requestId, bool accepted);
    
    constructor(address dataRegistryAddress) {
        require(dataRegistryAddress != address(0), "Invalid data registry address");
        dataRegistry = IResearchDataRegistry(dataRegistryAddress);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(SCIENTIFIC_COMMITTEE_ROLE, msg.sender);
    }
    
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    /**
     * @dev Create a new research project
     */
    function createProject(
        string memory title,
        string memory description,
        string memory ipfsHash,
        ProjectVisibility visibility,
        string[] memory disciplines,
        string[] memory keywords,
        uint256[] memory relatedDatasets
    ) public whenNotPaused returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        
        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();
        
        Project storage newProject = _projects[newProjectId];
        newProject.id = newProjectId;
        newProject.title = title;
        newProject.description = description;
        newProject.ipfsHash = ipfsHash;
        newProject.status = ProjectStatus.Draft;
        newProject.visibility = visibility;
        newProject.createdAt = block.timestamp;
        newProject.updatedAt = block.timestamp;
        newProject.relatedDatasets = relatedDatasets;
        newProject.disciplines = disciplines;
        newProject.keywords = keywords;
        newProject.milestoneCount = 0;
        
        // Add creator as principal investigator
        _addMember(newProjectId, msg.sender, MemberRole.PrincipalInvestigator);
        
        _researcherProjects[msg.sender].push(newProjectId);
        
        emit ProjectCreated(newProjectId, msg.sender, title);
        
        return newProjectId;
    }
    
    /**
     * @dev Add a member to a project
     */
    function _addMember(uint256 projectId, address memberAddress, MemberRole role) internal {
        Project storage project = _projects[projectId];
        
        require(!project.members[memberAddress].isActive, "Already a member");
        
        project.memberAddresses.push(memberAddress);
        
        ProjectMember storage newMember = project.members[memberAddress];
        newMember.memberAddress = memberAddress;
        newMember.role = role;
        newMember.joinedAt = block.timestamp;
        newMember.isActive = true;
        
        emit MemberAdded(projectId, memberAddress, role);
    }
    
    /**
     * @dev Update project status
     */
    function updateProjectStatus(uint256 projectId, ProjectStatus newStatus) public whenNotPaused {
        require(_projects[projectId].id != 0, "Project does not exist");
        require(_isMemberWithRole(projectId, msg.sender, MemberRole.PrincipalInvestigator) || 
                hasRole(SCIENTIFIC_COMMITTEE_ROLE, msg.sender), 
                "Not authorized");
        
        _projects[projectId].status = newStatus;
        _projects[projectId].updatedAt = block.timestamp;
        
        emit ProjectStatusChanged(projectId, newStatus);
    }
    
    /**
     * @dev Add a milestone to a project
     */
    function addMilestone(
        uint256 projectId,
        string memory title,
        string memory description,
        string memory ipfsHash,
        uint256 dueDate
    ) public whenNotPaused {
        require(_projects[projectId].id != 0, "Project does not exist");
        require(_isMemberWithRole(projectId, msg.sender, MemberRole.PrincipalInvestigator) || 
                _isMemberWithRole(projectId, msg.sender, MemberRole.CoInvestigator), 
                "Not authorized");
        
        Project storage project = _projects[projectId];
        uint256 milestoneIndex = project.milestoneCount;
        project.milestoneCount++;
        
        Milestone storage newMilestone = project.milestones[milestoneIndex];
        newMilestone.title = title;
        newMilestone.description = description;
        newMilestone.ipfsHash = ipfsHash;
        newMilestone.dueDate = dueDate;
        newMilestone.isCompleted = false;
        
        project.updatedAt = block.timestamp;
        
        emit MilestoneAdded(projectId, milestoneIndex, title);
    }
    
    /**
     * @dev Complete a milestone
     */
    function completeMilestone(uint256 projectId, uint256 milestoneIndex) public whenNotPaused {
        require(_projects[projectId].id != 0, "Project does not exist");
        require(_projects[projectId].milestoneCount > milestoneIndex, "Milestone does not exist");
        require(_isMemberWithRole(projectId, msg.sender, MemberRole.PrincipalInvestigator) || 
                _isMemberWithRole(projectId, msg.sender, MemberRole.CoInvestigator), 
                "Not authorized");
        
        Project storage project = _projects[projectId];
        Milestone storage milestone = project.milestones[milestoneIndex];
        
        require(!milestone.isCompleted, "Milestone already completed");
        
        milestone.isCompleted = true;
        milestone.completedAt = block.timestamp;
        milestone.completedBy = msg.sender;
        
        project.updatedAt = block.timestamp;
        
        emit MilestoneCompleted(projectId, milestoneIndex);
    }
    
    /**
     * @dev Add an output to a project
     */
    function addOutput(
        uint256 projectId,
        string memory title,
        string memory description,
        string memory outputType,
        string memory ipfsHash,
        string memory externalLink
    ) public whenNotPaused {
        require(_projects[projectId].id != 0, "Project does not exist");
        require(_isMember(projectId, msg.sender), "Not a project member");
        
        ProjectOutput memory newOutput = ProjectOutput({
            projectId: projectId,
            title: title,
            description: description,
            outputType: outputType,
            ipfsHash: ipfsHash,
            externalLink: externalLink,
            publishedAt: block.timestamp,
            publishedBy: msg.sender
        });
        
        _projectOutputs[projectId].push(newOutput);
        
        _projects[projectId].outputLinks.push(ipfsHash);
        _projects[projectId].updatedAt = block.timestamp;
        
        emit OutputAdded(projectId, title, outputType);
    }
    
    /**
     * @dev Create a request to join a project
     */
    function requestToJoin(
        uint256 projectId,
        MemberRole proposedRole,
        string memory motivation
    ) public whenNotPaused returns (uint256) {
        require(_projects[projectId].id != 0, "Project does not exist");
        require(_projects[projectId].status == ProjectStatus.Open, "Project not open for joining");
        require(!_isMember(projectId, msg.sender), "Already a member");
        
        _joinRequestIds.increment();
        uint256 newRequestId = _joinRequestIds.current();
        
        JoinRequest storage newRequest = _joinRequests[newRequestId];
        newRequest.projectId = projectId;
        newRequest.requester = msg.sender;
        newRequest.proposedRole = proposedRole;
        newRequest.motivation = motivation;
        newRequest.requestedAt = block.timestamp;
        newRequest.isProcessed = false;
        
        _projectJoinRequests[projectId].push(newRequestId);
        
        emit JoinRequestCreated(newRequestId, projectId, msg.sender);
        
        return newRequestId;
    }
    
    /**
     * @dev Process a join request
     */
    function processJoinRequest(uint256 requestId, bool accept) public whenNotPaused {
        require(_joinRequests[requestId].projectId != 0, "Request does not exist");
        require(!_joinRequests[requestId].isProcessed, "Request already processed");
        
        JoinRequest storage request = _joinRequests[requestId];
        uint256 projectId = request.projectId;
        
        require(_isMemberWithRole(projectId, msg.sender, MemberRole.PrincipalInvestigator), "Not authorized");
        
        request.isProcessed = true;
        request.isAccepted = accept;
        request.processedAt = block.timestamp;
        request.processedBy = msg.sender;
        
        if (accept) {
            _addMember(projectId, request.requester, request.proposedRole);
            _researcherProjects[request.requester].push(projectId);
        }
        
        emit JoinRequestProcessed(requestId, accept);
    }
    
    /**
     * @dev Remove a member from a project
     */
    function removeMember(uint256 projectId, address memberAddress) public whenNotPaused {
        require(_projects[projectId].id != 0, "Project does not exist");
        require(_isMemberWithRole(projectId, msg.sender, MemberRole.PrincipalInvestigator) || 
                hasRole(ADMIN_ROLE, msg.sender), 
                "Not authorized");
        require(_isMember(projectId, memberAddress), "Not a member");
        require(memberAddress != msg.sender, "Cannot remove yourself");
        
        Project storage project = _projects[projectId];
        project.members[memberAddress].isActive = false;
        project.updatedAt = block.timestamp;
        
        emit MemberRemoved(projectId, memberAddress);
    }
    
    /**
     * @dev Check if an address is a member of a project
     */
    function _isMember(uint256 projectId, address addr) internal view returns (bool) {
        return _projects[projectId].members[addr].isActive;
    }
    
    /**
     * @dev Check if an address is a member with a specific role
     */
    function _isMemberWithRole(uint256 projectId, address addr, MemberRole role) internal view returns (bool) {
        return _projects[projectId].members[addr].isActive && 
               _projects[projectId].members[addr].role == role;
    }
    
    /**
     * @dev Get project details
     */
    function getProjectDetails(uint256 projectId) public view returns (
        uint256 id,
        string memory title,
        string memory description,
        ProjectStatus status,
        ProjectVisibility visibility,
        uint256 createdAt,
        uint256 updatedAt,
        uint256 memberCount,
        uint256 milestoneCount,
        uint256 outputCount
    ) {
        require(_projects[projectId].id != 0, "Project does not exist");
        
        Project storage project = _projects[projectId];
        
        return (
            project.id,
            project.title,
            project.description,
            project.status,
            project.visibility,
            project.createdAt,
            project.updatedAt,
            project.memberAddresses.length,
            project.milestoneCount,
            _projectOutputs[projectId].length
        );
    }
    
    /**
     * @dev Get project members
     */
    function getProjectMembers(uint256 projectId) public view returns (address[] memory) {
        require(_projects[projectId].id != 0, "Project does not exist");
        
        return _projects[projectId].memberAddresses;
    }
    
    /**
     * @dev Get member details
     */
    function getMemberDetails(uint256 projectId, address memberAddress) public view returns (
        address addr,
        MemberRole role,
        uint256 joinedAt,
        bool isActive
    ) {
        require(_projects[projectId].id != 0, "Project does not exist");
        
        ProjectMember storage member = _projects[projectId].members[memberAddress];
        
        return (
            member.memberAddress,
            member.role,
            member.joinedAt,
            member.isActive
        );
    }
    
    /**
     * @dev Get milestone details
     */
    function getMilestoneDetails(uint256 projectId, uint256 milestoneIndex) public view returns (
        string memory title,
        string memory description,
        uint256 dueDate,
        bool isCompleted,
        uint256 completedAt,
        address completedBy
    ) {
        require(_projects[projectId].id != 0, "Project does not exist");
        require(_projects[projectId].milestoneCount > milestoneIndex, "Milestone does not exist");
        
        Milestone storage milestone = _projects[projectId].milestones[milestoneIndex];
        
        return (
            milestone.title,
            milestone.description,
            milestone.dueDate,
            milestone.isCompleted,
            milestone.completedAt,
            milestone.completedBy
        );
    }
    
    /**
     * @dev Get project outputs
     */
    function getProjectOutputs(uint256 projectId) public view returns (ProjectOutput[] memory) {
        require(_projects[projectId].id != 0, "Project does not exist");
        
        return _projectOutputs[projectId];
    }
    
    /**
     * @dev Get projects for a researcher
     */
    function getResearcherProjects(address researcher) public view returns (uint256[] memory) {
        return _researcherProjects[researcher];
    }
    
    /**
     * @dev Get join requests for a project
     */
    function getProjectJoinRequests(uint256 projectId) public view returns (uint256[] memory) {
        require(_projects[projectId].id != 0, "Project does not exist");
        require(_isMemberWithRole(projectId, msg.sender, MemberRole.PrincipalInvestigator) || 
                _isMemberWithRole(projectId, msg.sender, MemberRole.CoInvestigator), 
                "Not authorized");
        
        return _projectJoinRequests[projectId];
    }
    
    /**
     * @dev Get join request details
     */
    function getJoinRequestDetails(uint256 requestId) public view returns (
        uint256 projectId,
        address requester,
        MemberRole proposedRole,
        string memory motivation,
        uint256 requestedAt,
        bool isProcessed,
        bool isAccepted,
        uint256 processedAt,
        address processedBy
    ) {
        require(_joinRequests[requestId].projectId != 0, "Request does not exist");
        
        JoinRequest storage request = _joinRequests[requestId];
        
        return (
            request.projectId,
            request.requester,
            request.proposedRole,
            request.motivation,
            request.requestedAt,
            request.isProcessed,
            request.isAccepted,
            request.processedAt,
            request.processedBy
        );
    }
} 