// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title A Dex Bank
/// @author tausedzaman
/// @notice This contract is used as a bank
/// @dev still working this contract

contract Bank {
    uint256 private TRANSACTION_FEE = 2; // in %
    uint256 private LOWER_LIMIT = 1000; // 1000 wei
    uint256 private UPPER_LIMIT = 10000000000000000000; // 10 eth
    string public bank_name;
    address public owner;

    event transactionLog(
        address indexed sender,
        address indexed reciver,
        uint256 amount
    );

    mapping(address => uint256) public balances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unatherized action..");
        _;
    }

    modifier validateTransaction(address payable _receiver) {
        require(msg.sender != _receiver, "You cannot send to yourself.");
        require(msg.value > 0, "Invalid Amount.");
        require(
            msg.value >= LOWER_LIMIT && msg.value <= UPPER_LIMIT,
            "Amount not within limits."
        );
        require(
            balances[msg.sender] >= msg.value,
            "You don't have enough balance."
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function set_bank_name(
        string memory _name
    ) public onlyOwner returns (string memory) {
        bank_name = _name;
        return bank_name;
    }

    function set_min_limit(uint256 _amount) public payable onlyOwner {
        LOWER_LIMIT = _amount;
    }

    function set_max_limit(uint256 _amount) public payable onlyOwner {
        UPPER_LIMIT = _amount;
    }

    function deposit() public payable returns (uint256) {
        require(msg.value > 0, "Invalid Amount.");
        balances[msg.sender] += msg.value;
        return balances[msg.sender];
    }

    function get_balance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function withdraw(
        address payable _reciver
    ) public payable validateTransaction(_reciver) returns (uint256) {
        balances[msg.sender] -= msg.value;
        _reciver.transfer(msg.value);
        balances[_reciver] += msg.value;
        emit transactionLog(msg.sender, _reciver, msg.value);
        return balances[msg.sender];
    }
}
