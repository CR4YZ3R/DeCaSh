// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVerifier {
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[1] calldata _pubSignals
    ) external view returns (bool);
}

contract RentalCar {
    address public owner;
    address public renter;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public bookingCommitment;

    IVerifier public verifier;

    constructor(address verifierAddress) {
        owner = msg.sender;
        verifier = IVerifier(verifierAddress);
    }

    function rentCar(uint8 hoursToRent, uint256 commitment) external payable {
        require(renter == address(0), "Already rented");

        renter = msg.sender;

        startTime = block.timestamp;
        endTime = block.timestamp + hoursToRent * 1 hours;

        bookingCommitment = commitment;
    }

    function bookingActive() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function verifyAccess(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        bytes calldata signature
    ) external view returns (bool) {
        require(bookingActive(), "Rental expired");

        // Recover who signed the proof and confirm it was the registered renter
        bytes32 proofHash = keccak256(abi.encode(_pA, _pB, _pC));
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", proofHash));
        require(_recover(ethHash, signature) == renter, "Proof not signed by renter");

        uint[1] memory pubSignals = [bookingCommitment];
        return verifier.verifyProof(_pA, _pB, _pC, pubSignals);
    }

    function _recover(bytes32 hash, bytes calldata sig) internal pure returns (address) {
        require(sig.length == 65, "Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }
        return ecrecover(hash, v, r, s);
    }
}
