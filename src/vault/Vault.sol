// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VaultToken} from "../oft/VaultToken.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {RewardsLogic} from "../libs/RewardsLogic.sol";

struct Deposit {
    ///@dev -> The address of the user who initiated a deposit
    address depositor;
    ///@dev -> The amount of LP tokens deposited
    uint160 amount;
    ///@dev -> The already claimed amount of the deposit
    uint160 claimedAmount;
    ///@dev -> The duration for the locked tokens
    uint32 lockedFor;
    ///@dev -> The time at which the user deposited
    uint32 depositedAt;
}

/**
 * @title Vault
 * @author 0xkmm
 * @notice This is the main entrance
 */
contract Vault is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /////// STATE ///////

    ///@dev Storage gap just in case we decide to inherit from a contract with state
    uint256[50] gap;

    IERC20 lpToken;
    VaultToken public oftToken;

    uint32 lastId;
    uint160 totalDepositedAmount;
    mapping(uint32 id => Deposit deposit) deposits;

    /////// ERRORS ///////

    error NotDepositor();
    error AmountMustBeGreaterThanZero();
    error InvalidLockTime();
    error InsufficientClaimAmount();

    /////// EVENTS ///////

    /////// CONTRUCTOR/INITIALIZER ///////

    constructor() {
        _disableInitializers();
    }

    function initialize(address _lpToken, address _oftToken) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        oftToken = VaultToken(_oftToken);
        lpToken = IERC20(_lpToken);
    }

    /////// MODIFIERS ///////

    modifier onlyDepositOwner(uint32 _id) {
        if (!_isDepositor(_id)) revert NotDepositor();
        _;
    }

    ///////  EXTERNAL ///////

    function deposit(uint160 _amount, uint32 _lockFor) external {
        if (_gt0(_amount)) revert AmountMustBeGreaterThanZero();

        uint8 rewardMultiplier = RewardsLogic.rewardMultiplier(_lockFor);

        if (!_gt0(rewardMultiplier)) revert InvalidLockTime();

        Deposit storage currDeposit = deposits[++lastId];

        uint160 adjustedDeposit = _amount * rewardMultiplier;

        currDeposit.depositor = msg.sender;
        currDeposit.depositedAt = uint32(block.timestamp);
        currDeposit.lockedFor = _lockFor;

        currDeposit.amount = adjustedDeposit;
        totalDepositedAmount += adjustedDeposit;

        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function claim(uint32 _id) external onlyDepositOwner(_id) {
        Deposit memory currDeposit = deposits[_id];
        uint160 availableClaimAmount =
            RewardsLogic.getPendingRewards(currDeposit, oftToken.YEARLY_EMISSION_RATE(), totalDepositedAmount);

        if (!_gt0(availableClaimAmount)) revert InsufficientClaimAmount();

        deposits[_id].claimedAmount += availableClaimAmount;

        oftToken.mint(msg.sender, availableClaimAmount);
    }

    /////// INTERNAL ///////

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method
    function _isDepositor(uint32 _id) internal view returns (bool) {
        return deposits[_id].depositor == msg.sender;
    }

    function _gt0(uint256 number) internal pure returns (bool) {
        return number > 0;
    }
}
