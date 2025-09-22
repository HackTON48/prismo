/*

    Copyright 2020 PRISMO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {Ownable} from "./lib/Ownable.sol";
import {IPRISMO} from "./intf/IPRISMO.sol";
import {ICloneFactory} from "./helper/CloneFactory.sol";


/**
 * @title PRISMOZoo
 * @author PRISMO Breeder
 *
 * @notice Register of All PRISMO
 */
contract PRISMOZoo is Ownable {
    address public _PRISMO_LOGIC_;
    address public _CLONE_FACTORY_;

    address public _DEFAULT_SUPERVISOR_;

    mapping(address => mapping(address => address)) internal _PRISMO_REGISTER_;
    address[] public _PRISMOs;

    // ============ Events ============

    event PRISMOBirth(address newBorn, address baseToken, address quoteToken);

    // ============ Constructor Function ============

    constructor(
        address _prismoLogic,
        address _cloneFactory,
        address _defaultSupervisor
    ) public {
        _PRISMO_LOGIC_ = _prismoLogic;
        _CLONE_FACTORY_ = _cloneFactory;
        _DEFAULT_SUPERVISOR_ = _defaultSupervisor;
    }

    // ============ Admin Function ============

    function setPRISMOLogic(address _prismoLogic) external onlyOwner {
        _PRISMO_LOGIC_ = _prismoLogic;
    }

    function setCloneFactory(address _cloneFactory) external onlyOwner {
        _CLONE_FACTORY_ = _cloneFactory;
    }

    function setDefaultSupervisor(address _defaultSupervisor) external onlyOwner {
        _DEFAULT_SUPERVISOR_ = _defaultSupervisor;
    }

    function removePRISMO(address prismo) external onlyOwner {
        address baseToken = IPRISMO(prismo)._BASE_TOKEN_();
        address quoteToken = IPRISMO(prismo)._QUOTE_TOKEN_();
        require(isPRISMORegistered(baseToken, quoteToken), "PRISMO_NOT_REGISTERED");
        _PRISMO_REGISTER_[baseToken][quoteToken] = address(0);
        for (uint256 i = 0; i <= _PRISMOs.length - 1; i++) {
            if (_PRISMOs[i] == prismo) {
                _PRISMOs[i] = _PRISMOs[_PRISMOs.length - 1];
                _PRISMOs.pop();
                break;
            }
        }
    }

    function addPRISMO(address prismo) public onlyOwner {
        address baseToken = IPRISMO(prismo)._BASE_TOKEN_();
        address quoteToken = IPRISMO(prismo)._QUOTE_TOKEN_();
        require(!isPRISMORegistered(baseToken, quoteToken), "PRISMO_REGISTERED");
        _PRISMO_REGISTER_[baseToken][quoteToken] = prismo;
        _PRISMOs.push(prismo);
    }

    // ============ Breed PRISMO Function ============

    function breedPRISMO(
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external onlyOwner returns (address newBornPRISMO) {
        require(!isPRISMORegistered(baseToken, quoteToken), "PRISMO_REGISTERED");
        newBornPRISMO = ICloneFactory(_CLONE_FACTORY_).clone(_PRISMO_LOGIC_);
        IPRISMO(newBornPRISMO).init(
            _OWNER_,
            _DEFAULT_SUPERVISOR_,
            maintainer,
            baseToken,
            quoteToken,
            oracle,
            lpFeeRate,
            mtFeeRate,
            k,
            gasPriceLimit
        );
        addPRISMO(newBornPRISMO);
        emit PRISMOBirth(newBornPRISMO, baseToken, quoteToken);
        return newBornPRISMO;
    }

    // ============ View Functions ============

    function isPRISMORegistered(address baseToken, address quoteToken) public view returns (bool) {
        if (
            _PRISMO_REGISTER_[baseToken][quoteToken] == address(0) &&
            _PRISMO_REGISTER_[quoteToken][baseToken] == address(0)
        ) {
            return false;
        } else {
            return true;
        }
    }

    function getPRISMO(address baseToken, address quoteToken) external view returns (address) {
        return _PRISMO_REGISTER_[baseToken][quoteToken];
    }

    function getPRISMOs() external view returns (address[] memory) {
        return _PRISMOs;
    }
}
