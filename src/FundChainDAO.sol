// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {FundChainNFT} from "./FundChainNFT.sol";
import {ZkVerify} from "../zk-proof/ZkVerify.sol";

contract FundChainDAO is Ownable {
    struct Proposal {
        uint32 votes;
        uint16[] regions;
        uint256 id;
        string description;
    }

    error Not_Enough_Balance_To_Vote();
    error Can_Only_Vote_Once();
    error Voting_Currently_Disabled();
    error Must_Give_Zk_ID_Proof();

    event NewProposal(uint256 id);
    event ProposalAccepted(uint256 id);

    modifier onlyWhenVotingEnabled() {
        if (!votingEnabled) revert Voting_Currently_Disabled();
        _;
    }

    Proposal[] public proposals;
    FundChainNFT private VoteToken;
    IZkVerify zkVerifier;

    mapping(address => bool) public hasVoted;

    uint256 public proposalId = 0;
    uint256 public currId = 0;
    bool public votingEnabled;
    address private immutable ADMIN =
        0x9f0Bc747Cc7Df76826Ba38Ad90E99dA6C17F613C;

    constructor(address NFTAddress, address verifierAddr) Ownable(ADMIN) {
        VoteToken = FundChainNFT(NFTAddress);
        votingEnabled = true;
        zkVerifier = IZkVerify(verifierAddr);
    }

    function createProposal(
        string memory description,
        uint16[] memory regions
    ) external onlyOwner {
        proposals.push(
            Proposal({
                votes: 0,
                id: proposalId,
                description: description,
                regions: regions
            })
        );
        emit NewProposal(proposalId);
        proposalId++;
    }

    function enableVoting() external onlyOwner {
        votingEnabled = true;
    }

    function disableVoting() external onlyOwner {
        votingEnabled = false;
    }

    function voteFor(uint256 id) external onlyWhenVotingEnabled {
        if (VoteToken.balanceOf(msg.sender) == 0)
            revert Not_Enough_Balance_To_Vote();
        if (hasVoted[msg.sender]) revert Can_Only_Vote_Once();
        if (!zkVerifier.isVerified(msg.sender)) revert Must_Give_Zk_ID_Proof();

        Proposal storage proposal = proposals[id];
        proposal.votes += 1;
        hasVoted[msg.sender] = true;
    }

    function selectProposal() external onlyOwner returns (uint256) {
        require(proposals.length > 0, "No proposals available");
        require(!votingEnabled, "Voting is currently enabled");
        votingEnabled = false;
        uint256 selectedProposalId = 0;

        for (uint256 i = 1; i < proposals.length; i++) {
            if (proposals[i].votes > proposals[selectedProposalId].votes) {
                selectedProposalId = i;
            }
        }
        emit ProposalAccepted(proposals[selectedProposalId].id);

        return selectedProposalId;
    }

    function getAdmin() public view returns (address) {
        return ADMIN;
    }

    function totalProposals() public view returns (uint256) {
        return proposals.length;
    }
}

interface IZkVerify {
    function isVerified(address user) external view returns (bool);
}
