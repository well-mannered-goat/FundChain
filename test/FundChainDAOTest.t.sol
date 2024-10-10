// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {FundChainDAO, IZkVerify} from "../src/FundChainDAO.sol";
import {FundChainNFT} from "../src/FundChainNFT.sol";
import {DeployFundChain} from "../script/deployFundChain.s.sol";
import {MockVerifier} from "./mocks/MockVerifier.sol";

contract FundChainDAOTest is Test {
    FundChainDAO fundChainDAO;
    FundChainNFT fundChainNFT;
    DeployFundChain deployer;
    MockVerifier zkVerifier;

    uint16[] regions;
    address admin;

    function setUp() external {
        deployer = new DeployFundChain();
        zkVerifier = new MockVerifier();

        (, fundChainNFT) = deployer.run();
        fundChainDAO = new FundChainDAO(
            address(fundChainNFT),
            address(zkVerifier)
        );
        regions.push(1);

        admin = fundChainDAO.getAdmin();
    }

    function testCreatingProposal() external {
        vm.prank(fundChainDAO.getAdmin());
        vm.expectEmit();
        emit FundChainDAO.NewProposal(0);
        fundChainDAO.createProposal("desc", regions);

        assertEq(fundChainDAO.totalProposals(), 1);
    }

    function testUserCantRegisterHashTwice() external {
        address user = address(1);
        vm.prank(user);
        zkVerifier.addNewIdHash(bytes32(uint256(1)));

        vm.expectRevert(MockVerifier.Hash_Already_Stored.selector);
        vm.prank(user);
        zkVerifier.addNewIdHash(bytes32(uint256(2)));
    }

    function testUserCantVerifyBeforeAddingBrightIdHash() external {
        address user = address(1);
        vm.expectRevert(MockVerifier.Add_Hash_First.selector);
        vm.prank(user);
        zkVerifier.verifyProof(bytes32(uint256(2)));
    }

    function testUserCantVerifyTwice() external {
        address user = address(1);
        vm.startPrank(user);
        zkVerifier.addNewIdHash(bytes32(uint256(1)));
        zkVerifier.verifyProof(bytes32(uint256(1)));
        vm.stopPrank();

        vm.expectRevert(MockVerifier.User_Already_Verified.selector);
        vm.prank(user);
        zkVerifier.verifyProof(bytes32(uint256(1)));
    }

    function testProvidingWrongProofReverts() external {
        address user = address(1);
        vm.prank(user);
        zkVerifier.addNewIdHash(bytes32(uint256(1)));

        vm.expectRevert(MockVerifier.Proof_Not_Valid.selector);
        vm.prank(user);
        zkVerifier.verifyProof(bytes32(uint256(2)));
    }

    function testuserCantVoteWithoutGivingZkProof() external {
        address user = address(1);

        vm.startPrank(admin);
        fundChainDAO.createProposal("desc1", regions);
        fundChainNFT.mint(user);
        vm.stopPrank();

        vm.prank(user);
        vm.expectRevert(FundChainDAO.Must_Give_Zk_ID_Proof.selector);
        fundChainDAO.voteFor(0);
    }

    function testVoting() external {
        vm.startPrank(admin);
        fundChainDAO.createProposal("desc1", regions);
        fundChainDAO.createProposal("desc2", regions);
        fundChainDAO.createProposal("desc3", regions);
        vm.stopPrank();

        assert(fundChainDAO.totalProposals() == 3);

        vm.prank(address(1));
        vm.expectRevert(FundChainDAO.Not_Enough_Balance_To_Vote.selector);
        fundChainDAO.voteFor(0);

        for (uint256 i = 1; i <= 3; i++) {
            address voter = address(uint160(i));
            vm.prank(admin);
            fundChainNFT.mint(voter);
            vm.startPrank(voter);
            zkVerifier.addNewIdHash(bytes32(i));
            zkVerifier.verifyProof(bytes32(i));
            fundChainDAO.voteFor(0);
            vm.stopPrank();
        }

        for (uint256 i = 4; i <= 7; i++) {
            address voter = address(uint160(i));
            vm.prank(admin);
            fundChainNFT.mint(voter);
            vm.startPrank(voter);
            zkVerifier.addNewIdHash(bytes32(i));
            zkVerifier.verifyProof(bytes32(i));
            fundChainDAO.voteFor(1);
            vm.stopPrank();
        }

        for (uint256 i = 8; i <= 10; i++) {
            address voter = address(uint160(i));
            vm.prank(admin);
            fundChainNFT.mint(voter);
            vm.startPrank(voter);
            zkVerifier.addNewIdHash(bytes32(i));
            zkVerifier.verifyProof(bytes32(i));
            fundChainDAO.voteFor(2);
            vm.stopPrank();
        }

        vm.expectRevert(FundChainDAO.Can_Only_Vote_Once.selector);
        vm.prank(address(2));
        fundChainDAO.voteFor(0);

        vm.startPrank(admin);
        fundChainDAO.disableVoting();

        vm.expectEmit();
        emit FundChainDAO.ProposalAccepted(1);

        uint256 selectedProposal = fundChainDAO.selectProposal();
        vm.stopPrank();

        assertEq(selectedProposal, 1);
        vm.expectRevert(FundChainDAO.Voting_Currently_Disabled.selector);
        vm.prank(address(15));
        fundChainDAO.voteFor(2);
    }
}
