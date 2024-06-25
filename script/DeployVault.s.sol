// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Vault} from "../src/vault/Vault.sol";
import {VaultToken} from "../src/oft/VaultToken.sol";

import {Script} from "forge-std/Script.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {Config} from "./Config.sol";

contract DeployVault is Script, Config {
    function run() public returns (Vault vault, VaultToken token) {
        return deploy(msg.sender);
    }

    function deploy(address _owner) public returns (Vault vault, VaultToken token) {
        bytes32 salt = keccak256(abi.encodePacked(block.chainid, _owner));

        address lpToken = 0x000;
        address vaultAddress = Create2.computeAddress(salt, type(Vault).creationCode);

        token = new VaultToken("3S-OFT", "3S", 0x00, _owner, vaultAddress);
        vault = Vault(Create2.deploy(salt, type(Vault).creationCode));

        vault.initialize(lpToken, address(token));
    }
}
