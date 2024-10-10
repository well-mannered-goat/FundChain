// SPDX-License-Identifier: MIT
// A mock verifier contract to simplify the zk-proof verification method to be used in tests

pragma solidity ^0.8.18;

contract MockVerifier {
    error Hash_Already_Stored();
    error Proof_Not_Valid();
    error User_Already_Verified();
    error Add_Hash_First();

    mapping(address => bytes32) private brightIdHashes;
    mapping(address => bool) private verified;

    function addNewIdHash(bytes32 idHash) public {
        if (brightIdHashes[msg.sender] != bytes32(0))
            revert Hash_Already_Stored();

        brightIdHashes[msg.sender] = idHash;
    }

    function verifyProof(bytes32 brightIdHash) public {
        if (brightIdHashes[msg.sender] == bytes32(0)) revert Add_Hash_First();
        if (verified[msg.sender]) revert User_Already_Verified();

        if (brightIdHash == brightIdHashes[msg.sender])
            verified[msg.sender] = true;
        else revert Proof_Not_Valid();
    }

    function isVerified(address user) public view returns (bool) {
        return verified[user];
    }
}
