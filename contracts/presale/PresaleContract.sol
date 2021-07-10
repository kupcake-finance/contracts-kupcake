// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;

import "./deps/Context.sol";
import "./deps/Ownable.sol";
import "./deps/SafeERC20.sol";
import "./deps/IERC20.sol";
import "./deps/SafeMath.sol";
import "./deps/ReentrancyGuard.sol";
import "./deps/IcupcakeFactory.sol";
import "./deps/IcupcakeRouter02.sol";


contract PresaleContract is Context, Ownable, ReentrancyGuard{

    // TODO keep ETH or switch with WETH
    // TODO set WETH amount to add to the pool
    // TODO set Reward token to add to the pool

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // info of each holder
    struct UserInfo public {
         
        uint256 startBlock, // first time holder have been send eth
        uint256 numberOfSwap,   // number of swap
        uint256 ethAmount,  // total eth amount swaped by holder
        uint256 rewardPending,  // total reward pending according to calculation
        uint256 lastSwap    // last time holder send eth
    }

    // kupcake router
    IcupcakeRouter02 public kupcakeRouter;

    // token that will be release at releaseTimeStamp
    IERC20 public rewardToken;

    // amount calculation of reward token : (eth x priceRatio) / priceRatioAgainst
    uint256 public priceRatio = 10000;
    uint256 public priceRatioAgainst = 10000;

    // number of holders that swap
    uint256 public holders;

    // total amount of eth swaped in the pool
    uint256 public ethTotalSwaped;

    // Total amount that will be swap at releaseTimeStamp
    uint256 public rewardTokenTotalToSwap;

    // the unix timestamp since rewards could be claimed
    uint256 public releaseTimeStamp;

    // bool that show if the pool is deployed
    bool isPoolDeployed = false;

    // is msg.sender already a holder
    mapping  (address => bool) public isHolder;
   
    constructor(IERC20 _rewardToken, uint256 _releaseTimeStamp, address _routerAddress) public {
        rewardToken = _rewardToken;
        releaseTimeStamp = _releaseTimeStamp;
        kupcakeRouter = IcupcakeRouter02(_routerAddress);
    }

    // to add eth to the pool and calculate pending rewards
    function swapBusdToToken() public payable nonReentrant{
        UserInfo[_msgSender()] storage user;
        uint256 amount = msg.value;
        require(amount>=0, "value must be superior to 0.");
        require(block.timestamp < releaseTimeStamp, "the presale is finished")
        ethTotalSwaped = ethTotalSwaped.add(amount);
        uint256 rewardTokenAmount = amount.mul(priceRatio).div(priceRatioAgainst);
        user.startBlock==0?user.startBlock = block.timestamp:user.startBlock = user.startBlock;
        user.numberOfSwap = user.numberOfSwap.add(1);
        user.ethAmount = user.ethAmount.add(amount);
        user.rewardPending = user.rewardPending.add(rewardTokenAmount);
        user.lastSwap = block.timestamp;
         if(isHolder[_msgSender()]==false){
            isHolder[_msgSender()]=true;
            holders.add(1);
        }
        rewardTokenTotalToSwap = rewardTokenTotalToSwap.add(rewardTokenAmount);
    }

    // to claims rewards since releaseTimeStamp
    function claimRewards() public {
        UserInfo[_msgSender()] storage user;
        require(block.timestamp >= releaseTimeStamp, "not yet time to withdraw");
        require(user.rewardPending>0, "nothing to withdraw");
        require(getBalanceRewardToken()>= user.rewardPending, "not enough found in contract.");
        if(isPoolDeployed == false){
            address factoryAddress = kupcakeRouter.factory();
            IcupcakeFactory Factory = IcupcakeFactory(factoryAddress);
            Factory.createPair(address(rewardToken),kupcakeRouter.WETH());
            uint256 wethLiquidity= 1; //TODO set Weth to the pool
            uint256 rewardTokenLiquidity = 1 ; //TODO set amont token
            IERC20(kupcakeRouter.WETH()).approve(address(kupcakeRouter), wethLiquidity);
            IERC20(rewardToken).approve(address(kupcakeRouter), rewardTokenLiquidity);
            kupcakeRouter.addLiquidityETH(
                address(rewardToken),
                rewardTokenLiquidity,
                rewardTokenLiquidity,
                owner(),
                block.timestamp
                )
            isPoolDeployed = true;
        }
        IERC20(rewardToken).approve(address(_msgSender()), user.rewardPending);
        IERC20(rewardToken).safeTransfer(address(_msgSender()), user.rewardPending);
        user.rewardPending = 0;
    }
    
    // owner: to withdraw amount of eth
    function withdraw(uint256 _amount) public onlyOwner nonReentrant{
        require(address(this).balance >= _amount, "not enough balance to withdraw ");
        payable(_msgSender()).transfer(_amount);
    }

    // owner: to withdraw amount of reward token
    function withdrawRewardToken(uint256 _amount) public onlyOwner nonReentrant{
        require(_amount > 0 && getBalanceRewardToken()>= _amount, "not enough balance to withdraw.");
        IERC20(rewardToken).approve(address(this), _amount);
        rewardToken.safeTransfer(_msgSender(), _amount);
    }
    
    // owner: to withdraw all amount of eth
    function withdrawAll() public onlyOwner nonReentrant{
         require(address(this).balance >= 0, "nothing to withdraw ");
        payable(_msgSender()).transfer(address(this).balance);
    }
    
    // owner: to withdraw amount of reward token
    function withdrawAllRewardToken() public onlyOwner nonReentrant{
        require(getBalanceRewardToken() >= 0, "nothing to withdraw");
        IERC20(rewardToken).approve(address(this), getBalanceRewardToken());
        IERC20(rewardToken).transfer(_msgSender(), getBalanceRewardToken());
    }
    
    // owner: to set reward calculation
     function setPriceRatio(uint256 _priceRatio, uint256 _priceRatioAgainst) public onlyOwner{
         priceRatio = _priceRatio;
         priceRatioAgainst = _priceRatioAgainst;
    }
    
    // get data for the frontend
    function getData() public view returns( uint256[9] memory ){
        return  [priceRatio,priceRatioAgainst, getBalanceRewardToken(), getBalance(), rewardToken.balanceOf(address(_msgSender())), address(_msgSender()).balance, rewardTokenTotalToSwap, ethTotalSwaped, holders];
    }
    
    // reward token balance of the pool 
    function getBalanceRewardToken() public view returns(uint256) {
        return rewardToken.balanceOf(address(this));
    }
    
    // eth balance of the pool 
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    // owner : set the reward token
    function setRewardToken(IERC20 _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }

    // owner : set release timestamp
    function setReleaseTimeStamp(uint256 _releaseTimeStamp) public onlyOwner {
        releaseTimeStamp = _releaseTimeStamp;
    }

    // owner: set router address
    function setRouterAddress(address _routerAddress) public onlyOwner {
        kupcakeRouter = IcupcakeRouter02(_routerAddress);

    }
    
    // enable contract to recive ETH
    receive() external payable {}
  
}

