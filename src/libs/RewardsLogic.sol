// SPDX-License-Identifier: MTT
pragma solidity 0.8.26;

import {Deposit} from "../vault/Vault.sol";
/**
 * @title RewardsLogic
 * @author 0xkmmm
 * @notice Logic is moved into separate library to easiliy test/mantain the logic for calculating rewards
 */

library RewardsLogic {
    uint256 constant SECONDS_PER_YEAR = 365 * 24 * 60 * 60;

    function getPendingRewards(Deposit memory deposit, uint256 _yearlyEmissionRate, uint256 _totalDepositedAmount)
        internal
        view
        returns (uint160)
    {
        uint32 elapsedTime = _getDepositElapsedTime(deposit.depositedAt, deposit.lockedFor);

        uint256 currentDepositEmittedTokens = (_yearlyEmissionRate * elapsedTime) / SECONDS_PER_YEAR;
        uint256 totalReward = (deposit.amount * currentDepositEmittedTokens) / _totalDepositedAmount;

        uint256 claimableReward = totalReward - deposit.claimedAmount;
        return uint160(claimableReward);
    }

    function _getDepositElapsedTime(uint32 _depositedAt, uint32 _lockedFor) internal view returns (uint32) {
        uint32 elapsedTime = uint32(block.timestamp) - _depositedAt;
        uint32 totalLockTime = _lockedFor;

        return elapsedTime >= totalLockTime ? totalLockTime : elapsedTime;
    }

    function rewardMultiplier(uint256 _lockTime) internal pure returns (uint8) {
        if (_lockTime == 180 days) return 1;
        else if (_lockTime == 365 days) return 2;
        else if (_lockTime == 730 days) return 4;
        else if (_lockTime == 1460 days) return 8;
        else return 0;
    }
}
