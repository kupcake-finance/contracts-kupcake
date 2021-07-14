// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./deps/Context.sol";
import "./deps/Ownable.sol";
import "./deps/SafeERC20.sol";
import "./deps/IERC20.sol";
import "./deps/SafeMath.sol";
import "./deps/ReentrancyGuard.sol";
import "./deps/IKupcakeFactory.sol";
import "./deps/IKupcakeRouter02.sol";


contract PresaleContract is Context, Ownable, ReentrancyGuard{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // info of each holder
    struct UserInfo {
         
        uint256 numberOfSwap;  // number of swap
        uint256 ethAmount; // total eth amount swaped by holder
        uint256 rewardPending;  // total reward pending according to calculation
        bool isHolder; // is already entered in presale
    }


      // kupcake router
    IKupcakeRouter02 public kupcakeRouter;

    // token that will be release at releaseTimeStamp
    IERC20 public rewardToken;

    // amount calculation of reward token : (eth x priceRatio) / priceRatioAgainst
    uint256 public priceRatio = 10000;
    uint256 public priceRatioAgainst = 10000;
    
    // userInfo
    mapping (address => UserInfo) public userInfo;

    // bool that show if the pool is deployed
    bool isPoolDeployed = false;

    // number of holders that swap
    uint256 public holders;

    // total amount of eth swaped in the pool
    uint256 public ethTotalSwaped;

    // Total amount that will be swap at releaseTimeStamp
    uint256 public rewardTokenTotalToSwap;

    // the unix timestamp since rewards could be claimed
    uint256 public releaseTimeStamp;
    
    // presale limite
    uint public hardcap = 13000 ether;

    constructor(IERC20 _rewardToken, uint256 _releaseTimeStamp , address _routerAddress) public {
        rewardToken = _rewardToken;
        releaseTimeStamp = _releaseTimeStamp;
        kupcakeRouter = IKupcakeRouter02(_routerAddress);
    }

    // Use this to enter the presale
    function swapBusdToToken() public payable nonReentrant{
        // How is sending KCS?
        UserInfo storage user = userInfo[msg.sender];

        // How much did the user sent?
        uint256 amount = msg.value;

        // We implement an hardcap
        require(uint256(amount).add(ethTotalSwaped)<=hardcap, "total amount greater than hardcap.");
        require(amount>=0, "value must be superior to 0.");
        ethTotalSwaped = ethTotalSwaped.add(amount);

        // When will the presale end?
        require(block.timestamp < releaseTimeStamp, "the presale is finished");

        // How much do we owe the user?
        uint256 rewardTokenAmount = amount.mul(priceRatio).div(priceRatioAgainst);
        user.rewardPending = user.rewardPending.add(rewardTokenAmount);

        // How many times did we swap?
        user.numberOfSwap = user.numberOfSwap.add(1);

        // How much did the user send in total?
        user.ethAmount = user.ethAmount.add(amount);

        // How much was bought in total?
        rewardTokenTotalToSwap = rewardTokenTotalToSwap.add(rewardTokenAmount);
    }

    // to claims rewards since releaseTimeStamp
    function claimRewards() public nonReentrant{

        UserInfo storage user = userInfo[msg.sender];

        // You can't claim before the end of the presale
        require(block.timestamp >= releaseTimeStamp, "not yet time to withdraw");

        // Do we owe something to the user?
        require(user.rewardPending>0, "nothing to withdraw");

        // Do we have enough tokens?
        require(getBalanceRewardToken()>= user.rewardPending, "not enough found in contract.");

        // We add liquidity if no pool exists
        if(isPoolDeployed == false){
        
        // We create the pair
        IKupcakeFactory Factory = IKupcakeFactory(kupcakeRouter.factory());
        Factory.createPair(address(rewardToken),kupcakeRouter.WETH());

        // How much should we add?
        uint256 ethToLiquify = ethTotalSwaped.div(70).mul(100);

        // Adding liquidity
        IERC20(rewardToken).approve(address(kupcakeRouter), ethToLiquify);
        kupcakeRouter.addLiquidityETH.value(ethToLiquify)(
            address(rewardToken),
            ethToLiquify,
            0,
            0,
            owner(),
            block.timestamp + 60
            );
        

        payable(address(owner())).transfer(address(this).balance);
        isPoolDeployed = true;
        }
        IERC20(rewardToken).safeTransfer(address(_msgSender()), user.rewardPending);
        user.rewardPending = 0;
    }
    
    // owner: to withdraw amount of eth in case of problem
    function withdraw(uint256 _amount) public onlyOwner nonReentrant{
        // We can only withdraw way after the presale is over.
        require(block.timestamp >= releaseTimeStamp + 10000)
        require(address(this).balance >= _amount, "not enough balance to withdraw ");
        payable(_msgSender()).transfer(_amount);
    }

    // owner: to withdraw amount of reward token in case of problem
    function withdrawRewardToken(uint256 _amount) public onlyOwner nonReentrant{
        // We can only withdraw way after the presale is over.
        require(block.timestamp >= releaseTimeStamp + 10000)
        require(_amount > 0 && getBalanceRewardToken()>= _amount, "not enough balance to withdraw.");
        rewardToken.safeTransfer(_msgSender(), _amount);
    }
    
    // owner: to withdraw all amount of eth
    function withdrawAll() public onlyOwner nonReentrant{
        // We can only withdraw way after the presale is over.
        require(block.timestamp >= releaseTimeStamp + 10000)
        require(address(this).balance >= 0, "nothing to withdraw ");
        payable(_msgSender()).transfer(address(this).balance);
    }
    
    // owner: to withdraw an amount of reward token
    function withdrawAllRewardToken() public onlyOwner nonReentrant{
        // We can only withdraw way after the presale is over.
        require(block.timestamp >= releaseTimeStamp + 10000)
        require(getBalanceRewardToken() >= 0, "nothing to withdraw");
        IERC20(rewardToken).transfer(_msgSender(), getBalanceRewardToken());
    }
    
    // owner: to set reward calculation
     function setPriceRatio(uint256 _priceRatio, uint256 _priceRatioAgainst) public onlyOwner{
         priceRatio = _priceRatio;
         priceRatioAgainst = _priceRatioAgainst;
    }
    
    // get data for the frontend
    function getData() public view returns( uint256[11] memory ){
        return  [priceRatio,priceRatioAgainst, getBalanceRewardToken(), getBalance(), rewardToken.balanceOf(address(_msgSender())), address(_msgSender()).balance, rewardTokenTotalToSwap, ethTotalSwaped, holders, hardcap, releaseTimeStamp ];
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
        require(_releaseTimeStamp >= block.timestamp)
        releaseTimeStamp = _releaseTimeStamp;
    }
    
    function setHardcapAmount(uint256 _hardcap) public onlyOwner {
        hardcap = _hardcap;
    }
    
    // owner: set router address
    function setRouterAddress(address _routerAddress) public onlyOwner {
        kupcakeRouter = IKupcakeRouter02(_routerAddress);
    }

    // enable contract to recive ETH
    receive() external payable {}
}
