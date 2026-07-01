// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../contracts/RentalCar.sol";
import "../contracts/Verifier.sol";

contract RentalCar_FunctionalityTest {

    RentalCar carToTest;
    Groth16Verifier verifier;
    uint256 constant commitment = 0;

    function beforeEach () public {
        verifier = new Groth16Verifier();
        carToTest = new RentalCar(address(verifier));
    }

    /// #value: 5000000000000000000
    function renting_returning_refunding_works () public payable {
        // Renting the car
        carToTest.rentCar{value: 3 ether}(2, commitment); // Pay for more than one hour (so we can get the rest refunded)
        address _curr_booked_by = carToTest.renter();
        Assert.equal(_curr_booked_by, address(this), "Renting the car should result in the sender being the registered 'booker'");
        
        // Returning the car
        carToTest.returnCarEarly(); // We should be refunded at least some of the ether we spent
        uint _refundable_eth = carToTest.refunds(address(this));
        Assert.ok(_refundable_eth > 0, "Some ETH should have been refunded");

        // Requesting refund
        uint _balance_before_refund = address(this).balance;
        carToTest.requestRefund();
        uint _balance_after_refund = address(this).balance;
        Assert.ok(_balance_after_refund > _balance_before_refund, "Balance should have increased after refund");
    }

    // Just for refunding purposes
    receive() external payable { }
    fallback() external payable { }
}