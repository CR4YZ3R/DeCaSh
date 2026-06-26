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
        uint[2] calldata _pC
    ) external view returns (bool) {
        require(bookingActive(), "Rental expired");

        uint[1] memory pubSignals = [bookingCommitment];

        return verifier.verifyProof(_pA, _pB, _pC, pubSignals);
    }
}
