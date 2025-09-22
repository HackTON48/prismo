/*

    Copyright 2020 PRISMO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {ReentrancyGuard} from "./lib/ReentrancyGuard.sol";
import {SafeERC20} from "./lib/SafeERC20.sol";
import {SafeMath} from "./lib/SafeMath.sol";
import {IPRISMO} from "./intf/IPRISMO.sol";
import {IERC20} from "./intf/IERC20.sol";
import {IWETH} from "./intf/IWETH.sol";
import {IERC4626} from "./intf/IERC4626.sol";

interface IPRISMOZoo {
    function getPRISMO(address baseToken, address quoteToken) external view returns (address);
}

/**
 * @title PRISMO Eth Proxy
 * @author PRISMO Breeder
 *
 * @notice Handle ETH-WETH converting for users.
 */
contract PRISMOEthProxy is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public _PRISMO_ZOO_;
    address payable public _WETH_;

    // ============ Events ============

    event ProxySellEthToToken(
        address indexed seller,
        address indexed quoteToken,
        uint256 payEth,
        uint256 receiveToken
    );

    event ProxyBuyEthWithToken(
        address indexed buyer,
        address indexed quoteToken,
        uint256 receiveEth,
        uint256 payToken
    );

    event ProxySellTokenToEth(
        address indexed seller,
        address indexed baseToken,
        uint256 payToken,
        uint256 receiveEth
    );

    event ProxyBuyTokenWithEth(
        address indexed buyer,
        address indexed baseToken,
        uint256 receiveToken,
        uint256 payEth
    );

    event ProxyDepositEthAsBase(address indexed lp, address indexed PRISMO, uint256 ethAmount);

    event ProxyWithdrawEthAsBase(address indexed lp, address indexed PRISMO, uint256 ethAmount);

    event ProxyDepositEthAsQuote(address indexed lp, address indexed PRISMO, uint256 ethAmount);

    event ProxyWithdrawEthAsQuote(address indexed lp, address indexed PRISMO, uint256 ethAmount);

    // ============ Functions ============

    constructor(address prismoZoo, address payable weth) public {
        _PRISMO_ZOO_ = prismoZoo;
        _WETH_ = weth;
    }

    fallback() external payable {
        require(msg.sender == _WETH_, "WE_SAVED_YOUR_ETH_:)");
    }

    receive() external payable {
        require(msg.sender == _WETH_, "WE_SAVED_YOUR_ETH_:)");
    }

    function sellEthToToken(
        address quoteTokenAddress,
        uint256 ethAmount,
        uint256 minReceiveTokenAmount
    ) external payable preventReentrant returns (uint256 receiveTokenAmount) {
        require(msg.value == ethAmount, "ETH_AMOUNT_NOT_MATCH");
        address PRISMO = IPRISMOZoo(_PRISMO_ZOO_).getPRISMO(_WETH_, quoteTokenAddress);
        require(PRISMO != address(0), "PRISMO_NOT_EXIST");
        IWETH(_WETH_).deposit{value: ethAmount}();
        IWETH(_WETH_).approve(PRISMO, ethAmount);
        receiveTokenAmount = IPRISMO(PRISMO).sellBaseToken(ethAmount, minReceiveTokenAmount, "");
        if(IPRISMO(PRISMO)._QUOTE_TOKEN_IS_VAULT()){
            quoteTokenAddress = IERC4626(quoteTokenAddress).asset();
        }
        _transferOut(quoteTokenAddress, msg.sender, receiveTokenAmount);
        emit ProxySellEthToToken(msg.sender, quoteTokenAddress, ethAmount, receiveTokenAmount);
        return receiveTokenAmount;
    }

    function buyEthWithToken(
        address quoteTokenAddress,
        uint256 ethAmount,
        uint256 maxPayTokenAmount
    ) external preventReentrant returns (uint256 payTokenAmount) {
        address PRISMO = IPRISMOZoo(_PRISMO_ZOO_).getPRISMO(_WETH_, quoteTokenAddress);
        require(PRISMO != address(0), "PRISMO_NOT_EXIST");

        if(IPRISMO(PRISMO)._QUOTE_TOKEN_IS_VAULT()){
            quoteTokenAddress = IERC4626(quoteTokenAddress).asset();
        }

        payTokenAmount = IPRISMO(PRISMO).queryBuyBaseToken(ethAmount);
        _transferIn(quoteTokenAddress, msg.sender, payTokenAmount);
        IERC20(quoteTokenAddress).safeApprove(PRISMO, payTokenAmount);
        IPRISMO(PRISMO).buyBaseToken(ethAmount, maxPayTokenAmount, "");
        IWETH(_WETH_).withdraw(ethAmount);
        msg.sender.transfer(ethAmount);
        emit ProxyBuyEthWithToken(msg.sender, quoteTokenAddress, ethAmount, payTokenAmount);
        return payTokenAmount;
    }

    function sellTokenToEth(
        address baseTokenAddress,
        uint256 tokenAmount,
        uint256 minReceiveEthAmount
    ) external preventReentrant returns (uint256 receiveEthAmount) {
        address PRISMO = IPRISMOZoo(_PRISMO_ZOO_).getPRISMO(baseTokenAddress, _WETH_);
        require(PRISMO != address(0), "PRISMO_NOT_EXIST");

        if(IPRISMO(PRISMO)._BASE_TOKEN_IS_VAULT()){
            baseTokenAddress = IERC4626(baseTokenAddress).asset();
        }

        IERC20(baseTokenAddress).safeApprove(PRISMO, tokenAmount);
        _transferIn(baseTokenAddress, msg.sender, tokenAmount);
        receiveEthAmount = IPRISMO(PRISMO).sellBaseToken(tokenAmount, minReceiveEthAmount, "");
        IWETH(_WETH_).withdraw(receiveEthAmount);
        msg.sender.transfer(receiveEthAmount);
        emit ProxySellTokenToEth(msg.sender, baseTokenAddress, tokenAmount, receiveEthAmount);
        return receiveEthAmount;
    }

    function buyTokenWithEth(
        address baseTokenAddress,
        uint256 tokenAmount,
        uint256 maxPayEthAmount
    ) external payable preventReentrant returns (uint256 payEthAmount) {
        require(msg.value == maxPayEthAmount, "ETH_AMOUNT_NOT_MATCH");
        address PRISMO = IPRISMOZoo(_PRISMO_ZOO_).getPRISMO(baseTokenAddress, _WETH_);
        require(PRISMO != address(0), "PRISMO_NOT_EXIST");

        if(IPRISMO(PRISMO)._BASE_TOKEN_IS_VAULT()){
            baseTokenAddress = IERC4626(baseTokenAddress).asset();
        }

        payEthAmount = IPRISMO(PRISMO).queryBuyBaseToken(tokenAmount);
        IWETH(_WETH_).deposit{value: payEthAmount}();
        IWETH(_WETH_).approve(PRISMO, payEthAmount);
        IPRISMO(PRISMO).buyBaseToken(tokenAmount, maxPayEthAmount, "");
        _transferOut(baseTokenAddress, msg.sender, tokenAmount);
        uint256 refund = maxPayEthAmount.sub(payEthAmount);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
        emit ProxyBuyTokenWithEth(msg.sender, baseTokenAddress, tokenAmount, payEthAmount);
        return payEthAmount;
    }

    function depositEthAsBase(uint256 ethAmount, address quoteTokenAddress)
        external
        payable
        preventReentrant
    {
        require(msg.value == ethAmount, "ETH_AMOUNT_NOT_MATCH");
        address PRISMO = IPRISMOZoo(_PRISMO_ZOO_).getPRISMO(_WETH_, quoteTokenAddress);
        require(PRISMO != address(0), "PRISMO_NOT_EXIST");
        IWETH(_WETH_).deposit{value: ethAmount}();
        IWETH(_WETH_).approve(PRISMO, ethAmount);
        IPRISMO(PRISMO).depositBaseTo(msg.sender, ethAmount);
        emit ProxyDepositEthAsBase(msg.sender, PRISMO, ethAmount);
    }

    function withdrawEthAsBase(uint256 ethAmount, address quoteTokenAddress)
        external
        preventReentrant
        returns (uint256 withdrawAmount)
    {
        address PRISMO = IPRISMOZoo(_PRISMO_ZOO_).getPRISMO(_WETH_, quoteTokenAddress);
        require(PRISMO != address(0), "PRISMO_NOT_EXIST");
        address ethLpToken = IPRISMO(PRISMO)._BASE_CAPITAL_TOKEN_();

        // transfer all pool shares to proxy
        uint256 lpBalance = IERC20(ethLpToken).balanceOf(msg.sender);
        IERC20(ethLpToken).transferFrom(msg.sender, address(this), lpBalance);
        IPRISMO(PRISMO).withdrawBase(ethAmount);

        // transfer remain shares back to msg.sender
        lpBalance = IERC20(ethLpToken).balanceOf(address(this));
        IERC20(ethLpToken).transfer(msg.sender, lpBalance);

        // because of withdraw penalty, withdrawAmount may not equal to ethAmount
        // query weth amount first and than transfer ETH to msg.sender
        uint256 wethAmount = IERC20(_WETH_).balanceOf(address(this));
        IWETH(_WETH_).withdraw(wethAmount);
        msg.sender.transfer(wethAmount);
        emit ProxyWithdrawEthAsBase(msg.sender, PRISMO, wethAmount);
        return wethAmount;
    }

    function withdrawAllEthAsBase(address quoteTokenAddress)
        external
        preventReentrant
        returns (uint256 withdrawAmount)
    {
        address PRISMO = IPRISMOZoo(_PRISMO_ZOO_).getPRISMO(_WETH_, quoteTokenAddress);
        require(PRISMO != address(0), "PRISMO_NOT_EXIST");
        address ethLpToken = IPRISMO(PRISMO)._BASE_CAPITAL_TOKEN_();

        // transfer all pool shares to proxy
        uint256 lpBalance = IERC20(ethLpToken).balanceOf(msg.sender);
        IERC20(ethLpToken).transferFrom(msg.sender, address(this), lpBalance);
        IPRISMO(PRISMO).withdrawAllBase();

        // because of withdraw penalty, withdrawAmount may not equal to ethAmount
        // query weth amount first and than transfer ETH to msg.sender
        uint256 wethAmount = IERC20(_WETH_).balanceOf(address(this));
        IWETH(_WETH_).withdraw(wethAmount);
        msg.sender.transfer(wethAmount);
        emit ProxyWithdrawEthAsBase(msg.sender, PRISMO, wethAmount);
        return wethAmount;
    }

    function depositEthAsQuote(uint256 ethAmount, address baseTokenAddress)
        external
        payable
        preventReentrant
    {
        require(msg.value == ethAmount, "ETH_AMOUNT_NOT_MATCH");
        address PRISMO = IPRISMOZoo(_PRISMO_ZOO_).getPRISMO(baseTokenAddress, _WETH_);
        require(PRISMO != address(0), "PRISMO_NOT_EXIST");
        IWETH(_WETH_).deposit{value: ethAmount}();
        IWETH(_WETH_).approve(PRISMO, ethAmount);
        IPRISMO(PRISMO).depositQuoteTo(msg.sender, ethAmount);
        emit ProxyDepositEthAsQuote(msg.sender, PRISMO, ethAmount);
    }

    function withdrawEthAsQuote(uint256 ethAmount, address baseTokenAddress)
        external
        preventReentrant
        returns (uint256 withdrawAmount)
    {
        address PRISMO = IPRISMOZoo(_PRISMO_ZOO_).getPRISMO(baseTokenAddress, _WETH_);
        require(PRISMO != address(0), "PRISMO_NOT_EXIST");
        address ethLpToken = IPRISMO(PRISMO)._QUOTE_CAPITAL_TOKEN_();

        // transfer all pool shares to proxy
        uint256 lpBalance = IERC20(ethLpToken).balanceOf(msg.sender);
        IERC20(ethLpToken).transferFrom(msg.sender, address(this), lpBalance);
        IPRISMO(PRISMO).withdrawQuote(ethAmount);

        // transfer remain shares back to msg.sender
        lpBalance = IERC20(ethLpToken).balanceOf(address(this));
        IERC20(ethLpToken).transfer(msg.sender, lpBalance);

        // because of withdraw penalty, withdrawAmount may not equal to ethAmount
        // query weth amount first and than transfer ETH to msg.sender
        uint256 wethAmount = IERC20(_WETH_).balanceOf(address(this));
        IWETH(_WETH_).withdraw(wethAmount);
        msg.sender.transfer(wethAmount);
        emit ProxyWithdrawEthAsQuote(msg.sender, PRISMO, wethAmount);
        return wethAmount;
    }

    function withdrawAllEthAsQuote(address baseTokenAddress)
        external
        preventReentrant
        returns (uint256 withdrawAmount)
    {
        address PRISMO = IPRISMOZoo(_PRISMO_ZOO_).getPRISMO(baseTokenAddress, _WETH_);
        require(PRISMO != address(0), "PRISMO_NOT_EXIST");
        address ethLpToken = IPRISMO(PRISMO)._QUOTE_CAPITAL_TOKEN_();

        // transfer all pool shares to proxy
        uint256 lpBalance = IERC20(ethLpToken).balanceOf(msg.sender);
        IERC20(ethLpToken).transferFrom(msg.sender, address(this), lpBalance);
        IPRISMO(PRISMO).withdrawAllQuote();

        // because of withdraw penalty, withdrawAmount may not equal to ethAmount
        // query weth amount first and than transfer ETH to msg.sender
        uint256 wethAmount = IERC20(_WETH_).balanceOf(address(this));
        IWETH(_WETH_).withdraw(wethAmount);
        msg.sender.transfer(wethAmount);
        emit ProxyWithdrawEthAsQuote(msg.sender, PRISMO, wethAmount);
        return wethAmount;
    }

    // ============ Helper Functions ============

    function _transferIn(
        address tokenAddress,
        address from,
        uint256 amount
    ) internal {
        IERC20(tokenAddress).safeTransferFrom(from, address(this), amount);
    }

    function _transferOut(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        IERC20(tokenAddress).safeTransfer(to, amount);
    }
}
