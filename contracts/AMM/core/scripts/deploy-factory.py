from brownie import PancakeFactory, accounts, CalHash

def main():
    acct = accounts.load("ftl")
    factory = PancakeFactory.deploy(acct, {"from":acct}, publish_source=True)
    factory.setFeeTo(acct)
    print(f"Factory: {factory}")
