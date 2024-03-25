// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title A Dex Bank
/// @author tausedzaman
/// @notice This contract is used as a bank
/// @dev We have a bank contract where users can deposit,and withdraw there balance, transactoin fee is cut for each transaction, for deposit as well as withdraw. then we allow owner to set settings of the contract like min,max transaction amount, bank name etc, also owner can make transaction from the bank balance. also owner can ban users/address from the contract so they will be not able to withdraw or deposit...

contract Bank {
    // fee for deposit and withdraw transactions for users in percentage..
    uint256 private TRANSACTION_FEE = 2; // in %

    // min and max allowed amount of eth allowed in wei
    uint256 private LOWER_LIMIT = 1000; // 1000 wei
    uint256 private UPPER_LIMIT = 10000000000000000000; // 10 eth
    string public bank_name;
    address public owner;

    event transactionLog(
        address indexed sender,
        address indexed reciver,
        uint256 amount
    );

    //
    event BannedLog(address indexed wallet, bool status);

    mapping(address => uint256) public balances;
    address[] public banned_list;

    // modifier that will check if the sender is not banned if banned then revert
    modifier isBanned() {
        bool Banned = false;
        for (uint256 i = 0; i < banned_list.length; i++) {
            if (banned_list[i] == msg.sender) {
                Banned = true;
                break;
            }
        }
        require(!Banned, "You are banned from using this service.");
        _;
    }

    // only owner can change settings and make transaction from the bank balance
    modifier onlyOwner() {
        require(msg.sender == owner, "Unatherized action..");
        _;
    }

    // check min and max limits before deposit and withdraw
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

    // we allow users to send and recive founds from the contract address that why i added these methods
    receive() external payable {}

    fallback() external payable {}

    // method for the owner to change the bannk name
    function set_bank_name(string memory _name)
        public
        onlyOwner
        returns (string memory)
    {
        bank_name = _name;
        return bank_name;
    }

    // allow owner to set min and max limits for transactions
    function set_min_limit(uint256 _amount) public payable onlyOwner {
        LOWER_LIMIT = _amount;
    }

    function set_max_limit(uint256 _amount) public payable onlyOwner {
        UPPER_LIMIT = _amount;
    }

    // allow admin to bann and unban user
    function ban_user(address _address) public payable onlyOwner {
        banned_list.push(_address);
        emit BannedLog(_address, true);
    }

    function unban_user(address _address) public payable onlyOwner {
        for (uint256 i = 0; i < banned_list.length; i++) {
            // if auth address is in the banned list then remove it
            if (banned_list[i] == _address) {
                banned_list[i] = banned_list[banned_list.length - 1];
                banned_list.pop();
                emit BannedLog(_address, false);
                break;
            }
        }
    }

    // users can deposit founds to the bank after differents check passed in modifiers
    function deposit() public payable isBanned IsValidAmount returns (uint256) {
        require(msg.value > 0, "Invalid Amount.");

        // send founds to contract, and cut the fee and add the rest of the founds to user balance
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

    // allowing owner to tranfer founds from bank contract to recivers
    function transfer_bank_balance(address payable _reciver, uint256 amount)
        public
        payable
        onlyOwner
    {
        require(
            address(this).balance > amount,
            "Bank dont have enough balance"
        );
        _reciver.transfer(amount);
        emit transactionLog(msg.sender, _reciver, msg.value);
    }

    // allowing users to withdraw fouds after checks
    function withdraw(address payable _reciver)
        public
        payable
        validateTransaction(_reciver)
        isBanned
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
