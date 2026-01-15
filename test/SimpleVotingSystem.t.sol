// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";

contract SimpleVotingSystemTest is Test {
    SimpleVotingSystem public votingSystem;

    // On définit des adresses pour nos tests
    address public admin = makeAddr("admin");
    address public voter1 = makeAddr("voter1");
    address public voter2 = makeAddr("voter2");

    // On récupère le hachage du rôle ADMIN depuis le contrat
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        // On se fait passer pour l'admin pour déployer
        vm.prank(admin);
        votingSystem = new SimpleVotingSystem();
    }

    // --- TEST DU ROLE ADMIN ---
    function test_AdminIsSetCorrectly() public view {
        // Au lieu de vérifier "owner", on vérifie si l'adresse a le rôle ADMIN
        assertTrue(votingSystem.hasRole(DEFAULT_ADMIN_ROLE, admin));
    }

    function test_AdminCanAddCandidate() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        assertEq(votingSystem.getCandidatesCount(), 1);

        // Vérification des données du candidat
        (uint256 id, string memory name, uint256 voteCount) = votingSystem.candidates(1);
        assertEq(id, 1);
        assertEq(name, "Alice");
        assertEq(voteCount, 0);
    }

    function testRevert_NonAdminCannotAddCandidate() public {
        // On essaie avec un utilisateur lambda (voter1)
        vm.prank(voter1);

        // On s'attend à une erreur car voter1 n'a pas le rôle
        // Note: Le message d'erreur d'AccessControl est un peu long, on vérifie juste que ça revert
        vm.expectRevert();
        votingSystem.addCandidate("Bob");
    }

    // --- TEST DU VOTE ---
    function test_Vote() public {
        // 1. L'admin ajoute un candidat
        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        // 2. Le voteur vote
        vm.prank(voter1);
        votingSystem.vote(1);

        // 3. Vérifications
        assertEq(votingSystem.getTotalVotes(1), 1);
        assertTrue(votingSystem.voters(voter1));
    }
}
