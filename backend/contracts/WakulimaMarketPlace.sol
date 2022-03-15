// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract WakulimaMarketPlace {
    mapping(uint256 => address) public tokens;

    // Set purchase price of each fake nft
    uint256 nftPrice = 0.1 ether;

    // accepts eth and marks the owner as the caller addres
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "The NFT const 0.1 ether");
        tokens[_tokenId] = msg.sender;
    }

    // get price of one NFT
    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    // Check if the given token has already been sold or not
    function available(uint256 _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        }

        return false;
    }
}
