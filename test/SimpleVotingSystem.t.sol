// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";
import {VotingNFT} from "../src/VotingNFT.sol";

contract SimpleVotingSystemTest is Test {
    SimpleVotingSystem public votingSystem;
    VotingNFT public votingNFT;

    address public admin = makeAddr("admin");
    address public founder = makeAddr("founder");
    address public withdrawer = makeAddr("withdrawer");
    address public voter1 = makeAddr("voter1");
    
    address public candidateAlice = makeAddr("candidateAlice");
    address public candidateBob = makeAddr("candidateBob");

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; 
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    function setUp() public {
        vm.prank(admin); 
        votingSystem = new SimpleVotingSystem();
        votingNFT = votingSystem.votingNFT();

        vm.startPrank(admin);
        votingSystem.grantRole(FOUNDER_ROLE, founder);
        votingSystem.grantRole(WITHDRAWER_ROLE, withdrawer);
        vm.stopPrank();
        
        vm.deal(founder, 100 ether);
    }

    // --- TEST ROLES ---
    function test_RolesSetup() public view {
        assertTrue(votingSystem.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(votingSystem.hasRole(FOUNDER_ROLE, founder));
    }

    function test_NFTIsDeployed() public view {
        assertTrue(address(votingNFT) != address(0));
        assertEq(votingNFT.owner(), address(votingSystem));
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

    // --- TEST VOTE & NFT ---
    function test_Vote_MintNFT() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice", candidateAlice);

        vm.startPrank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1 seconds);
        assertEq(votingNFT.balanceOf(voter1), 0);

        vm.prank(voter1);
        votingSystem.vote(1);

        assertEq(votingNFT.balanceOf(voter1), 1);
        assertEq(votingSystem.getTotalVotes(1), 1);
    }

    function testRevert_CannotVoteTwice_WithNFT() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice", candidateAlice);
        vm.startPrank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.prank(voter1);
        votingSystem.vote(1);

        vm.prank(voter1);
        vm.expectRevert("You already have the voting NFT");
        votingSystem.vote(1);
    }

    function test_GetWinner() public {
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice", candidateAlice);
        votingSystem.addCandidate("Bob", candidateBob);
        
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.prank(voter1);
        votingSystem.vote(2);

        vm.expectRevert("Voting session is not completed");
        votingSystem.getWinner();

        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);

        SimpleVotingSystem.Candidate memory winner = votingSystem.getWinner();
        
        assertEq(winner.id, 2);
        assertEq(winner.name, "Bob");
        assertEq(winner.voteCount, 1);
    }

    function test_Withdraw() public {
        vm.deal(address(123), 10 ether);
        vm.prank(address(123));
        (bool sent, ) = address(votingSystem).call{value: 5 ether}("");
        require(sent, "Sending eth failed");

        assertEq(address(votingSystem).balance, 5 ether);

        vm.prank(withdrawer);
        vm.expectRevert("Voting session is not completed");
        votingSystem.withdraw();

        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);

        uint balanceBefore = withdrawer.balance;
        
        vm.prank(withdrawer);
        votingSystem.withdraw();

        assertEq(address(votingSystem).balance, 0);
        assertEq(withdrawer.balance, balanceBefore + 5 ether);
    }
}