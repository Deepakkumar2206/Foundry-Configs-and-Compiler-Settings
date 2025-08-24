// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Minimal MultiSig Wallet
/// @notice Owners submit, confirm and execute transactions once enough confirmations are collected.
contract Wallet {
    event Submit(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event Confirm(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required; // confirmations needed

    struct Tx {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmCount;
    }

    Tx[] public transactions;
    // txId => owner => confirmed?
    mapping(uint256 => mapping(address => bool)) public confirmations;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "NOT_OWNER");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "TX_DOES_NOT_EXIST");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "ALREADY_EXECUTED");
        _;
    }

    modifier notConfirmed(uint256 _txId) {
        require(!confirmations[_txId][msg.sender], "ALREADY_CONFIRMED");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "NO_OWNERS");
        require(_required > 0 && _required <= _owners.length, "BAD_REQUIRED");

        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "ZERO_OWNER");
            require(!isOwner[owner], "DUP_OWNER");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    function submit(address _to, uint256 _value, bytes calldata _data) external onlyOwner returns (uint256 txId) {
        txId = transactions.length;
        transactions.push(Tx({to: _to, value: _value, data: _data, executed: false, confirmCount: 0}));
        emit Submit(txId, _to, _value, _data);
    }

    function confirm(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notConfirmed(_txId) {
        confirmations[_txId][msg.sender] = true;
        transactions[_txId].confirmCount += 1;
        emit Confirm(msg.sender, _txId);
    }

    function revoke(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(confirmations[_txId][msg.sender], "NOT_CONFIRMED");
        confirmations[_txId][msg.sender] = false;
        transactions[_txId].confirmCount -= 1;
        emit Revoke(msg.sender, _txId);
    }

    function execute(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        Tx storage t = transactions[_txId];
        require(t.confirmCount >= required, "NOT_ENOUGH_CONFIRMS");
        t.executed = true;

        (bool ok,) = t.to.call{value: t.value}(t.data);
        require(ok, "CALL_FAILED");
        emit Execute(_txId);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function txCount() external view returns (uint256) {
        return transactions.length;
    }

    receive() external payable {}
}
