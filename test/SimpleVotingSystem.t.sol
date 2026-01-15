// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";

contract SimpleVotingSystemTest is Test {
    SimpleVotingSystem public votingSystem;

    address public admin = makeAddr("admin");
    address public voter1 = makeAddr("voter1");
    address public voter2 = makeAddr("voter2");

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; 

    function setUp() public {
        vm.prank(admin); 
        votingSystem = new SimpleVotingSystem();
    }

    // --- TEST ROLE ADMIN ---
    function test_AdminIsSetCorrectly() public view {
        assertTrue(votingSystem.hasRole(DEFAULT_ADMIN_ROLE, admin));
    }

    // --- TEST WORKFLOW ---
    function test_AdminCanChangeWorkflowStatus() public {
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        
        assertTrue(votingSystem.workflowStatus() == SimpleVotingSystem.WorkflowStatus.VOTE);
    }

    function testRevert_NonAdminCannotChangeWorkflow() public {
        vm.prank(voter1);
        vm.expectRevert();
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    }

    // --- TEST AJOUT CANDIDAT ---
    function test_AddCandidate_Success() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice");
        assertEq(votingSystem.getCandidatesCount(), 1);
    }

    function testRevert_AddCandidate_WrongStatus() public {
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);

        vm.prank(admin);
        vm.expectRevert("Candidates registration is not open");
        votingSystem.addCandidate("Bob");
    }

    // --- TEST DU VOTE ---
    function test_Vote_Success() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);

        vm.prank(voter1);
        votingSystem.vote(1);

        assertEq(votingSystem.getTotalVotes(1), 1);
        assertTrue(votingSystem.voters(voter1));
    }

    function testRevert_Vote_WrongStatus() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        vm.prank(voter1);
        vm.expectRevert("Voting session is not open");
        votingSystem.vote(1);
    }
}