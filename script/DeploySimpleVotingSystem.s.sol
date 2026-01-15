// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";

contract DeploySimpleVotingSystem is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        SimpleVotingSystem votingSystem = new SimpleVotingSystem();

        console.log("SimpleVotingSystem deployed at:", address(votingSystem));
        console.log("VotingNFT deployed at:", address(votingSystem.votingNFT()));

        vm.stopBroadcast();
    }
}