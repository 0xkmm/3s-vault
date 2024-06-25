// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import {Params} from "../src/Params.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract Config is Params {
    uint256 FOUNDRY_LOCAL_CHAINID = 31337;
    uint256 ETHEREUM_MAINNET_CHAINID = 1;
    uint256 ETH_SEPOLIA_MAINNET_CHAINID = 11155111;
    uint256 ARBITRUM_MAINNET_CHAINID = 42161;

    function config()
        public
        returns (
            address _uniswapV2Factory,
            address _uniswapV2Router,
            address _uniswapV3PositionManager,
            address _weth,
            address _quoter
        )
    {
        if (block.chainid == ETHEREUM_MAINNET_CHAINID) {
            _uniswapV2Factory = MAINNET_UNISWAPV2_FACTORY;
            _quoter = MAINNET_UNISWAPV3_QUOTER;
            _uniswapV2Router = MAINNET_UNISWAPV2_ROUTER02;
            _uniswapV3PositionManager = MAINNET_UNISWAPV3_POSITION_MANAGER;
            _weth = MAINNET_WETH;
        } else if (block.chainid == ARBITRUM_MAINNET_CHAINID) {
            _uniswapV2Factory = ARBITRUM_UNISWAPV2_FACTORY;
            _uniswapV2Router = ARBITRUM_UNISWAPV2_ROUTER02;
            _uniswapV3PositionManager = ARBITRUM_UNISWAPV3_POSITION_MANAGER;
            _quoter = ARBITRUM_UNISWAPV3_QUOTER;
            _weth = ARBITRUM_WETH;
        } else if (block.chainid == ETH_SEPOLIA_MAINNET_CHAINID) {
            _uniswapV2Factory = ETH_SEPOLIA_UNISWAPV2_FACTORY;
            _uniswapV2Router = ETH_SEPOLIA_UNISWAPV2_ROUTER02;
            _quoter = ETH_SEPOLIA_UNISWAPV3_QUOTER;
            _uniswapV3PositionManager = ETH_SEPOLIA_UNISWAPV3_POSITION_MANAGER;
            _weth = ETH_SEPOLIA_WETH;
        } else if (block.chainid == FOUNDRY_LOCAL_CHAINID) {
            _weth = address(new ERC20Mock());
            _uniswapV2Router = address(123); // this will not be used in local testing
            _uniswapV2Factory = address(123); // this will not be used in local testing
            _uniswapV3PositionManager = address(123); // this will not be used in local testing
        }
    }
}
