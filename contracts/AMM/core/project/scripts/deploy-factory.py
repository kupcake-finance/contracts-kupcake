from brownie import KupcakeFactory, accounts

def main():
    acct = accounts.load("ftl")
    factory = KupcakeFactory.deploy(acct, {"from":acct}, publish_source=True)
    factory.setFeeTo(acct)
    print(f"Factory: {factory}")
