// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

contract RentalCar {
  address public rented_by = address(0);
  uint public time_of_booking = 0;
  uint public booked_hours = 0;
  mapping(address => uint) public refunds; 
  uint constant HOUR_IN_SEC = 60*60;
  uint constant MAX_BOOKING_TIME = 5 * 24; // Maximum hours of continuous booking
  uint constant COST_PER_HOUR = 1 ether; // THIS SHOULD NEVER BE ZERO
  uint constant MINIMUM_RENTING_COST = COST_PER_HOUR;

  function get_end_of_booking() internal view returns(uint) {
    return time_of_booking + booked_hours*HOUR_IN_SEC;
  }

  function is_booking_active() internal view returns(bool) {
    uint _estimated_curr_time = block.timestamp;
    bool _booking_started = _estimated_curr_time >= time_of_booking;
    bool _still_booked = _estimated_curr_time <= get_end_of_booking();
    return _booking_started && _still_booked;
  }

  function get_remaining_hours() internal view returns(uint) {
    uint _estimated_curr_time = block.timestamp;
    uint _remaining_seconds = get_end_of_booking() - _estimated_curr_time;
    uint _remaining_hours = safe_divide(_remaining_seconds, HOUR_IN_SEC);
    return _remaining_hours;
  }

  function free_up_car() internal is_booked {
    booked_hours = 0;
  }

  modifier is_available() {
    require(!is_booking_active(), "Car currently booked");
    _;
  }

  modifier is_booked() {
    require(is_booking_active(), "Car is currently unbooked");
    _;
  }

  modifier currently_rented_by_sender() {
    require(msg.sender == rented_by, "Car not booked by you");
    _;
  }

  modifier covers_cost() {
    require(msg.value >= MINIMUM_RENTING_COST, "Provided ETH do not cover the minimum time/cost");
    _;
  }

  function safe_divide(uint a, uint b) pure private returns(uint) {
    require(b != 0, "Division by zero was attempted");
    return a / b;
  }

  // Depending on the amount of ETH spent, the booking 
  function rent_car() payable public is_available covers_cost {
    uint _booking_time = safe_divide(msg.value, COST_PER_HOUR);
    require(_booking_time <= MAX_BOOKING_TIME, "The maximum booking time was exceeded");

    uint _estimated_curr_time = block.timestamp;
    time_of_booking = _estimated_curr_time;
    booked_hours = _booking_time;

    // User might not have sent a full multiple of the hourly fee.
    // As we do not allow for booking of smaller time intervals, we just refund the rest later.
    uint _refunded_amount = msg.value - _booking_time*COST_PER_HOUR;
    refunds[msg.sender] += _refunded_amount;
    rented_by = msg.sender;
  }

  function return_car() public is_booked currently_rented_by_sender {
    uint _returned_funds = get_remaining_hours() * COST_PER_HOUR;
    refunds[msg.sender] += _returned_funds;
    free_up_car();
  }

  function request_refund() public {
    uint _refund_amount = refunds[msg.sender];
    refunds[msg.sender] = 0;
    (bool send_success, ) = msg.sender.call{value: _refund_amount}("");
    require(send_success, "Refunding failed");
  }
}