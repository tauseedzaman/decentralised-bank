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
    event BannedLog(address indexed wallet, bool status);

    mapping(address => uint256) public balances;
    address[] public banned_list;

    modifier notBanned() {
        bool isBanned = false;
        for (uint256 i = 0; i < banned_list.length; i++) {
            if (banned_list[i] == msg.sender) {
                isBanned = true;
                break;
            }
        }
        require(isBanned, "You are banned from using this service.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unatherized action..");
        _;
    }

    modifier IsValidAmount() {
        // check limits
        require(msg.value > 0, "Invalid Amount.");
        require(
            msg.value >= LOWER_LIMIT && msg.value <= UPPER_LIMIT,
            "Amount not within limits."
        );
        _;
    }

    modifier validateTransaction(address payable _receiver) {
        require(msg.sender != _receiver, "You cannot send to yourself.");

        // check if current balance is wallet
        require(
            balances[msg.sender] >= msg.value,
            "You don't have enough balance."
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    fallback() external payable {}

    function set_bank_name(string memory _name)
        public
        onlyOwner
        returns (string memory)
    {
        bank_name = _name;
        return bank_name;
    }

    function set_min_limit(uint256 _amount) public payable onlyOwner {
        LOWER_LIMIT = _amount;
    }

    function set_max_limit(uint256 _amount) public payable onlyOwner {
        UPPER_LIMIT = _amount;
    }

    function ban_user(address _address) public payable onlyOwner {
        banned_list.push(_address);
        emit BannedLog(_address, true);
    }

    function unban_user(address _address) public payable onlyOwner {
        for (uint256 i = 0; i < banned_list.length; i++) {
            // if auth address is in the banned list then remove it
            if (banned_list[i] == msg.sender) {
                banned_list[i] = banned_list[banned_list.length - 1];
                banned_list.pop();
                emit BannedLog(_address, false);
                break;
            }
        }
    }

    function deposit()
        public
        payable
        notBanned
        IsValidAmount
        returns (uint256)
    {
        require(msg.value > 0, "Invalid Amount.");

        // cut the fee and send it to owner
        uint256 fee = (msg.value * TRANSACTION_FEE) / 100;
        address payable contractAddress = payable(address(this));

        // send the amount to this contract
        contractAddress.transfer(msg.value);

        // cut the fee and update user balance
        uint256 balance_after_fee = msg.value - fee;
        balances[msg.sender] += balance_after_fee;
        return balances[msg.sender];
    }

    function get_balance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function get_bank_balance() public view returns (uint256) {
        address payable contractAddress = payable(address(this));
        return contractAddress.balance;
    }

    function withdraw(address payable _reciver)
        public
        payable
        validateTransaction(_reciver)
        notBanned
        IsValidAmount
        returns (uint256)
    {
        uint256 fee = (msg.value * TRANSACTION_FEE) / 100;
        uint256 balance_after_fee = msg.value - fee;
        balances[msg.sender] -= balance_after_fee;

        _reciver.transfer(balance_after_fee);

        emit transactionLog(msg.sender, _reciver, msg.value);

        return balances[msg.sender];
    }
}
