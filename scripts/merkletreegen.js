const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

let allowListAddresses = [
    // TODO
];

const leafNodes = allowListAddresses.map(addr => keccak256(addr));
const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
const rootHash = merkleTree.getHexRoot();

console.log('Allow list Merkle Tree\n', rootHash.toString());

const hexProof = merkleTree.getHexProof(keccak256("TODO"));

console.log('Proof\n', hexProof.toString());
