from brownie import accounts, Contract
from scripts.getAbi import get_abi
from web3 import Web3


def create_pair(factory, tokenA, tokenB, network='testnet', account_id=''):

    print(f"tokenA : {tokenA}")
    print(f"tokenB : {tokenB}")

    factory.createPair(tokenA, tokenB, {"from":account_id})
    pair_address = factory.getPair.call(tokenA, tokenB)

    return pair_address

def get_pair(tokenA, tokenB, factory):

    if factory == None:
        factory_address="0xBCfCcbde45cE874adCB698cC183deBcF17952812"
        factory = Contract.from_explorer(factory_address)

    return factory.getPair.call(tokenA, tokenB)