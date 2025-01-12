// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPaymaster, ExecutionResult, PAYMASTER_VALIDATION_SUCCESS_MAGIC} from "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymaster.sol";
import {IPaymasterFlow} from "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymasterFlow.sol";
import {TransactionHelper, Transaction} from "@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol";

import "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract WitsPaymaster is IPaymaster, Ownable {
    // State Variables
    uint256 public balanceMinThreshold;
    mapping (address => bool) public allowedTargets;

    // Events
    event TargetAdded(address indexed target);
    event TargetRemoved(address indexed target);
    event Deposited(address indexed depositor, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed to, uint256 amount);
    event NotifyLowBalance(uint256 balance);
    event BalanceMinThresholdSet(uint256 threshold);

    // Errors
    error ZeroAddress();
    error TargetAlreadyAllowed();
    error TargetNotAllowed();
    error OnlyBootloader();
    error InvalidPaymasterInput();
    error UnsupportedPaymasterFlow();
    error InsufficientBalance();
    error WithdrawFailed();

    // Modifiers
    modifier onlyAllowedTarget(address target) {
        _checkAllowedTarget(target);
        _;
    }

    modifier onlyBootloader() {
        if(msg.sender != BOOTLOADER_FORMAL_ADDRESS) revert OnlyBootloader();
        // Continue execution if called from the bootloader.
        _;
    }

    // Constructor
    constructor(address initialOwner) Ownable(initialOwner) {}

    // Owner only functions
    function setBalanceMinThreshold(uint256 _threshold) external onlyOwner {
        balanceMinThreshold = _threshold;
        emit BalanceMinThresholdSet(_threshold);
    }

    function addAllowedTarget(address target) external onlyOwner {
        if(target == address(0)) revert ZeroAddress();
        if(allowedTargets[target]) revert TargetAlreadyAllowed();
        allowedTargets[target] = true;
        emit TargetAdded(target);
    }

    function removeAllowedTarget(address target) external onlyOwner {
        if(target == address(0)) revert ZeroAddress();
        if(!allowedTargets[target]) revert TargetNotAllowed();
        allowedTargets[target] = false;
        emit TargetRemoved(target);
    }

    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        (bool success, ) = _to.call{value: _amount}("");
        if(!success) revert WithdrawFailed();
        emit Withdrawn(_to, _amount);
    }

    // External functions
    function deposit() public payable {
        uint256 newBalance = address(this).balance;
        emit Deposited(msg.sender, msg.value, newBalance);
    }

    function validateAndPayForPaymasterTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    )
        external
        payable
        onlyBootloader
        onlyAllowedTarget(address(uint160(_transaction.to)))
        returns (bytes4 magic, bytes memory context)
    {
        // By default we consider the transaction as accepted.
        magic = PAYMASTER_VALIDATION_SUCCESS_MAGIC;
        if(_transaction.paymasterInput.length < 4) revert InvalidPaymasterInput();

        bytes4 paymasterInputSelector = bytes4(
            _transaction.paymasterInput[0:4]
        );
        if (paymasterInputSelector == IPaymasterFlow.general.selector) {
            // Note, that while the minimal amount of ETH needed is tx.gasPrice * tx.gasLimit,
            // neither paymaster nor account are allowed to access this context variable.
            uint256 requiredETH = _transaction.gasLimit *
                _transaction.maxFeePerGas;

            // The bootloader never returns any data, so it can safely be ignored here.
            (bool success, ) = payable(BOOTLOADER_FORMAL_ADDRESS).call{
                value: requiredETH
            }("");
            if(!success) revert InsufficientBalance();
            _checkBalanceAndNotify();
        } else {
            revert UnsupportedPaymasterFlow();
        }
    }

    function postTransaction(
        bytes calldata _context,
        Transaction calldata _transaction,
        bytes32,
        bytes32,
        ExecutionResult _txResult,
        uint256 _maxRefundedGas
    ) external payable override onlyBootloader {}

    receive() external payable {
        deposit();
    }

    // Internal functions
    function _checkAllowedTarget(address target) internal view {
        if (!allowedTargets[target]) revert TargetNotAllowed();
    }

    function _checkBalanceAndNotify() internal {
        if(address(this).balance < balanceMinThreshold) emit NotifyLowBalance(address(this).balance);
    }
}