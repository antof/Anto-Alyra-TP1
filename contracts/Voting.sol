// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable{

  constructor() Ownable(msg.sender) {
    currentVoteStatus = WorkflowStatus.RegisteringVoters;
    }
    
    struct Voter { 
        bool isRegistered; 
        bool hasVoted; 
        uint votedProposalId; 
    }

    struct Proposal { 
        string description; 
        uint voteCount; 
    }

    enum WorkflowStatus { RegisteringVoters, ProposalsRegistrationStarted, ProposalsRegistrationEnded, VotingSessionStarted, VotingSessionEnded, VotesTallied }

    WorkflowStatus currentVoteStatus;

    mapping(address => Voter) public whitelist;
    Proposal[] public proposals;

    uint winningProposalId;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    function changeStatus(WorkflowStatus _status) public onlyOwner
    {
        require(currentVoteStatus!=_status, "The status is already the one you're trying to set");
        emit WorkflowStatusChange(currentVoteStatus, _status);
        currentVoteStatus = _status;    
        if(currentVoteStatus == WorkflowStatus.VotesTallied)
            calculateResult();
    }

    function registerVoter(address _voterAddress) public onlyOwner
    {
        require(currentVoteStatus == WorkflowStatus.RegisteringVoters, "The registration phase is over");
        whitelist[_voterAddress] = Voter(true,false,0);
        emit VoterRegistered(_voterAddress);
    }

    function registerProposal(string memory _description) public 
    {
        require(whitelist[msg.sender].isRegistered,"You are not registered as a Voter");
        require(currentVoteStatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposal registration is not open");
        proposals.push(Proposal(_description,0));
        emit ProposalRegistered(proposals.length-1);
    }

    function voteProposal(uint _proposalId) public
    {
        Voter storage sender = whitelist[msg.sender];
        require(currentVoteStatus == WorkflowStatus.VotingSessionStarted, "Vote session is not started");
        require(!whitelist[msg.sender].hasVoted,"User has already voted");
        require(_proposalId<proposals.length,"This proposal Id doesn't exist");
        emit Voted(msg.sender,_proposalId);
        sender.hasVoted = true;
        sender.votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
    }

    function calculateResult() internal
    {      
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposalId = p;
            }
        }
    }

    function getWinner() public view returns (Proposal memory winningProposal)
    {
        winningProposal = proposals[winningProposalId];
    }
}