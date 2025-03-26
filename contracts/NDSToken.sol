// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title NDSToken
 * @dev The main token of the NeuraDeSci ecosystem
 */
contract NDSToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    uint256 public constant MAX_SUPPLY = 100_000_000 * 10**18; // 100 million tokens
    
    // Token distribution
    uint256 public constant RESEARCH_ALLOCATION = 40_000_000 * 10**18; // 40% for research grants
    uint256 public constant ECOSYSTEM_ALLOCATION = 25_000_000 * 10**18; // 25% for ecosystem development
    uint256 public constant TEAM_ALLOCATION = 15_000_000 * 10**18; // 15% for team
    uint256 public constant COMMUNITY_ALLOCATION = 20_000_000 * 10**18; // 20% for community rewards

    // Track minted amounts per category
    uint256 public researchMinted;
    uint256 public ecosystemMinted;
    uint256 public teamMinted;
    uint256 public communityMinted;

    constructor() ERC20("NeuraDeSci Token", "NDS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(DAO_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mintResearch(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(researchMinted + amount <= RESEARCH_ALLOCATION, "Exceeds research allocation");
        researchMinted += amount;
        _mint(to, amount);
    }

    function mintEcosystem(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(ecosystemMinted + amount <= ECOSYSTEM_ALLOCATION, "Exceeds ecosystem allocation");
        ecosystemMinted += amount;
        _mint(to, amount);
    }

    function mintTeam(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(teamMinted + amount <= TEAM_ALLOCATION, "Exceeds team allocation");
        teamMinted += amount;
        _mint(to, amount);
    }

    function mintCommunity(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(communityMinted + amount <= COMMUNITY_ALLOCATION, "Exceeds community allocation");
        communityMinted += amount;
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function getTotalMinted() public view returns (uint256) {
        return researchMinted + ecosystemMinted + teamMinted + communityMinted;
    }

    function getRemainingAllocation(string memory category) public view returns (uint256) {
        bytes32 categoryHash = keccak256(abi.encodePacked(category));
        
        if (categoryHash == keccak256(abi.encodePacked("research"))) {
            return RESEARCH_ALLOCATION - researchMinted;
        } else if (categoryHash == keccak256(abi.encodePacked("ecosystem"))) {
            return ECOSYSTEM_ALLOCATION - ecosystemMinted;
        } else if (categoryHash == keccak256(abi.encodePacked("team"))) {
            return TEAM_ALLOCATION - teamMinted;
        } else if (categoryHash == keccak256(abi.encodePacked("community"))) {
            return COMMUNITY_ALLOCATION - communityMinted;
        }
        
        return 0;
    }
} 