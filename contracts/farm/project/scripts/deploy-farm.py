from brownie import Token, MasterChefV2, DistributeReward, Timelock, accounts, Contract
from web3 import Web3
from time import sleep
from scripts.getAbi import get_abi
from scripts.create_pair import create_pair
from scripts.create_pair import get_pair
import os

# Deploy code for x token and so on...
def main():
    #declarations
    publish=False
    current_network = "test"
    # os.system(")

    factory_address = {"test":"0xd417A0A4b65D24f5eBD0898d9028D92E3592afCC",
                            "main":"0xBCfCcbde45cE874adCB698cC183deBcF17952812"}[current_network]
    factory = Contract.from_explorer(factory_address)
    # Pools
    wbnb = {'test':"0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
        "main": "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"}[current_network]

    if current_network == "test":
        pass
    else:
        usdt_busd = {"main": "0xc15fa3e22c912a276550f3e5fe3b0deb87b55acd"}[current_network]
        btcb_bnb = {"main": "0x7561eee90e24f3b348e1087a005f78b4c8453524"}[current_network]
        eth_bnb = {"main": "0x70d8929d04b60af4fb9b58713ebcf18765ade422"}[current_network]
        dai_busd = {"main": "0x3ab77e40340ab084c3e23be8e5a6f7afed9d41dc"}[current_network]
        dot_bnb = {"main": "0xbcd62661a6b1ded703585d3af7d7649ef4dcdb5c"}[current_network]
        cake_bnb = {"main": "0xa527a61703d82139f8a06bc30097cc9caa2df5a6"}[current_network]
        usdc_busd = {"main": "0x680dd100e4b394bda26a59dd5c119a391e747d18"}[current_network]
        usdt = {"main": "0x55d398326f99059ff775485246999027b3197955"}[current_network]
        btcb = {"main": "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c"}[current_network]
        eth = {"main": "0x2170ed0880ac9a755fd29b2688956bd959f933f8"}[current_network]
        dai = {"main": "0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3"}[current_network]
        dot = {"main": "0x7083609fce4d1d8dc0c979aab8c869ea2c873402"}[current_network]
        cake = {"main": "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82"}[current_network]
        usdc = {"main": "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d"}[current_network]

    def test_pools():
        assert get_pair(wbnb, busd, factory) == bnb_busd

        if current_network == "test":
            pass
        else:
            assert get_pair(usdt,busd, factory) == usdt_busd
            assert get_pair(btcb, wbnb, factory) == btcb_bnb
            assert get_pair(eth, wbnb, factory) == eth_bnb
            assert get_pair(dai, busd, factory) == dai_busd
            assert get_pair(dot, wbnb, factory) == dot_bnb
            assert get_pair(cake, wbnb, factory) == cake_bnb
            assert get_pair(busd, usdc, factory) == usdc_busd

        print("Addresses are ok")

    test_pools()

    # Load account
    acct = accounts.load('jazz')

    # Deploy token and mint
    token = JazzToken.deploy({"from": acct}, publish_source=publish)
    token.mint(1000000000000000000000, {"from": acct})

    # Deploy Masterchef : token address, dev_address, token per block (bigint), start block,
    chef = MasterChefV2.deploy(token.address, acct.address, 1000000000000000000, 0,
        {"from":acct}, publish_source=publish)

    # Deploy Timelock - 43200 (24hours)
    #lock = Timelock.deploy(acct, 0, {"from":acct}, publish_source=publish)

    # Deploy Distribution contract
    # distribute = DistributeReward.deploy(token.address, {"from":acct}, publish_source=publish)

    # Create Pairs
    token_busd = create_pair(factory, busd, token.address, current_network, acct)
    print(f"Token-BUSD pair - {token_busd}")
    token_bnb = create_pair(factory, wbnb, token.address, current_network, acct)
    print(f"Token-BNB pair - {token_bnb}")

    if current_network == "test":
        pass
    else:
        token_cake = create_pair(factory, cake, token.address, "main", acct)
        print(f"Token-CAKE pair - {token_cake}")
        token_dot = create_pair(factory, dot, token.address, "main", acct)
        print(f"Token-DOT pair - {token_dot}")
        token_eth = create_pair(factory, eth, token.address, "main", acct)
        print(f"Token-ETH pair - {token_eth}")

    # Give token ownership to MasterChef
    token.transferOwnership(chef.address, {"from":acct})

    #Add Pools - double
    print("Token-BNB")
    chef.add(4500, token_bnb, 0, False, {"from":acct}) # 1 - Token-BNB
    print("Token-BUSD")
    chef.add(3000, token_busd, 0, False,{"from":acct}) # 2 - Token-BUSD

    print("BNB-BUSD")
    chef.add(500, bnb_busd, 399, False,{"from":acct}) # 5 - BNB-BUSD

    #Add Pools - simple
    print("Token pool")
    chef.add(1500, token.address, 0, False,{"from":acct}) # 0 - Token

    print(f"Token: {token.address}")
    print(f"MasterChef: {chef}")
    print(f"Token-BUSD: {token_busd}")
    print(f"Token-BNB: {token_bnb}")