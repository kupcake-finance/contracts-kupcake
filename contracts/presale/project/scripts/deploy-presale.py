from brownie import PresaleContract, accounts, MockBEP20

def main():
    acct = accounts.load("ftl")
    router = "0x2239D835a2D28c445C29bc489131D1a923e04a07"

    token = MockBEP20.deploy("Test03", "T03", 1e21, {"from":acct}, publish_source=True)
    
    presale = PresaleContract.deploy(token, 0, router,{"from":acct}, publish_source=True)
    token.transfer(presale, 1e20, {"from":acct})
    tx1= presale.swapBusdToToken({"from:":acct, "value":1e16})
    tx2 = presale.claimRewards({"from":acct})
