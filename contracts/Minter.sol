// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Minter is ERC721, Ownable {
  using Counters for Counters.Counter;
  
	enum Status {
		Eligible,
		AlreadyClaimed,
		NotEligible
	}

  uint256 private constant AMOUNT_FOR_ALLOWLIST = 995;
  uint256 private constant AMOUNT_FOR_DEVS = 5;

  Counters.Counter private _tokenIds;
  string private _tokenBaseURI;

  bytes32 public merkleRoot; 
	bool public metadataIsFrozen = false;
  uint256 public mintPrice = 0.1 ether;
  mapping(address => bool) public allowlistClaimed;

  constructor(
    string memory name, 
    string memory symbol, 
    string memory uri
    ) ERC721(name, symbol) {
    _tokenBaseURI = uri;
    _tokenIds.increment(); // Start at 1
  }

  // STEPS FOR MINT

  // 1. Set merkle root
  function setMerkleRoot(bytes32 root) external onlyOwner {
    merkleRoot = root; 
  }  

  // 2a. Allowlist mint
  function allowlistMint(bytes32[] memory _proof) external payable {
    require(_tokenIds.current() <= AMOUNT_FOR_ALLOWLIST, "Reached max allowlist supply");
    require(checkStatus(msg.sender, _proof) == Status.Eligible, "Account is not eligible to claim");
    require(msg.value >= mintPrice, "Insufficient funds provided");

    _mintTo(msg.sender);
    allowlistClaimed[msg.sender] = true;

    // Refund if over
    if (msg.value > mintPrice) {
      payable(msg.sender).transfer(msg.value - mintPrice);
    }
  }

  // 2b. Dev mint
  function devMint(uint256 count) external onlyOwner {
		for (uint256 i = 0; i < count; i++) {
			_mintTo(msg.sender);
		}
	}

  // 3. Withdraw funds
  function withdrawFunds(address address_) external onlyOwner {
		(bool success, ) = address_.call{value: address(this).balance}("");
		require(success, "Transfer failed");
	}

  // 4. Freeze metadata
  function freezeMetadata() external onlyOwner {
    require(!metadataIsFrozen, "Metadata is already frozen");
    metadataIsFrozen = true;
  }

  // Check account status
  function checkStatus(address _account, bytes32[] memory _proof) public view returns (Status) {
    return !_verifyMerkleLeaf(_generateMerkleLeaf(_account), merkleRoot, _proof) 
            ? Status.NotEligible
            : allowlistClaimed[_account]
              ? Status.AlreadyClaimed
              : Status.Eligible;
  }

  // Update token base URI
  function setBaseURI(string memory uri) external onlyOwner {
    require(!metadataIsFrozen, "Metadata is permanently frozen");
    _tokenBaseURI = uri;
  }

  // Update mint price
  function setMintPrice(uint256 newPrice) external onlyOwner {
    mintPrice = newPrice;
  }

  // Get next tokenId
  function getNextTokenId() external view returns (uint256) {
    return _tokenIds.current();
  }

  // Verify that the given leaf belongs to a given tree using its root for comparison
	function _verifyMerkleLeaf(  
    bytes32 _leafNode,  
    bytes32 _merkleRoot,  
    bytes32[] memory _proof 
  ) 
    internal pure returns (bool) 
  {  
    return MerkleProof.verify(_proof, _merkleRoot, _leafNode); 
  }

  // Create merkle leaf from supplied data
  function _generateMerkleLeaf(address _account) internal pure returns (bytes32) {  
    return keccak256(abi.encodePacked(_account)); 
  }

  // Mint to address
  function _mintTo(address to) private {
    require(_tokenIds.current() <= AMOUNT_FOR_ALLOWLIST + AMOUNT_FOR_DEVS, "Reached max supply");
		_safeMint(to, _tokenIds.current());
    _tokenIds.increment();
	}

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenBaseURI;
  }
}