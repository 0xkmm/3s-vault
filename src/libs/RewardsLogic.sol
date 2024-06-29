// SPDX-License-Identifier: MTT
pragma solidity 0.8.26;

/**
 * @title RewardsLogic
 * @author 0xkmmm
 * @notice Logic is moved into separate library to easiliy test/mantain the logic for calculating rewards
 */
library RewardsLogic {
    function rewardMultiplier(uint24 _lockTime) internal pure returns (uint8) {
        if (_lockTime == 180 days) return 1;
        else if (_lockTime == 365 days) return 2;
        else if (_lockTime == 730 days) return 4;
        else if (_lockTime == 1460 days) return 8;
        else return 0;
    }
}
