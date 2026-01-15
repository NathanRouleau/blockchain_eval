// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract SimpleVotingSystem is AccessControl {

    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }

    WorkflowStatus public workflowStatus;

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setWorkflowStatus(WorkflowStatus _status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        WorkflowStatus previousStatus = workflowStatus;
        workflowStatus = _status;
        emit WorkflowStatusChange(previousStatus, _status);
    }

    function addCandidate(string memory _name) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // possible que pendant l'enregistrement
        require(workflowStatus == WorkflowStatus.REGISTER_CANDIDATES, "Candidates registration is not open");
        
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);
    }

    function vote(uint _candidateId) public {
        // possible que pendant le vote
        require(workflowStatus == WorkflowStatus.VOTE, "Voting session is not open");
        
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
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