// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IWNative.sol";

contract WNativeRelayer is Ownable, ReentrancyGuard {
  address wnative;
  mapping(address => bool) okCallers;

  event SetCallerOk(address[] whitelistedCallers, bool isOk);

  constructor(address _wnative) {
    wnative = _wnative;
  }

  modifier onlyWhitelistedCaller() {
    require(okCallers[msg.sender] == true, "wnativeRelayer: !okCaller");
    _;
  }

  function setCallerOk(address[] calldata whitelistedCallers, bool isOk)
    external
    onlyOwner
  {
    uint256 len = whitelistedCallers.length;
    for (uint256 idx = 0; idx < len; idx++) {
      okCallers[whitelistedCallers[idx]] = isOk;
    }

    emit SetCallerOk(whitelistedCallers, isOk);
  }

  function withdraw(uint256 _amount) public onlyWhitelistedCaller nonReentrant {
    IWNative(wnative).withdraw(_amount);
    (bool success, ) = msg.sender.call{ value: _amount }("");
    require(success, "wnativeRelayer: can't withdraw");
  }

  receive() external payable {}
}
