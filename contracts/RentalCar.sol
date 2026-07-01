// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Interface for Proxy-Pattern
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
    bool public bookingDisabled = false;
    address public renter;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public costPerHour = 20 gwei;

    uint256 public bookingCommitment;

    IVerifier public verifier;

    constructor(address verifierAddress) {
        owner = msg.sender;
        verifier = IVerifier(verifierAddress);
    }

    // Allows the owner to withdraw funds from the contract.
    // Only pays out a safe amount of ether to the owner, so that renters can still get their refunds or choose to return the car early.
    function payoutOwner() external {
        require(msg.sender == owner, "Only owner can withdraw");

        // Renter must be allowed to get their remaining time refunded, if they return the car early.
        // Thus we forbid the owner from withdrawing those funds. 
        uint256 _lockedFunds = calculateRemainingHours() * costPerHour;

        uint256 _balance = address(this).balance;
        uint256 _safelyWithdrawable = _balance > _lockedFunds ? _balance - _lockedFunds : 0;
        (bool _success, ) = owner.call{value: _safelyWithdrawable}("");
        require(_success, "Withdrawal failed");
    }

    // Used so that the Owner can deactivate further bookings. Thus no new bookings can be made (existing ones will still be honored).
    // This is useful if the car needs maintanance or if the renting service is no longer available.
    function setBookingInactive(bool _deactivateBooking) external {
        require(msg.sender == owner, "Only owner can deactivate booking");
        bookingDisabled = _deactivateBooking;
    }

    // Allows anyone to rent the car. (As long as booking is activated)
    function rentCar(uint8 hoursToRent, uint256 commitment) external payable {
        require(!bookingActive(), "Car is already booked");
        require(!bookingDisabled, "Bookings are currently disabled");
        require(hoursToRent > 0, "Rental duration must be at least one hour");
        uint256 _rentalCost = hoursToRent * costPerHour;
        require(msg.value >= _rentalCost, "Insufficient payment");
        
        renter = msg.sender;
        startTime = block.timestamp;
        endTime = block.timestamp + hoursToRent * 1 hours;
        bookingCommitment = commitment;
        
        // Return the excess funds to the renter if they overpaid
        (bool _success, ) = msg.sender.call{value: msg.value - _rentalCost}("");
        require(_success, "Failed to refund excess payment");
    }

    function roundDownToHour(uint256 timestamp) private pure returns (uint256) {
        return timestamp - (timestamp % 1 hours);
    }

    function calculateRemainingHours() public view returns (uint256) {
        uint256 _currentTime = block.timestamp;
        uint256 _elapsedTime = _currentTime - startTime;
        uint256 _originalBookingTime = endTime - startTime;
        if (_originalBookingTime < _elapsedTime) {
            return 0;
        }
        uint256 _remainingTime = _originalBookingTime - _elapsedTime;
        return roundDownToHour(_remainingTime) / 1 hours; // Return remaining hours

    }

    // Lets renter return the car early and get a refund for the remaining time.
    // (Rounds up to the next hour; so if they begin an hour, they still pay the full hour)
    function returnCarEarly() external {
        require(msg.sender == renter, "Only renter can return the car");
        require(bookingActive(), "Rental period has ended");
        uint256 _remainingHours = calculateRemainingHours();
        uint256 _remainingFundsForCurrentBooking = _remainingHours * costPerHour;
        
        // How high the refund is for the renter
        uint256 _refundAmount = _remainingFundsForCurrentBooking;
        (bool _success, ) = msg.sender.call{value: _refundAmount}("");
        require(_success, "Refund failed");

        uint256 _currentTime = block.timestamp;
        endTime = _currentTime; // Update end time to current time
    }

    // Checks if a booking is currently active.
    function bookingActive() public view returns (bool) {
        uint256 _currentTime = block.timestamp;
        bool _bookingStarted  = _currentTime >= startTime;
        bool _bookingEnded = _currentTime > endTime;
        return _bookingStarted && !_bookingEnded;
    }

    // This is used to access the car.
    // Verify access using zk-SNARK proof.
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
