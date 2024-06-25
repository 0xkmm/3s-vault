// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import {Params} from "../src/Params.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {LZEndpointMock} from "../src/mocks/lz/LZEndpointMock.sol";

import {ChainId} from "../src/libs/ChainId.sol";

contract Config is Params {
    uint256 FOUNDRY_LOCAL_CHAINID = 31337;
    uint256 ETHEREUM_MAINNET_CHAINID = 1;
    uint256 ETH_SEPOLIA_MAINNET_CHAINID = 11155111;
    uint256 ARBITRUM_MAINNET_CHAINID = 42161;

    function config() public returns (address lzEndpoint) {
        uint16 chainId = ChainId.get();

        if (chainId == ETHEREUM_MAINNET_CHAINID) {} else if (chainId == ARBITRUM_MAINNET_CHAINID) {} else if (
            chainId == ETH_SEPOLIA_MAINNET_CHAINID
        ) {} else if (chainId == FOUNDRY_LOCAL_CHAINID) {
            lzEndpoint = address(new LZEndpointMock(chainId));
        }
    }
}
