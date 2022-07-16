
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721Minter is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 private constant AMOUNT_FOR_ALLOW_LIST = 994;
    uint256 private constant AMOUNT_FOR_DEVS = 6;
    uint256 private constant MAX_ALLOWED_TO_MINT = 10;

    Counters.Counter private _tokenIdTracker;
    
    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;
    bool public saleIsActive = false;
    bool public metadataIsFrozen = false;
    uint256 public mintPrice = 0.1 ether;

    constructor(string memory name, string memory symbol) 
        ERC721(name, symbol) 
    {
        _tokenIdTracker.increment();
        for (uint256 i = 0; i < AMOUNT_FOR_DEVS; i++) {
            _mintTo(_msgSender());
        }
    }

    //////////////////////////////////////////////////////
    // External methods
    //////////////////////////////////////////////////////

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        require(!metadataIsFrozen, "Metadata is permanently frozen");

        baseTokenURI = _baseTokenURI;
    }

    /**
    @notice Mints token(s) to the caller if requirements are met.
    @param numberOfTokens Number of tokens to mint to the caller.
    */
    function allowListMint(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to claim");
        require(numberOfTokens <= MAX_ALLOWED_TO_MINT, "Purchase would exceed max tokens allowed to mint");
        require(msg.value >= (mintPrice * numberOfTokens), "Insufficient funds provided");
        require((totalSupply() + numberOfTokens) <= AMOUNT_FOR_ALLOW_LIST + AMOUNT_FOR_DEVS, "Purchase would exceed max token supply");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintTo(_msgSender());
        }

        // Refund if over
        if (msg.value > (mintPrice * numberOfTokens)) {
            payable(_msgSender()).transfer(msg.value - (mintPrice * numberOfTokens));
        }
    }

    /**
    @notice Makes sale active (or pauses sale if necessary).
    */
    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
    @notice Withdraws balance to the supplied address.
    */
    function withdrawTo(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /**
    @notice Freezes metadata when ready to permanently lock.
    */
    function freezeMetadata() external onlyOwner {
        require(!metadataIsFrozen, "Metadata is already frozen");

        metadataIsFrozen = true;
    }

    //////////////////////////////////////////////////////
    // Public methods
    //////////////////////////////////////////////////////

    /**
    @notice Gets next available token id. 
    */
    function getNextTokenId() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
    @notice Returns the total amount of tokens stored by the contract.
    */
    function totalSupply() public view returns (uint256) {
        return getNextTokenId() - 1;
    }

    //////////////////////////////////////////////////////
    // Internal methods
    //////////////////////////////////////////////////////

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    //////////////////////////////////////////////////////
    // Private methods
    //////////////////////////////////////////////////////

    /**
    @notice Mints to the supplied address.
    */
    function _mintTo(address to) private {
        require(getNextTokenId() <= AMOUNT_FOR_ALLOW_LIST + AMOUNT_FOR_DEVS, "Reached max token supply");

        _mint(to, getNextTokenId());
        _tokenIdTracker.increment();
    }
}