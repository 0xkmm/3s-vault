// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/* == System == */
import {VaultToken} from "../oft/VaultToken.sol";

/* == Interfaces == */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* == OZ == */
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* == Libraries == */
import {RewardsLogic} from "../libs/RewardsLogic.sol";
import {Uint32, Uint64, Uint160} from "../libs/SafeCast.sol";

/**
 * @title Vault
 * @author 0xkmmm
 * @notice This contract manages deposits of Uniswap LP tokens, locks them for a period, and distributes rewards.
 * @dev This contract uses UUPS upgradeability and is Ownable.
 */
contract Vault is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Struct representing a deposit
    /// @dev - This struct is packed to be exactly 32 bytes - 128 + 24 + 32 + 74 = 256 / 8 = 32
    struct Deposit {
        /// @dev The amount of LP tokens deposited
        uint128 amount;
        /// @dev The duration for the locked tokens
        uint24 lockedFor;
        /// @dev The time at which the user deposited
        uint32 depositedAt;
        /// @dev The reward debt for the deposit
        uint72 rewardDebt;
    }

    /* ====== STATE ====== */

    /// @dev Storage gap in case we want to upgrade and inherit from a contract with state
    uint256[50] private __gap;

    /// @notice The LP token accepted by the vault
    IERC20 public lpToken;

    /// @notice The reward token distributed by the vault
    VaultToken public oftToken;

    /// @notice The last update time of the rewards
    uint32 public lastUpdateTime;

    /// @notice The accumulated rewards per share
    uint160 public rewardsPerShare;

    /// @notice The total rewards accumulated
    uint160 public totalRewards;

    /// @notice The first active deposit ID
    uint32 public firstActiveId;

    /// @notice The total shares in the vault
    uint160 public totalLockedLPs;

    /// @notice The pro rata shares
    uint160 public proRataShares;

    /// @notice The accumulated reward per share
    uint160 public accRewardPerShare;

    /// @notice Mapping of deposit IDs to Deposit structs
    mapping(address => Deposit[]) public deposits;

    /* ====== ERRORS ====== */

    error AmountMustBeGreaterThanZero();
    error InvalidLockTime();
    error InsufficientClaimAmount();
    error LockPeriodNotEnded();

    /* ====== EVENTS ====== */

    /// @notice Event emitted when LP tokens are deposited
    /// @param user The address of the user
    /// @param amount The amount of LP tokens deposited
    /// @param lockEnd The time at which the lock period ends
    /// @param multiplier The reward multiplier for the deposit
    event DepositLP(address indexed user, uint160 amount, uint32 lockEnd, uint256 multiplier);

    /// @notice Event emitted when rewards are claimed
    /// @param user The address of the user
    /// @param depositId The ID of the deposit
    /// @param amount The amount of rewards claimed
    event ClaimReward(address indexed user, uint32 depositId, uint160 amount);

    /// @notice Event emitted when LP tokens are withdrawn
    /// @param user The address of the user
    /// @param depositId The ID of the deposit
    /// @param amount The amount of LP tokens withdrawn
    event WithdrawLP(address indexed user, uint32 depositId, uint160 amount);

    /* ====== INITIALIZER/CONSTRUCTOR ====== */

    /// @notice Initializes the contract by disabling initializers
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the vault contract
     * @param _lpToken The address of the LP token
     * @param _oftToken The address of the reward token
     */
    function initialize(address _lpToken, address _oftToken) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        oftToken = VaultToken(_oftToken);
        lpToken = IERC20(_lpToken);
    }

    /* ====== MODIFIERS ====== */

    modifier updatePool() {
        _updatePool();
        _;
    }

    /* ====== EXTERNAL ====== */

    /**
     * @notice Deposits LP tokens into the vault
     * @param _amount The amount of LP tokens to deposit
     * @param _lockFor The duration for which the tokens will be locked
     */
    function deposit(uint128 _amount, uint24 _lockFor) external updatePool {
        if (_amount <= 0) revert AmountMustBeGreaterThanZero();

        uint8 multiplier = RewardsLogic.rewardMultiplier(_lockFor);
        if (multiplier == 0) revert InvalidLockTime();

        uint128 adjustedAmount = _amount * multiplier;

        deposits[msg.sender].push(
            Deposit({
                amount: adjustedAmount,
                lockedFor: _lockFor,
                depositedAt: Uint32(block.timestamp),
                rewardDebt: Uint64((_amount * accRewardPerShare / 1e12))
            })
        );

        emit DepositLP(msg.sender, _amount, uint32(block.timestamp) + _lockFor, multiplier);

        totalLockedLPs += adjustedAmount;

        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Claims rewards for a specific deposit
     * @param _id The ID of the deposit
     */
    function claim(uint32 _id) external updatePool {
        _claim(_id);
    }

    /**
     * @notice Withdraws LP tokens and claims rewards
     * @param _id The ID of the deposit
     */
    function withdraw(uint32 _id) external updatePool {
        Deposit storage userDeposit = deposits[_id];
        if (userDeposit.depositedAt + userDeposit.lockedFor > block.timestamp) revert LockPeriodNotEnded();

        _claim(_id);

        lpToken.transfer(msg.sender, userDeposit.amount);
        totalLockedLPs -= userDeposit.amount;

        emit WithdrawLP(msg.sender, _id, userDeposit.amount);

        delete deposits[_id];
    }

    /* ====== INTERNAL/PRIVATE ===== */

    /// @dev Updates the reward pool
    function _updatePool() internal {
        if (block.timestamp <= lastUpdateTime) {
            return;
        }
        if (totalLockedLPs == 0) {
            lastUpdateTime = uint32(block.timestamp);
            return;
        }

        uint256 multiplier = block.timestamp - lastUpdateTime;
        uint256 reward = multiplier * oftToken.YEARLY_EMISSION_RATE();
        accRewardPerShare += Uint160(reward / totalLockedLPs);
        lastUpdateTime = Uint32(block.timestamp);
    }

    /**
     * @dev Authorizes the upgrade of the contract
     * @param newImplementation The address of the new implementation
     * @notice Only the owner can upgrade the implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Private function to handle claims
     * @param _user The user which we are claiming for
     */
    function _claim(address _user) private {
        // Deposit[] storage userDeposits = deposits[_user];

        // uint160 pending = uint160(userDeposit.amount * accRewardPerShare / 1e12) - userDeposit.rewardDebt;
        // if (pending > 0) {
        //     oftToken.mint(msg.sender, pending);
        //     userDeposit.rewardDebt = uint64(userDeposit.amount * accRewardPerShare / 1e12);

        //     emit ClaimReward(msg.sender, _id, pending);
        // }
    }
}
