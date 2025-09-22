/*

    Copyright 2020 PRISMO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {IPRISMO} from "../intf/IPRISMO.sol";
import {IERC20} from "../intf/IERC20.sol";
import {SafeMath} from "../lib/SafeMath.sol";


interface IPRISMOMine {
    function getUserLpBalance(address _lpToken, address _user) external view returns (uint256);
}


contract PRISMOMineReader {
    using SafeMath for uint256;

    function getUserStakedBalance(
        address _prismoMine,
        address _prismo,
        address _user
    ) external view returns (uint256 baseBalance, uint256 quoteBalance) {
        address baseLpToken = IPRISMO(_prismo)._BASE_CAPITAL_TOKEN_();
        address quoteLpToken = IPRISMO(_prismo)._QUOTE_CAPITAL_TOKEN_();

        uint256 baseLpBalance = IPRISMOMine(_prismoMine).getUserLpBalance(baseLpToken, _user);
        uint256 quoteLpBalance = IPRISMOMine(_prismoMine).getUserLpBalance(quoteLpToken, _user);

        uint256 baseLpTotalSupply = IERC20(baseLpToken).totalSupply();
        uint256 quoteLpTotalSupply = IERC20(quoteLpToken).totalSupply();

        (uint256 baseTarget, uint256 quoteTarget) = IPRISMO(_prismo).getExpectedTarget();
        baseBalance = baseTarget.mul(baseLpBalance).div(baseLpTotalSupply);
        quoteBalance = quoteTarget.mul(quoteLpBalance).div(quoteLpTotalSupply);

        return (baseBalance, quoteBalance);
    }
}
