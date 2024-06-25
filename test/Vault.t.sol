// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {DeployVault} from "../script/DeployVault.s.sol";
import {Vault} from "../src/vault/Vault.sol";
import {VaultToken} from "../src/oft/VaultToken.sol";

contract VaultTest is Test {
    Vault vault;
    VaultToken token;

    function setUp() public {
        DeployVault deployer = new DeployVault();

        (vault, token) = deployer.deploy();
    }

    function test_everGreen() public {
        assert(true);
    }
}
