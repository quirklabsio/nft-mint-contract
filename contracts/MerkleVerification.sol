// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract MerkleVerification {
    bytes32 public merkleRoot; 

    /**
    @notice Sets merkle root.
    */
    function setMerkleRoot(bytes32 _merkleRoot) external virtual;

    /**
    @notice Verifies that the given leaf belongs to a given tree 
    using its root for comparison.
    */
    function _verifyMerkleLeaf(  
        bytes32 _leafNode, 
        bytes32[] memory _proof 
    ) 
        internal view returns (bool) 
    {  
        require(merkleRoot != "", "MerkleVerification: root is empty");

        return MerkleProof.verify(_proof, merkleRoot, _leafNode); 
    }

    /**
    @notice Creates a merkle leaf from the supplied address.
    */
    function _generateMerkleLeaf(address _account) internal pure returns (bytes32) {  
        return keccak256(abi.encodePacked(_account)); 
    }
}