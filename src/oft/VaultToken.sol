// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VaultToken
 * @author 0xkmmm
 * @notice Description of the contract
 */
contract VaultToken is OFT {
    ///@dev -> The address of the vault
    address public immutable vault;

    /////// CONSTRUCTOR ///////

    constructor(string memory _name, string memory _symbol, address _layerZeroEndpoint, address _owner, address _vault)
        OFT(_name, _symbol, _layerZeroEndpoint, _owner)
        Ownable(_owner)
    {
        vault = _vault;
    }

    /////// ERRORS ///////

    error OnlyVaultAllowed();

    ///@notice Prevents anyone else from minting
    modifier onlyVault() {
        _checkOnlyVault();
        _;
    }

    /////// EXTERNAl ///////

    ///@dev Mints an amount of tokens to a recipient
    ///@notice This can only be called through the vault
    function mint(address _to, uint256 _amount) external onlyVault {
        _mint(_to, _amount);
    }

    /////// INTERNAL ///////

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method
    function _checkOnlyVault() internal view {
        if (msg.sender != vault) revert OnlyVaultAllowed();
    }
}
