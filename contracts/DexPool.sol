// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DexLiquidityToken.sol" ;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract DexPool {
    using SafeMath for uint;
    using Math for uint ; 

    address public token1;
    address public token2;

    uint256 public reserve1;
    uint256 public reserve2;

    uint256 public constantk ;

    DexLiquidityToken public liquiditytoken ;
    
    event Swap (
    address indexed sender,
    uint256 amoutIn,
    uint256 amountOut,
    address tokenIn , 
    address tokenOut
    );
  constructor (address _token1 , address _token2, string memory _liquidityTokenName , string memory _liquidityTokenSymbol){
  token1 = _token1 ;
  token2 = _token2 ;
  liquiditytoken = new DexLiquidityToken(_liquidityTokenName,_liquidityTokenSymbol);

  }

  function addLiquidity (uint amountToken1 , uint amountToken2) external {
  //Create and send some liquidity token to the liquidity provider
  uint256 liquidity;
  uint256 totalsupplyOfToken=liquiditytoken.totalSupply();
  //amount of liquidity at initialization

  if (totalsupplyOfToken == 0){
  liquidity = amountToken1.mul(amountToken2).sqrt ();
  }

  else {
  // amountToken1 * totalsupplyLiquidityToken / Reserve1 , amountToken2 * totalSupplyLiquidityToken / Reserve2
  liquidity = amountToken1.mul(totalsupplyOfToken).div(reserve1).min(amountToken2.mul(totalsupplyOfToken).div(reserve2));
  }
  liquiditytoken.mint(msg.sender,liquidity);
  //transfer amountToken1 and amountToken2 inside the liquidity Pool
  require(IERC20(token1).transferFrom(msg.sender,address(this),amountToken1),"transfer of token1 is failed");
  require(IERC20(token2).transferFrom(msg.sender,address(this),amountToken2),"transfer of token2 is failed");

  //update reserve1 and the reserve2
  reserve1 += amountToken1;
  reserve2 += amountToken2;
  //update the constantformula
  _updateConstantFormula();
  }

  function removeliquidity (uint amountOfLiquidity ) external {
    uint256 totalsupply = liquiditytoken.totalSupply();
    require(amountOfLiquidity <= liquiditytoken.totalSupply(),"Liquidity is more than total supply");
    //burn the liquidity amount
    liquiditytoken.burn(msg.sender , amountOfLiquidity);
    //transfer token1 and token 2 to liquidity provider or msg.sender
    uint256 amount1 = (reserve1*amountOfLiquidity) / totalsupply;
    uint256 amount2 = (reserve2*amountOfLiquidity) / totalsupply;
    require(IERC20(token1).transfer(msg.sender,amount1),"Transfer of token1 failed");
    require(IERC20(token2).transfer(msg.sender,amount2),"Transfer of token1 failed");

     //update reserve1 and reserve2
     reserve1 -= amount1 ;
     reserve2 -= amount2;
    //update the constant formula
   _updateConstantFormula();
  }

  function swapTokens (address fromToken , address toToken , uint256 amountIn , uint256 amountOut) external {
  //Make some cheks
  require(amountIn > 0 && amountOut >0 , "Amount must be greater than 0");
  require((fromToken == token1 && toToken   == token2) || (fromToken == token2 && toToken == token1),"tokens need to be pairs of liquidity pool");
  IERC20 fromTokenContract = IERC20 (fromToken);
  IERC20 toTokenContract = IERC20 (toToken);
  require(fromTokenContract.balanceOf(msg.sender) > amountIn , "Insufficient balance of tokenFrom");
  require(toTokenContract.balanceOf(address(this)) > amountOut , "Insufficient balance of tokenTo");
 
  //Verify that amountOut is less or equal to expected amount after calculation
  uint256 expectedAmountOut ;
  //amountIn token1 reserve1
  //amoutOut token2 reserve2 
  //amoutIn/amountOut = reserve1/reserve2
  //reserve1*reserve2 = constant
  //expected amountOut =reserve2*amoutin / 
  //10*10=100
  //11*(reserve2+expectedAmountOut)=100
  //100/(reserve1 - amountIn)-reserve2=expectedAmountOut
  if (fromToken == token1 && toToken == token2){
    expectedAmountOut = constantk.div(reserve1.sub(amountIn)).sub(reserve2);

  }else {
    expectedAmountOut = constantk.div(reserve2.sub(amountIn)).sub(reserve1);

  }
   require(amountOut <= expectedAmountOut,"Swap does not preserve constant formula");
  //Perform the swap , to transfer amountIn into the liquidity poll and to transfer to the swap initiator the amountOut
  require(fromTokenContract.transferFrom(msg.sender, address(this), amountIn),"transfer of token from failed");
  require(toTokenContract.transfer(msg.sender,expectedAmountOut),"Transfer of token to failed");
  //Upadate the reserve1 and reserve2
  if(fromToken == token1 && toToken == token2){
    reserve1 = reserve1.add (amountIn);
    reserve2 = reserve2.sub (expectedAmountOut);
  } else {
    reserve1 = reserve1.sub (expectedAmountOut);
    reserve2 = reserve2.add (amountIn);
  }
  //check that the result is maintaining the constant formula x*y=k
  require(reserve1.mul(reserve2) <= constantk, "Swap does not preserve constant formula");

  //add events
  emit Swap(msg.sender , amountIn ,expectedAmountOut , fromToken ,  toToken);
  }

  function _updateConstantFormula () internal {
    constantk =reserve1.mul(reserve2);
    require(constantk > 0 ,"Constant formula not update ");

  }
}