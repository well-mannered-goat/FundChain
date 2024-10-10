// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundChainDAO} from "../src/FundChainDAO.sol";
import {FundChainNFT} from "../src/FundChainNFT.sol";
import {ZkVerify} from "../zk-proof/ZkVerify.sol";
import {Groth16Verifier} from "../zk-proof/verifier.sol";

contract DeployFundChain is Script {
    FundChainDAO fundChainDAO;
    FundChainNFT fundChainNFT;
    ZkVerify zkVerifier;
    Groth16Verifier verifier;

    function run() external returns (FundChainDAO, FundChainNFT) {
        vm.startBroadcast();
        fundChainNFT = new FundChainNFT();
        verifier = new Groth16Verifier();
        vm.stopBroadcast();

        vm.startBroadcast();
        zkVerifier = new ZkVerify(address(verifier));
        vm.stopBroadcast();

        vm.startBroadcast();
        fundChainDAO = new FundChainDAO(
            address(fundChainNFT),
            address(zkVerifier)
        );
        vm.stopBroadcast();

        return (fundChainDAO, fundChainNFT);
    }
}
