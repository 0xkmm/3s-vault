// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Vault} from "../src/vault/Vault.sol";
import {VaultToken} from "../src/oft/VaultToken.sol";
import {Config} from "./Config.sol";

import {Script} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployVault is Script, Config {
    function run() public returns (Vault vault, VaultToken token) {
        return deploy(msg.sender);
    }

    function deploy(address _owner) public returns (Vault vault, VaultToken token) {
        address lpToken = address(0);

        (address layerZeroEndpoint) = config();

        address impl = address(new Vault());
        address vaultProxy = address(new ERC1967Proxy(impl, ""));

        token = new VaultToken("3S-OFT", "3S", layerZeroEndpoint, _owner, address(vaultProxy));
        vault = Vault(vaultProxy);

        vault.initialize(lpToken, address(token));
    }
}
