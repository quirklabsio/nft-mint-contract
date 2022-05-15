
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./MerkleVerification.sol";

contract ERC721Minter is ERC721, Ownable, MerkleVerification {
    using Counters for Counters.Counter;

    // Allow list eligibility status
    enum Status {
      Eligible,
      AlreadyClaimed,
      NotEligible
    }

    uint256 private constant AMOUNT_FOR_ALLOW_LIST = 992;
    uint256 private constant AMOUNT_FOR_DEVS = 8;

    Counters.Counter private _tokenIdTracker;
    
    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;
    bool public saleIsActive = false;
    bool public metadataIsFrozen = false;
    uint256 public mintPrice = 0.1 ether;
    mapping(address => bool) public allowListClaimed;

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

    /**
    @notice Returns the total amount of tokens stored by the contract.
    */
    function totalSupply() external view returns (uint256) {
        return getNextTokenId() - 1;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        require(!metadataIsFrozen, "Metadata is permanently frozen");

        baseTokenURI = _baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external virtual override onlyOwner {
        merkleRoot = _merkleRoot; 
    } 

    /**
    @notice Mints a token to the caller if requirements are met.
    @param proof Sibling hashes on the branch from the leaf to the root of the merkle tree.
    */
    function allowListMint(bytes32[] memory proof) external payable {
        require(saleIsActive, "Sale must be active to claim");
        require(checkStatus(_msgSender(), proof) == Status.Eligible, "Account must be eligible to claim");
        require(msg.value >= mintPrice, "Insufficient funds provided");

        _mintTo(_msgSender());
        allowListClaimed[_msgSender()] = true;

        // Refund if over
        if (msg.value > mintPrice) {
            payable(_msgSender()).transfer(msg.value - mintPrice);
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
    @notice Checks allow list eligibility for the supplied address.
    */
    function checkStatus(address _account, bytes32[] memory _proof) public view returns (Status) {
        return !_verifyMerkleLeaf(_generateMerkleLeaf(_account), _proof) 
            ? Status.NotEligible
            : allowListClaimed[_account]
                ? Status.AlreadyClaimed
                : Status.Eligible;
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