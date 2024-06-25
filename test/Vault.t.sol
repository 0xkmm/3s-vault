// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {DeployVault} from "../script/DeployVault.s.sol";
import {Vault} from "../src/vault/Vault.sol";
import {VaultToken} from "../src/oft/VaultToken.sol";

contract VaultTest is Test {
    Vault vault;
    VaultToken token;

    address owner = makeAddr("Owner");

    function setUp() public {
        DeployVault deployer = new DeployVault();

        (vault, token) = deployer.deploy(owner);
    }

    function test_everGreen() public pure {
        assert(true);
    }

    function test_wireUp() public view {
        assert(token.vault() == address(vault));
        assert(address(vault.oftToken()) == address(token));
    }
}
