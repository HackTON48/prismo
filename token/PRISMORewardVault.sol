/*

    Copyright 2020 PRISMO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {Ownable} from "../lib/Ownable.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";
import {IERC20} from "../intf/IERC20.sol";


interface IPRISMORewardVault {
    function reward(address to, uint256 amount) external;
}


contract PRISMORewardVault is Ownable {
    using SafeERC20 for IERC20;

    address public prismoToken;

    constructor(address _prismoToken) public {
        prismoToken = _prismoToken;
    }

    function reward(address to, uint256 amount) external onlyOwner {
        IERC20(prismoToken).safeTransfer(to, amount);
    }
}
