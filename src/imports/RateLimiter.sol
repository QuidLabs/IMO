// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract RateLimiter {
    struct RateLimit {
        uint256 amountInFlight;
        uint256 lastUpdated;
        uint256 limit;
        uint256 window;
    }

    struct RateLimitConfig {
        uint32 dstEid;
        uint256 limit;
        uint256 window;
    }

    mapping(uint32 dstEid => RateLimit limit) public rateLimits;

    event RateLimitsChanged(RateLimitConfig[] rateLimitConfigs);

    error RateLimitExceeded();

    function getAmountCanBeSent(
        uint32 _dstEid
    ) external view returns (uint256 currentAmountInFlight, uint256 amountCanBeSent) {
        RateLimit memory rl = rateLimits[_dstEid];
        return _amountCanBeSent(rl.amountInFlight, rl.lastUpdated, rl.limit, rl.window);
    }

    function _setRateLimits(RateLimitConfig[] memory _rateLimitConfigs) internal {
        unchecked {
            for (uint256 i = 0; i < _rateLimitConfigs.length; i++) {
                RateLimit storage rl = rateLimits[_rateLimitConfigs[i].dstEid];

                // @dev does NOT reset the amountInFlight/lastUpdated of an existing rate limit
                rl.limit = _rateLimitConfigs[i].limit;
                rl.window = _rateLimitConfigs[i].window;
            }
        }
        emit RateLimitsChanged(_rateLimitConfigs);
    }

    function _amountCanBeSent(
        uint256 _amountInFlight,
        uint256 _lastUpdated,
        uint256 _limit,
        uint256 _window
    ) internal view returns (uint256 currentAmountInFlight, uint256 amountCanBeSent) {
        uint256 timeSinceLastDeposit = block.timestamp - _lastUpdated;

        if (timeSinceLastDeposit >= _window) {
            currentAmountInFlight = 0;
            amountCanBeSent = _limit;
        } else {
            // @dev presumes linear decay
            uint256 decay = (_limit * timeSinceLastDeposit) / _window;
            currentAmountInFlight = _amountInFlight <= decay ? 0 : _amountInFlight - decay;
            // @dev in the event the _limit is lowered, and the 'in-flight' amount is higher than the _limit, set to 0
            amountCanBeSent = _limit <= currentAmountInFlight ? 0 : _limit - currentAmountInFlight;
        }
    }

    function _checkAndUpdateRateLimit(uint32 _dstEid, uint256 _amount) internal {
        // @dev by default dstEid that have not been explicitly set will return amountCanBeSent == 0
        RateLimit storage rl = rateLimits[_dstEid];

        (uint256 currentAmountInFlight, uint256 amountCanBeSent) = _amountCanBeSent(
            rl.amountInFlight,
            rl.lastUpdated,
            rl.limit,
            rl.window
        );
        if (_amount > amountCanBeSent) revert RateLimitExceeded();

        // update the storage to contain the new amount and current timestamp
        rl.amountInFlight = currentAmountInFlight + _amount;
        rl.lastUpdated = block.timestamp;
    }
}
