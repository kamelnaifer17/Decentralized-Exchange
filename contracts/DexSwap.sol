// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DexPool.sol" ;

contract DexSwap {
    address[] public allpairs ;
    mapping (address => mapping (address =>DexPool )) public getPair ;
    event PairCreated (address indexed token1 , address indexed token2 , address pair);


  function createPairs (address token1 , address token2 , string calldata token1Name , string calldata token2Name) external returns (address){
  require(token1 != token2,"identical adress not allowed");
  require (address (getPair[token1][token2]) == address(0),"Pair already exist");
  
  string memory liquidityTokenName = string (abi.encodePacked("Liquidity-",token1Name,"-",token2Name)) ;
  string memory liquidityTokenSymbol = string(abi.encodePacked("LP-",token1Name,"-",token2Name));

  DexPool dexpool = new DexPool(token1,token2,liquidityTokenName,liquidityTokenSymbol);
  getPair[token1][token2] = dexpool ;
  getPair[token2][token1] = dexpool ;
  allpairs.push(address(dexpool));
 
  emit PairCreated(token1, token2, address(dexpool));
 
 return address(dexpool);
}
function allpairslength () external view  returns (uint) {
  return allpairs.length;
} 
function getpairs () external view  returns (address[] memory) {
return allpairs ;
}
}