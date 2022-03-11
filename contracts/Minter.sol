// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Minter is 
  ERC721, 
  Ownable 
{
  using Counters for Counters.Counter;
  
  enum Status {
    Eligible,
    AlreadyClaimed,
    NotEligible
  }

  uint256 private constant AMOUNT_FOR_ALLOWLIST = 995;
  uint256 private constant AMOUNT_FOR_DEVS = 5;

  Counters.Counter private _tokenIdTracker;

  string private _baseTokenURI;

  bytes32 public merkleRoot; 

  bool public saleIsActive = false;
	bool public metadataIsFrozen = false;
  uint256 public mintPrice = 0.1 ether;

  mapping(address => bool) public allowlistClaimed;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI
    ) ERC721(name, symbol) {
    _baseTokenURI = baseTokenURI;

    // We want to start at 1
    _tokenIdTracker.increment();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
    require(!metadataIsFrozen, "Metadata is permanently frozen");

    _baseTokenURI = baseTokenURI;
  }

  // STEPS FOR MINT

  /**
  * 1. Set merkle root before minting.
  */
  function setMerkleRoot(bytes32 root) external onlyOwner {
    merkleRoot = root; 
  }  

  /**
  * 2. Make sale active (or pause sale if necessary).
  */
  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  /**
  * 3a. Allowlist mint.
  */
  function allowlistMint(bytes32[] memory _proof) external payable {
    require(saleIsActive, "Sale must be active to claim");
    require(checkStatus(_msgSender(), _proof) == Status.Eligible, "Account must be eligible to claim");
    require(msg.value >= mintPrice, "Insufficient funds provided");

    _mintTo(_msgSender());
    allowlistClaimed[_msgSender()] = true;

    // Refund if over
    if (msg.value > mintPrice) {
      payable(_msgSender()).transfer(msg.value - mintPrice);
    }
  }

  /**
  * 3b. Dev mint.
  */
  function devMint(uint256 count) external onlyOwner {
		for (uint256 i = 0; i < count; i++) {
			_mintTo(_msgSender());
		}
	}

  /**
  * 4. Withdraw funds to supplied address.
  */
  function withdrawTo(address address_) external onlyOwner {
		(bool success, ) = address_.call{value: address(this).balance}("");
		require(success, "Transfer failed");
	}

  /**
  * 5. Freeze metadata when ready to permanently lock.
  */
  function freezeMetadata() external onlyOwner {
    require(!metadataIsFrozen, "Metadata is already frozen");

    metadataIsFrozen = true;
  }

  // PUBLIC METHODS

  /**
  * Check allowlist eligibility for supplied address.
  */
  function checkStatus(address _account, bytes32[] memory _proof) public view returns (Status) {
    require(merkleRoot != "", "Merkle root must not be empty");

    return !_verifyMerkleLeaf(_generateMerkleLeaf(_account), merkleRoot, _proof) 
            ? Status.NotEligible
            : allowlistClaimed[_account]
              ? Status.AlreadyClaimed
              : Status.Eligible;
  }

  /**
  * Update mint price if necessary.
  */
  function setMintPrice(uint256 newPrice) external onlyOwner {
    mintPrice = newPrice;
  }

  /**
  * Get current token id.
  */
  function getCurrentTokenId() external view returns (uint256) {
    return _tokenIdTracker.current();
  }

  // PRIVATE METHODS

  /**
  * Verify that the given leaf belongs to a given tree 
  * using its root for comparison.
  */
	function _verifyMerkleLeaf(  
    bytes32 _leafNode,  
    bytes32 _merkleRoot,  
    bytes32[] memory _proof 
  ) 
    internal pure returns (bool) 
  {  
    return MerkleProof.verify(_proof, _merkleRoot, _leafNode); 
  }

  /**
  * Create merkle leaf from supplied address.
  */
  function _generateMerkleLeaf(address _account) internal pure returns (bytes32) {  
    return keccak256(abi.encodePacked(_account)); 
  }

  /**
  * Mint to supplied address.
  */
  function _mintTo(address to) private {
    require(_tokenIdTracker.current() <= AMOUNT_FOR_ALLOWLIST + AMOUNT_FOR_DEVS, "Reached max token supply");

		_safeMint(to, _tokenIdTracker.current());
    _tokenIdTracker.increment();
	}
}