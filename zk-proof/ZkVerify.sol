// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Groth16Verifier} from "./verifier.sol";

contract ZkVerify {
    Groth16Verifier verifier;

    error Hash_Already_Stored();
    error Proof_Not_Valid();
    error Add_Hash_First();
    error User_Already_Verified();

    event NewIdHashAdded(address indexed user, bytes32 idHash);
    event UserVerified(address indexed user);

    constructor(address verifierAddr) {
        verifier = Groth16Verifier(verifierAddr);
    }

    mapping(address => bytes32) private brightIdHashes;
    mapping(address => bool) private verified;

    function addNewIdHash(bytes32 idHash) public {
        if (brightIdHashes[msg.sender] != bytes32(0))
            revert Hash_Already_Stored();

        brightIdHashes[msg.sender] = idHash;
        emit NewIdHashAdded(msg.sender, idHash);
    }

    function verifyProof(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[1] calldata d
    ) public {
        if (brightIdHashes[msg.sender] == bytes32(0)) revert Add_Hash_First();
        if (verified[msg.sender]) revert User_Already_Verified();

        bool isValid = verifier.verifyProof(a, b, c, d);
        if (isValid) {
            verified[msg.sender] = true;
            emit UserVerified(msg.sender);
        } else revert Proof_Not_Valid();
    }

    function isVerified(address user) public view returns (bool) {
        return verified[user];
    }
}
