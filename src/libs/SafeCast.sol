// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @notice Cast a uint256 to a uint160, revert on overflow
/// @param y The uint256 to be downcasted
/// @return z The downcasted integer, now type uint160
function Uint160(uint256 y) pure returns (uint160 z) {
    require((z = uint160(y)) == y);
}

/// @notice Cast a uint256 to a uint32, revert on overflow
/// @param y The uint256 to be downcasted
/// @return z The downcasted integer, now type uint32
function Uint32(uint256 y) pure returns (uint32 z) {
    require((z = uint32(y)) == y);
}

/// @notice Cast a uint256 to a uint64, revert on overflow
/// @param y The uint256 to be downcasted
/// @return z The downcasted integer, now type uint64
function Uint64(uint256 y) pure returns (uint64 z) {
    require((z = uint32(y)) == y);
}
