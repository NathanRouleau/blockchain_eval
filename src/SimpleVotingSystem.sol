// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {VotingNFT} from "./VotingNFT.sol";

contract SimpleVotingSystem is AccessControl {

    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }

    WorkflowStatus public workflowStatus;
    uint256 public voteStartTime;

    VotingNFT public votingNFT;

    struct Candidate {
        uint id;
        string name;
        address payable candidateAddress;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event CandidateFunded(uint indexed candidateId, uint amount);
    event FundsWithdrawn(address indexed withdrawer, uint amount);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        votingNFT = new VotingNFT();
    }

    receive() external payable {}

    function setWorkflowStatus(WorkflowStatus _status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        WorkflowStatus previousStatus = workflowStatus;
        workflowStatus = _status;
        
        if (_status == WorkflowStatus.VOTE) {
            voteStartTime = block.timestamp;
        }

        emit WorkflowStatusChange(previousStatus, _status);
    }

    function addCandidate(string memory _name, address _candidateAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(workflowStatus == WorkflowStatus.REGISTER_CANDIDATES, "Candidates registration is not open");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        require(_candidateAddress != address(0), "Candidate address cannot be zero");

        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, payable(_candidateAddress), 0);
        candidateIds.push(candidateId);
    }

    function fundCandidate(uint _candidateId) public payable onlyRole(FOUNDER_ROLE) {
        require(workflowStatus == WorkflowStatus.FOUND_CANDIDATES, "Funding candidates is not open");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        require(msg.value > 0, "You must send some ether");

        Candidate storage candidate = candidates[_candidateId];
        
        (bool success, ) = candidate.candidateAddress.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit CandidateFunded(_candidateId, msg.value);
    }

    function vote(uint _candidateId) public {
        require(workflowStatus == WorkflowStatus.VOTE, "Voting session is not open");
        require(block.timestamp >= voteStartTime + 1 hours, "Voting starts 1 hour after session open");
        
        require(votingNFT.balanceOf(msg.sender) == 0, "You already have the voting NFT");
        require(!voters[msg.sender], "You have already voted");
        
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;

        votingNFT.mint(msg.sender);
    }

    function withdraw() public onlyRole(WITHDRAWER_ROLE) {
        require(workflowStatus == WorkflowStatus.COMPLETED, "Voting session is not completed");
        require(address(this).balance > 0, "No funds to withdraw");

        uint amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw transfer failed");

        emit FundsWithdrawn(msg.sender, amount);
    }

    function getWinner() public view returns (Candidate memory) {
        require(workflowStatus == WorkflowStatus.COMPLETED, "Voting session is not completed");
        require(candidateIds.length > 0, "No candidates available");

        uint winningCandidateId = candidateIds[0];
        uint maxVotes = candidates[winningCandidateId].voteCount;

        for (uint i = 1; i < candidateIds.length; i++) {
            uint currentId = candidateIds[i];
            if (candidates[currentId].voteCount > maxVotes) {
                maxVotes = candidates[currentId].voteCount;
                winningCandidateId = currentId;
            }
        }

        return candidates[winningCandidateId];
    }

    function getTotalVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }

    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }
}