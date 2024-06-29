// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/* == LZ == */
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

/* == OZ == */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VaultToken
 * @author 0xkmmm
 * @notice Description of the contract
 */
contract VaultToken is OFT {
    /* ====== STATE ====== */

    /// @notice The address of the vault allowed to mint tokens
    address public immutable vault;

    /// @notice The yearly emission rate of the token
    uint256 public YEARLY_EMISSION_RATE = 1e10;

    /* ====== ERRORS ====== */

    /// @notice Error thrown when a function is called by an address other than the vault
    error OnlyVaultAllowed();

    /* ====== EVENTS ====== */

    event DistributedTokens(address indexed to, uint256 indexed amount);

    /* ====== CONSTRUCTOR ====== */

    /**
     * @notice Initializes the VaultToken contract
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _layerZeroEndpoint The LayerZero endpoint address
     * @param _owner The owner of the token
     * @param _vault The address of the vault allowed to mint tokens
     */
    constructor(string memory _name, string memory _symbol, address _layerZeroEndpoint, address _owner, address _vault)
        OFT(_name, _symbol, _layerZeroEndpoint, _owner)
        Ownable(_owner)
    {
        vault = _vault;
    }

    /* ====== MODIFIERS ====== */

    /// @notice Modifier to restrict function access to only the vault
    modifier onlyVault() {
        _checkOnlyVault();
        _;
    }

    /* ====== EXTERNAL ====== */

    ///@dev Mints an amount of tokens to a recipient
    ///@notice This can only be called through the vault
    function mint(address _to, uint256 _amount) external onlyVault {
        _mint(_to, _amount);

        emit DistributedTokens(_to, _amount);
    }

    /* ====== INTERNAL ====== */

    /**
     * @notice Checks if the caller is the vault
     * @dev Reverts if the caller is not the vault
     * @dev Private method is used instead of inlining into modifier because modifiers are copied into each method
     */
    function _checkOnlyVault() internal view {
        if (msg.sender != vault) revert OnlyVaultAllowed();
    }
}
