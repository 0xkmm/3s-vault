// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Vault
 * @author 0xkmm
 * @notice This is the main entrance
 */
contract Vault is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /////// STATE ///////

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

    IERC20 lpToken;
    IERC20 public oftToken;

    uint32 lastId;
    mapping(uint32 id => Deposit deposit) deposits;

    /////// ERRORS ///////

    error NotDepositor();
    error InvalidInput();
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

        oftToken = IERC20(_oftToken);
        lpToken = IERC20(_lpToken);
    }

    /////// MODIFIERS ///////

    modifier onlyDepositOwner(uint32 _id) {
        if (!_isDepositor(_id)) revert NotDepositor();
        _;
    }

    ///////  EXTERNAL ///////

    function deposit(uint160 _amount, uint32 _lockFor) external {
        if (_gt0(_amount)) revert InvalidInput();
        if (!_isValidLockTime(_lockFor)) revert InvalidLockTime();

        Deposit storage currDeposit = deposits[++lastId];

        currDeposit.amount = _amount;
        currDeposit.depositedAt = uint32(block.timestamp);
        currDeposit.lockedFor = _lockFor;

        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function claim(uint32 _id, uint160 _amount) external onlyDepositOwner(_id) {
        if (_gt0(_amount)) revert InvalidInput();

        Deposit storage currDeposit = deposits[_id];

        uint160 availableClaimAmount = _claimableAmount(currDeposit);

        if (_gteq(_amount, availableClaimAmount)) revert InsufficientClaimAmount();

        currDeposit.claimedAmount += _amount;

        //token.mint(msg.sender, _amount)
    }

    function _claimableAmount(Deposit storage deposit) internal returns (uint160) {}

    /////// INTERNAL ///////

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method
    function _isDepositor(uint32 _id) internal view returns (bool) {
        return deposits[_id].depositor == msg.sender;
    }

    function _gt0(uint256 number) internal pure returns (bool) {
        return number > 0;
    }

    function _gteq(uint256 num1, uint256 num2) internal pure returns (bool) {
        return num1 >= num2;
    }

    function _isValidLockTime(uint32 _lockTime) internal pure returns (bool) {
        return _lockTime == 180 days || _lockTime == 365 days || _lockTime == 730 days || _lockTime == 1460 days;
    }
}
