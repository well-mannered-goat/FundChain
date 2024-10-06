// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {FundChainNFT} from "./FundChainNFT.sol";

contract FundChainDAO is Ownable {
    struct Proposal {
        uint32 votes;       
        uint16[] regions;    
        uint256 id;          
        string description; 
    }

    error Not_Enough_Balance_To_Vote();
    error Can_Only_Vote_Once();
    error Proposal_Crossed_Deadline();
    event NewProposal(address indexed proposer);
    event ProposalAccepted(uint256 id);
    bool public votingEnabled;

    modifier onlyWhenVotingEnabled() {
        require(votingEnabled, "Voting is currently disabled");
        _;
    }

    Proposal[] public proposals;
    mapping(address => bool) public hasVoted;
    uint256 public proposalId = 0;
    uint256 public currId = 0;
    FundChainNFT private VoteToken;

    constructor(address NFTAddress) Ownable(msg.sender) {
        VoteToken = FundChainNFT(NFTAddress);
    }

    function createProposal(string memory description, uint16[] memory regions) external onlyOwner {
        proposals.push(
            Proposal({
                votes: 0,
                id: proposalId,
                description: description,
                regions: regions
            })
        );
        proposalId++;
        emit NewProposal(msg.sender);
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
        Proposal storage proposal = proposals[id];

        proposal.votes += 1;
        hasVoted[msg.sender] = true;
    }

    function selectProposal() external onlyOwner  {
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
    }

    // function checkUpkeep(
    //     bytes calldata /* checkData */
    // )
    //     external
    //     view
    //     returns (bool upkeepNeeded, bytes memory /* performData */)
    // {
    //     if (currId >= proposals.length) return (false, "0x0");

    //     Proposal memory proposal = proposals[currId];
    //     upkeepNeeded = (proposal.state == 3); 
    //     return (upkeepNeeded, "0x0");
    // }

    // function performUpkeep(bytes calldata /* performData */) external {
    //     execute(currId);
    // }

    // function execute(uint256 id) internal {
    //     Proposal storage proposal = proposals[id];
    //     uint256 votesFor = proposal.votes;
    //     uint256 votesAgainst = 0;

    //     if (votesAgainst >= votesFor) {
    //         proposal.state = 1; 
    //     } else {
    //         proposal.state = 2;
    //     }

    //     currId++;
    //     removeProposal(id);
    // }

    // function removeProposal(uint256 index) internal {
    //     require(index < proposals.length, "Index out of bounds");
    //     proposals[index] = proposals[proposals.length - 1];
    //     proposals.pop();
    // }

    // function getProposalsLength() external view returns (uint256) {
    //     return proposals.length;
    // }
}
