// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundChainDAO} from "../src/FundChainDAO.sol";
import {FundChainNFT} from "../src/FundChainNFT.sol";

contract DeployFundChainDAO is Script {
    FundChainDAO fundChainDAO;
    FundChainNFT fundChainNFT;

    function run() external returns (FundChainDAO, FundChainNFT) {
        vm.startBroadcast();
        fundChainNFT = new FundChainNFT();
        vm.stopBroadcast();

        vm.startBroadcast();
        fundChainDAO = new FundChainDAO(address(fundChainNFT));
        vm.stopBroadcast();

        return (fundChainDAO, fundChainNFT);
    }
}
