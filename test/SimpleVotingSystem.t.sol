// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";

contract SimpleVotingSystemTest is Test {
    SimpleVotingSystem public votingSystem;

    address public admin = makeAddr("admin");
    address public founder = makeAddr("founder");
    address public voter1 = makeAddr("voter1");
    
    address public candidateAlice = makeAddr("candidateAlice");

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; 
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    function setUp() public {
        vm.prank(admin); 
        votingSystem = new SimpleVotingSystem();

        vm.prank(admin);
        votingSystem.grantRole(FOUNDER_ROLE, founder);
        
        vm.deal(founder, 100 ether);
    }

    // --- TEST ROLES ---
    function test_RolesSetup() public view {
        assertTrue(votingSystem.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(votingSystem.hasRole(FOUNDER_ROLE, founder));
    }

    // --- TEST AJOUT CANDIDAT ---
    function test_AddCandidate() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice", candidateAlice);

        ( , string memory name, address addr, ) = votingSystem.candidates(1);
        assertEq(name, "Alice");
        assertEq(addr, candidateAlice);
    }

    // --- TEST FUNDING ---
    function test_FounderCanFundCandidate() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice", candidateAlice);

        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        uint256 amountToSend = 1 ether;
        uint256 balanceBefore = candidateAlice.balance;

        vm.prank(founder);
        votingSystem.fundCandidate{value: amountToSend}(1);

        uint256 balanceAfter = candidateAlice.balance;
        assertEq(balanceAfter, balanceBefore + amountToSend);
    }

    function testRevert_FundingWrongStatus() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice", candidateAlice);
                
        vm.prank(founder);
        vm.expectRevert("Funding candidates is not open");
        votingSystem.fundCandidate{value: 1 ether}(1);
    }

    // --- TEST VOTE AVEC TEMPS ---
    function test_Vote_Success_After1Hour() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice", candidateAlice);

        vm.startPrank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.prank(voter1);
        votingSystem.vote(1);

        assertEq(votingSystem.getTotalVotes(1), 1);
    }

    function testRevert_VoteTooEarly() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice", candidateAlice);

        vm.startPrank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.prank(voter1);
        vm.expectRevert("Voting starts 1 hour after session open");
        votingSystem.vote(1);
    }
}