/*

    Copyright 2020 PRISMO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {Storage} from "./Storage.sol";
import {IERC20} from "../intf/IERC20.sol";
import {IERC4626} from "../intf/IERC4626.sol";

/**
 * @title Admin
 * @author PRISMO Breeder
 *
 * @notice Functions for admin operations
 */
contract Admin is Storage {
    // ============ Events ============

    event UpdateGasPriceLimit(uint256 oldGasPriceLimit, uint256 newGasPriceLimit);

    event UpdateLiquidityProviderFeeRate(
        uint256 oldLiquidityProviderFeeRate,
        uint256 newLiquidityProviderFeeRate
    );

    event UpdateMaintainerFeeRate(uint256 oldMaintainerFeeRate, uint256 newMaintainerFeeRate);

    event UpdateK(uint256 oldK, uint256 newK);

    // ============ Params Setting Functions ============

    function setOracle(address newOracle) external onlyOwner {
        _ORACLE_ = newOracle;
    }

    function setSupervisor(address newSupervisor) external onlyOwner {
        _SUPERVISOR_ = newSupervisor;
    }

    function setMaintainer(address newMaintainer) external onlyOwner {
        _MAINTAINER_ = newMaintainer;
    }

    function setLiquidityProviderFeeRate(uint256 newLiquidityPorviderFeeRate) external onlyOwner {
        emit UpdateLiquidityProviderFeeRate(_LP_FEE_RATE_, newLiquidityPorviderFeeRate);
        _LP_FEE_RATE_ = newLiquidityPorviderFeeRate;
        _checkPRISMOParameters();
    }

    function setMaintainerFeeRate(uint256 newMaintainerFeeRate) external onlyOwner {
        emit UpdateMaintainerFeeRate(_MT_FEE_RATE_, newMaintainerFeeRate);
        _MT_FEE_RATE_ = newMaintainerFeeRate;
        _checkPRISMOParameters();
    }

    function setK(uint256 newK) external onlyOwner {
        emit UpdateK(_K_, newK);
        _K_ = newK;
        _checkPRISMOParameters();
    }

    function setGasPriceLimit(uint256 newGasPriceLimit) external onlySupervisorOrOwner {
        emit UpdateGasPriceLimit(_GAS_PRICE_LIMIT_, newGasPriceLimit);
        _GAS_PRICE_LIMIT_ = newGasPriceLimit;
    }

    // ============ System Control Functions ============

    function disableTrading() external onlySupervisorOrOwner {
        _TRADE_ALLOWED_ = false;
    }

    function enableTrading() external onlyOwner  {
        _TRADE_ALLOWED_ = true;
    }

    function disableQuoteDeposit() external onlySupervisorOrOwner {
        _DEPOSIT_QUOTE_ALLOWED_ = false;
    }

    function enableQuoteDeposit() external onlyOwner  {
        _DEPOSIT_QUOTE_ALLOWED_ = true;
    }

    function disableBaseDeposit() external onlySupervisorOrOwner {
        _DEPOSIT_BASE_ALLOWED_ = false;
    }

    function enableBaseDeposit() external onlyOwner  {
        _DEPOSIT_BASE_ALLOWED_ = true;
    }

    // ============ Advanced Control Functions ============

    function disableBuying() external onlySupervisorOrOwner {
        _BUYING_ALLOWED_ = false;
    }

    function enableBuying() external onlyOwner  {
        _BUYING_ALLOWED_ = true;
    }

    function disableSelling() external onlySupervisorOrOwner {
        _SELLING_ALLOWED_ = false;
    }

    function enableSelling() external onlyOwner  {
        _SELLING_ALLOWED_ = true;
    }

    function setBaseBalanceLimit(uint256 newBaseBalanceLimit) external onlyOwner  {
        _BASE_BALANCE_LIMIT_ = newBaseBalanceLimit;
    }

    function setQuoteBalanceLimit(uint256 newQuoteBalanceLimit) external onlyOwner  {
        _QUOTE_BALANCE_LIMIT_ = newQuoteBalanceLimit;
    }

    function emergencyTransfer(address token) external onlyOwner{
        if(token == _BASE_TOKEN_ && _BASE_TOKEN_IS_VAULT){
            IERC4626 vault = IERC4626(_BASE_TOKEN_);
            vault.redeem(vault.maxRedeem(address(this)),address(this),address(this));
        } else if(token == _QUOTE_TOKEN_ && _QUOTE_TOKEN_IS_VAULT){
            IERC4626 vault = IERC4626(_QUOTE_TOKEN_);
            vault.redeem(vault.maxRedeem(address(this)),address(this),address(this));
        }
        IERC20(token).transfer(msg.sender,IERC20(token).balanceOf(address(this)));
    }

}
