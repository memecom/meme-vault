// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ParamCheckBase  {
    /**
    * @dev modifier Throws when value is not above zero
    */
    modifier aboveZero(uint256 _value, string memory _error) {
        require(_value > 0, _error);
        _;
    }
}
