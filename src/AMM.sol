// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AMM is ERC20 {
    error InitializedAlready();
    error CantSendZero();
    error MustBeEqual();
    error MustBeGreaterThanZero();
    error NotAllowed();

    using SafeERC20 for IERC20;

    IERC20 public immutable Token_X;
    IERC20 public immutable Token_Y;



    uint256 reserve_x;
    uint256 reserve_y;

    bool initialized;

    constructor(address _x, address _y) ERC20("AMM", "TKZ") {
        if(_x == _y){revert NotAllowed();}
        Token_X = IERC20(_x);
        Token_Y = IERC20(_y);
    }

    function init(uint256 supply_x, uint256 supply_y) public {
        if (initialized) revert InitializedAlready();
        if (supply_x > 0 && supply_y > 0) revert CantSendZero();
        


        initialized = true;

        reserve_x = reserve_x + supply_x;
        reserve_y = reserve_y + supply_y;

        uint256 z = supply_x * supply_y;

        Token_X.safeTransferFrom(msg.sender, address(this), supply_x);
        Token_Y.safeTransferFrom(msg.sender, address(this), supply_y);

        _mint(msg.sender, z);
    }

    function mint (uint256 supply_x, uint256 supply_y) public {
        if(supply_x < 0 && supply_y < 0) {revert MustBeGreaterThanZero();}
        if (supply_x * reserve_y != supply_y * reserve_x){revert MustBeEqual();}

        Token_X.safeTransferFrom(msg.sender, address(this), supply_x);
        Token_Y.safeTransferFrom(msg.sender, address(this), supply_y);

        uint256 z = supply_x / reserve_x;

        _mint(msg.sender, z);

        reserve_x += supply_x;
        reserve_y += supply_y;

       

    }

    function burn (uint256 z) public {
        if(z < 0){revert MustBeGreaterThanZero();}

        uint256 tot = totalSupply();

        uint256 x = (z * reserve_x) / tot;
        uint256 y = (z * reserve_y) / tot;

        Token_X.safeTransfer(msg.sender, x);
        Token_Y.safeTransfer(msg.sender, y);

        reserve_x -= x;
        reserve_y -= y;

        
    }
}
