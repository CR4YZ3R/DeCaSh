// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../contracts/RentalCar.sol";

contract RentalCar_FunctionalityTest {

    RentalCar carToTest;
    function beforeEach () public {
        carToTest = new RentalCar();
    }

    /// #value: 5000000000000000000
    function renting_returning_refunding_works () public payable {
        // Renting the car
        carToTest.rent_car{value: 3 ether}(); // Pay for more than one hour (so we can get the rest refunded)
        address _curr_booked_by = carToTest.booked_by();
        Assert.equal(_curr_booked_by, address(this), "Renting the car should result in the sender being the registered 'booker'");
        
        // Returning the car
        carToTest.return_car(); // We should be refunded at least some of the ether we spent
        uint _refundable_eth = carToTest.refunds(address(this));
        Assert.ok(_refundable_eth > 0, "Some ETH should have been refunded");

        // Requesting refund
        uint _balance_before_refund = address(this).balance;
        carToTest.request_refund();
        uint _balance_after_refund = address(this).balance;
        Assert.ok(_balance_after_refund > _balance_before_refund, "Balance should have increased after refund");
    }

    // Just for refunding purposes
    receive() external payable { }
    fallback() external payable { }
}