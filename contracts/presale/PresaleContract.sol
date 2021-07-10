// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;

import "./deps/Context.sol";
import "./deps/Ownable.sol";
import "./deps/SafeERC20.sol";
import "./deps/IERC20.sol";
import "./deps/SafeMath.sol";
import "./deps/ReentrancyGuard.sol";


contract PresaleContract is Context, Ownable, ReentrancyGuard{
    
    using SafeMath for uint256;
   

    IERC20 public rewardToken;

    uint256 rewardTokenBalance;
    uint256 busdTokenBalance;
    uint256 public priceRatio = 10000;
    uint256 public priceRatioAgainst = 10000;
    mapping (address => bool) isHolder;
    uint256 holders;
    uint256 public totalEthSwaped;
    uint256 public rewardTokenTotalAmount;

     using SafeERC20 for IERC20;

   
    constructor(IERC20 _rewardToken) public {
        
        rewardToken = _rewardToken;
        
    }

    function swapBusdToToken() public payable nonReentrant{
        uint256 amount = msg.value;
        require(amount>=0, "value must be superior to 0.");
        totalEthSwaped = totalEthSwaped.add(amount);
        uint256 rewardTokenAmount = amount.mul(priceRatio).div(priceRatioAgainst);
        require(getBalanceRewardToken()>=rewardTokenAmount, "not enough found in contract.");
        IERC20(rewardToken).approve(address(msg.sender), rewardTokenAmount);
        IERC20(rewardToken).safeTransfer(address(_msgSender()), rewardTokenAmount);
        if(isHolder[msg.sender]==false){
            isHolder[msg.sender]=true;
            holders.add(1);
        }
        rewardTokenTotalAmount = rewardTokenTotalAmount.add(rewardTokenAmount);
    }
    
      function withdraw(uint256 _amount) public onlyOwner nonReentrant{
        require(address(this).balance >= _amount, "not enough balance to withdraw ");
        payable(_msgSender()).transfer(_amount);
    }
    
     function withdrawRewardToken(uint256 _amount) public onlyOwner nonReentrant{
        require(_amount > 0 && getBalanceRewardToken()>= _amount, "not enough balance to withdraw.");
        IERC20(rewardToken).approve(address(this), _amount);
        rewardToken.safeTransfer(_msgSender(), _amount);
    }
    
      function withdrawAll() public onlyOwner nonReentrant{
         require(address(this).balance >= 0, "nothing to withdraw ");
        payable(_msgSender()).transfer(address(this).balance);
    }
    
      function withdrawAllRewardToken() public onlyOwner nonReentrant{
        require(getBalanceRewardToken() >= 0, "nothing to withdraw");
        IERC20(rewardToken).approve(address(this), getBalanceRewardToken());
        IERC20(rewardToken).transfer(_msgSender(), getBalanceRewardToken());
    }
    
     function setPriceRatio(uint256 _priceRatio, uint256 _priceRatioAgainst) public onlyOwner nonReentrant{
         priceRatio = _priceRatio;
         priceRatioAgainst = _priceRatioAgainst;
    }
    
    
    
    function getData() public view returns( uint256[9] memory ){
        return  [priceRatio,priceRatioAgainst, getBalanceRewardToken(), getBalance(), rewardToken.balanceOf(address(msg.sender)), address(msg.sender).balance, rewardTokenTotalAmount, totalEthSwaped, holders];
    }
    
     function getBalanceRewardToken() public view returns(uint256) {
        return rewardToken.balanceOf(address(this));
    }
    
     function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    
    receive() external payable {}
  
}

