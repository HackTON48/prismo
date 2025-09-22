/*

    Copyright 2020 PRISMO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {IERC4626} from "../intf/IERC4626.sol";
import {DecimalMath} from "../lib/DecimalMath.sol";
import {IPRISMOLpToken} from "../intf/IPRISMOLpToken.sol";
import {IERC20} from "../intf/IERC20.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";
import {SafeMath} from "../lib/SafeMath.sol";
import {Storage} from "./Storage.sol";
import {Types} from "../lib/Types.sol";


/**
 * @title Settlement
 * @author PRISMO Breeder
 *
 * @notice Functions for assets settlement
 */
contract Settlement is Storage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Events ============

    event Donate(uint256 amount, bool isBaseToken);

    event ClaimAssets(address indexed user, uint256 baseTokenAmount, uint256 quoteTokenAmount);

    // ============ Assets IN/OUT Functions ============

    function _baseTokenTransferIn(address from, uint256 amount) internal returns(uint256){
        require(_BASE_BALANCE_.add(amount) <= _BASE_BALANCE_LIMIT_, "BASE_BALANCE_LIMIT_EXCEEDED");

        if(_BASE_TOKEN_IS_VAULT){
            IERC20 baseToken = IERC20(IERC4626(_BASE_TOKEN_).asset());
            baseToken.safeTransferFrom(from, address(this), amount);
            baseToken.approve(_BASE_TOKEN_,amount);
            amount = IERC4626(_BASE_TOKEN_).deposit(amount,address(this));
        }else{
            IERC20(_BASE_TOKEN_).safeTransferFrom(from, address(this), amount);
        }

        _BASE_BALANCE_ = _BASE_BALANCE_.add(amount);
        return amount;
    }

    function _quoteTokenTransferIn(address from, uint256 amount) internal returns(uint256){
        require(
            _QUOTE_BALANCE_.add(amount) <= _QUOTE_BALANCE_LIMIT_,
            "QUOTE_BALANCE_LIMIT_EXCEEDED"
        );

        if(_QUOTE_TOKEN_IS_VAULT){
            IERC20 quoteToken = IERC20(IERC4626(_QUOTE_TOKEN_).asset());
            quoteToken.safeTransferFrom(from, address(this), amount);
            quoteToken.approve(_QUOTE_TOKEN_,amount);
            amount = IERC4626(_QUOTE_TOKEN_).deposit(amount,address(this));
        }else{
            IERC20(_QUOTE_TOKEN_).safeTransferFrom(from, address(this), amount);
        }

        _QUOTE_BALANCE_ = _QUOTE_BALANCE_.add(amount);
        return amount;
    }

    function _baseTokenTransferOut(address to, uint256 amount) internal {

        if(_BASE_TOKEN_IS_VAULT){

            IERC4626(_BASE_TOKEN_).redeem(amount,to,address(this));
        }else{
            IERC20(_BASE_TOKEN_).safeTransfer(to, amount);
        }
        _BASE_BALANCE_ = _BASE_BALANCE_.sub(amount);
    }

    function _quoteTokenTransferOut(address to, uint256 amount) internal {

        if(_QUOTE_TOKEN_IS_VAULT){
            IERC4626(_QUOTE_TOKEN_).redeem(amount,to,address(this));
        }else{
            IERC20(_QUOTE_TOKEN_).safeTransfer(to, amount);
        }

        _QUOTE_BALANCE_ = _QUOTE_BALANCE_.sub(amount);
    }

    // ============ Donate to Liquidity Pool Functions ============

    function _donateBaseToken(uint256 amount) internal {
        _TARGET_BASE_TOKEN_AMOUNT_ = _TARGET_BASE_TOKEN_AMOUNT_.add(amount);
        emit Donate(amount, true);
    }

    function _donateQuoteToken(uint256 amount) internal {
        _TARGET_QUOTE_TOKEN_AMOUNT_ = _TARGET_QUOTE_TOKEN_AMOUNT_.add(amount);
        emit Donate(amount, false);
    }

    function donateBaseToken(uint256 amount) external preventReentrant {
        _baseTokenTransferIn(msg.sender, amount);
        _donateBaseToken(amount);
    }

    function donateQuoteToken(uint256 amount) external preventReentrant {
        _quoteTokenTransferIn(msg.sender, amount);
        _donateQuoteToken(amount);
    }

    // ============ Final Settlement Functions ============


    // in case someone transfer to contract directly
    function retrieve(address token, uint256 amount) external onlyOwner {
        if (token == _BASE_TOKEN_) {
            require(
                IERC20(_BASE_TOKEN_).balanceOf(address(this)) >= _BASE_BALANCE_.add(amount),
                "PRISMO_BASE_BALANCE_NOT_ENOUGH"
            );
        }
        if (token == _QUOTE_TOKEN_) {
            require(
                IERC20(_QUOTE_TOKEN_).balanceOf(address(this)) >= _QUOTE_BALANCE_.add(amount),
                "PRISMO_QUOTE_BALANCE_NOT_ENOUGH"
            );
        }
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
