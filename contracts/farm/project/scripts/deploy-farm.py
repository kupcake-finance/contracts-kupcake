from brownie import KupCakeToken, MasterChefV2, accounts, Contract, interface
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

    factory_address = {"test":"0xF809307b431F1bbBcBb247d6264b8993479F88C3",
                            "main":"0xBCfCcbde45cE874adCB698cC183deBcF17952812"}[current_network]
    factory = interface.IKupcakeFactory(factory_address)

    # Pools
    wkcs = {'test':"0x307ee9cb3822f360f3b1e10445f7925e56789990",
        "main": "0x4446fc4eb47f2f6586f9faab68b3498f86c07521"}[current_network]
    print("Addresses are ok")

    # Load account
    acct = accounts.load('ftl')

    # Deploy token and mint
    token = KupCakeToken.deploy({"from": acct}, publish_source=publish)
    token.mint(2200000e18, {"from": acct})

    # Deploy Masterchef : token address, dev_address, fee_address, token per block, start block,
    chef = MasterChefV2.deploy(token.address, acct, acct, 3e18 , 0,
        {"from":acct}, publish_source=publish)

    # Deploy Timelock - 43200 (24hours)
    #lock = Timelock.deploy(acct, 0, {"from":acct}, publish_source=publish)

    # Deploy Distribution contract
    # distribute = DistributeReward.deploy(token.address, {"from":acct}, publish_source=publish)

    # Create Pairs
    token_wkcs = create_pair(factory, wkcs, token.address, current_network, acct)

    # Give token ownership to MasterChef
    token.transferOwnership(chef.address, {"from":acct})

    #Add Pools - double
    print("Token-wkcs")
    chef.add(1000, token_wkcs, 0, False, {"from":acct}) # 1 - Token-BNB
 
    #Add Pools - simple
    print("Token pool")
    chef.add(100, token.address, 0, False,{"from":acct}) # 0 - Token

    print(f"Token: {token.address}")
    print(f"MasterChef: {chef}")
    print(f"Token-wkcs: {token_wkcs}")