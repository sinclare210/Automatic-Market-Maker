// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

/**
 * @title Automated Market Maker (AMM)
 * @author [Sinclair]
 * @notice This contract implements a simple AMM for two ERC20 tokens (Token X and Token Y)
 * @dev The AMM itself is also an ERC20 token representing LP shares
 *
 * - init: Initializes liquidity pool (can only be called once)
 * - mint: Adds liquidity in the same proportion as reserves
 * - burn: Removes liquidity and returns proportional share of tokens
 * - sellX / sellY: Swaps between Token X and Token Y using constant product formula
 *
 * No privileged accounts; fully decentralized.
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AMM is ERC20 {
    using SafeERC20 for IERC20;

    /// @notice Revert if contract is already initialized
    error InitializedAlready();

    /// @notice Revert if tokens sent are zero
    error CantSendZero();

    /// @notice Revert if supplied tokens are not in correct ratio
    error MustBeEqual();

    /// @notice Revert if amount must be greater than zero
    error MustBeGreaterThanZero();

    /// @notice Revert if the same token address is provided
    error NotAllowed();

    IERC20 public immutable Token_X;
    IERC20 public immutable Token_Y;

    uint256 public reserve_x;
    uint256 public reserve_y;

    bool public initialized;

    /**
     * @notice Constructor sets immutable token addresses
     * @param _x Address of token X
     * @param _y Address of token Y
     */
    constructor(address _x, address _y) ERC20("AMM", "TKZ") {
        if(_x == _y) revert NotAllowed();
        Token_X = IERC20(_x);
        Token_Y = IERC20(_y);
    }

    /**
     * @notice Initialize liquidity pool with tokens X and Y
     * @param supply_x Amount of token X
     * @param supply_y Amount of token Y
     */
    function init(uint256 supply_x, uint256 supply_y) public {
        if (initialized) revert InitializedAlready();
        if (supply_x == 0 || supply_y == 0) revert CantSendZero();

        initialized = true;

        reserve_x = supply_x;
        reserve_y = supply_y;

        uint256 z = supply_x * supply_y;

        Token_X.safeTransferFrom(msg.sender, address(this), supply_x);
        Token_Y.safeTransferFrom(msg.sender, address(this), supply_y);

        _mint(msg.sender, z);
    }

    /**
     * @notice Add liquidity in same ratio as reserves
     * @param supply_x Amount of token X
     * @param supply_y Amount of token Y
     */
    function mint(uint256 supply_x, uint256 supply_y) public {
        if(supply_x == 0 || supply_y == 0) revert MustBeGreaterThanZero();
        if (supply_x * reserve_y != supply_y * reserve_x) revert MustBeEqual();

        Token_X.safeTransferFrom(msg.sender, address(this), supply_x);
        Token_Y.safeTransferFrom(msg.sender, address(this), supply_y);

        uint256 z = (supply_x * totalSupply()) / reserve_x; // proportional mint

        _mint(msg.sender, z);

        reserve_x += supply_x;
        reserve_y += supply_y;
    }

    /**
     * @notice Burn LP tokens and withdraw proportional amounts of X and Y
     * @param z Amount of LP tokens to burn
     */
    function burn(uint256 z) public {
        if(z == 0) revert MustBeGreaterThanZero();

        uint256 ts = totalSupply();

        uint256 x = (z * reserve_x) / ts;
        uint256 y = (z * reserve_y) / ts;

        _burn(msg.sender, z);

        Token_X.safeTransfer(msg.sender, x);
        Token_Y.safeTransfer(msg.sender, y);

        reserve_x -= x;
        reserve_y -= y;
    }

    /**
     * @notice Swap token X for token Y
     * @param x Amount of token X to sell
     */
    function sellX(uint256 x) public {
        if (x == 0) revert MustBeGreaterThanZero();

        Token_X.safeTransferFrom(msg.sender, address(this), x);

        uint256 numerator = reserve_x * reserve_y;
        uint256 newReserveX = reserve_x + x;
        uint256 newReserveY = numerator / newReserveX;

        uint256 y = reserve_y - newReserveY;

        require(y > 0, "Zero output");

        Token_Y.safeTransfer(msg.sender, y);

        reserve_x = newReserveX;
        reserve_y = newReserveY;
    }

    /**
     * @notice Swap token Y for token X
     * @param y Amount of token Y to sell
     */
    function sellY(uint256 y) external {
        if (y == 0) revert MustBeGreaterThanZero();

        Token_Y.safeTransferFrom(msg.sender, address(this), y);

        uint256 numerator = reserve_x * reserve_y;
        uint256 newReserveY = reserve_y + y;
        uint256 newReserveX = numerator / newReserveY;

        uint256 x = reserve_x - newReserveX;

        require(x > 0, "Zero output");

        Token_X.safeTransfer(msg.sender, x);

        reserve_x = newReserveX;
        reserve_y = newReserveY;
    }
}
