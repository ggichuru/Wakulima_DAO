// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IWakulimaMarketPlace {
    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);

    function purchase(uint256 _tokenId) external payable;
}

interface IWakulimaNFT {
    // Returns the number of nfts owned
    function balanceOf(address owner) external view returns (uint256);

    // returns the token ids of NFTs
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract WakulimaDao is Ownable {
    struct Proposal {
        uint256 nftTokenId; // token id of the NFT to purchase if the propasal passes
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        mapping(uint256 => bool) voters; // mapping of nft token ids. Check ifs an nft has already been used to cast a vote or not
    }

    // Mapping of IDs ot proposal
    mapping(uint256 => Proposal) public proposals;
    uint256 public numOfProposals;

    // Initialize interfaces
    IWakulimaMarketPlace nftM_P;
    IWakulimaNFT wakulimaNft;

    // Initialize contracts
    constructor(address _nftMarketplace, address _wakulimaNft) payable {
        nftM_P = IWakulimaMarketPlace(_nftMarketplace);
        wakulimaNft = IWakulimaNFT(_wakulimaNft);
    }

    // Modifier: only those who hold WakulimaNFT can call other functions
    modifier nftHolderOnly() {
        require(
            wakulimaNft.balanceOf(msg.sender) > 0,
            "NOT A MEMBER OF THE WAKULIMA DAO"
        );
        _;
    }

    /** Allow member to create new proposals */
    function createProposal(uint256 _tokenId)
        external
        nftHolderOnly
        returns (uint256)
    {
        require(nftM_P.available(_tokenId), "NOT FOR SALE");
        Proposal storage proposal = proposals[numOfProposals];

        proposal.nftTokenId = _tokenId;

        proposal.deadline = block.timestamp + 5; // Five minutes from the current time

        numOfProposals++;

        return numOfProposals - 1;
    }

    // Modifier: proposal whose deadline is passed cannot be vote on
    modifier onlyActiveProposals(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE EXCEEDED"
        );
        _;
    }

    enum Vote {
        YAY,
        NAY
    }

    function voteOnProposal(uint256 indexOfProposal, Vote vote)
        external
        nftHolderOnly
        onlyActiveProposals(indexOfProposal)
    {
        Proposal storage proposal = proposals[indexOfProposal];

        uint256 voterNftBalance = wakulimaNft.balanceOf(msg.sender);
        uint256 numVotes = 0;

        // Calculate how many nfts are owned by the voter that havent been used to vote
        for (uint256 i = 0; i < voterNftBalance; i++) {
            uint256 tokenId = wakulimaNft.tokenOfOwnerByIndex(msg.sender, 1);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }

        require(numVotes > 0, "Already voted");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    // modifier: call if deadline has been exceeded
    modifier inactiveProposalsOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE NOT EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL ALREADY EXECUTED"
        );
        _;
    }

    /** Execute proposal whose deadline has been reached */
    function executeProposal(uint256 proposalIndex)
        external
        nftHolderOnly
        inactiveProposalsOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        // if proposal has more yay than nay votes, purchase nft from market_place
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftM_P.getPrice();
            require(address(this).balance >= nftPrice, "NOT ENOUGH FUNDS");
            nftM_P.purchase{value: nftPrice}(proposal.nftTokenId);
        }

        proposal.executed = true;
    }

    /** Allow contract deployer to withdraw eth from contract */
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}
}
