// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {RateLimiter} from "./RateLimiter.sol";
import { OFT } from "./OFT.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 *
 * @dev Manually copied/composed over from OZ5 due to inheritance constraints from OFT standards
 */
abstract contract OFTOwnable2Step 
    is OFT, RateLimiter {
    address private _pendingOwner;
    address public rateLimiter;

    // Event emitted when the rate limiter is set
    event RateLimiterSet(address indexed rateLimiter);
    // Error to be thrown when 
    // only the rate limiter is 
    // allowed to perform an action
    error OnlyRateLimiter();
    
    // @dev custom error for no renounce ownership
    error CantRenounceOwnership();

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    // @dev Route through the constructor args
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {}

    /**
     * @dev Sets the rate limiter contract address. Only callable by the owner.
     * @param _rateLimiter Address of the rate limiter contract.
     */
    function setRateLimiter(address _rateLimiter) external onlyOwner {
        rateLimiter = _rateLimiter;
        emit RateLimiterSet(_rateLimiter);
    }
    /**
     * @dev Sets the rate limits based on RateLimitConfig array. Only callable by the owner or the rate limiter.
     * @param _rateLimitConfigs An array of RateLimitConfig structures defining the rate limits.
     */
    function setRateLimits(RateLimitConfig[] calldata _rateLimitConfigs) external {
        if (msg.sender != rateLimiter && msg.sender != owner()) revert OnlyRateLimiter();
        _setRateLimits(_rateLimitConfigs);
    }

    /**
     * @dev Checks and updates the rate limit before initiating a token transfer.
     * @param _amountLD The amount of tokens to be transferred.
     * @param _minAmountLD The minimum amount of tokens expected to be received.
     * @param _dstEid The destination endpoint identifier.
     * @return amountSentLD The actual amount of tokens sent.
     * @return amountReceivedLD The actual amount of tokens received.
     */
    function _debit(
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        _checkAndUpdateRateLimit(_dstEid, _amountLD);
        return super._debit(_amountLD, _minAmountLD, _dstEid);
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }

    // @dev Overrides the renounceOwnership function to prevent renouncing ownership
    function renounceOwnership() public view override onlyOwner {
        revert CantRenounceOwnership();
    }
}
