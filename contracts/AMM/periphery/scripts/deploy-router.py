from brownie import PancakeRouter, accounts
import calendar;
import time
ts = calendar.timegm(time.gmtime())

def main():
    acct = accounts.load('ftl')
    wbnb = "0x094616f0bdfb0b526bd735bf66eca0ad254ca81f"
    busd_address = "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7"
    router = PancakeRouter.deploy("0x2Cc5BE27dBbE6A5cDa26668D6Fe33b339D4cF9dA", wbnb, {"from":acct}, publish_source=True)
    #router = PancakeRouter.at("0x226B2C0545b0dA0F77a89668Bc1b0eb1E1422D99")
    print(f"Router:{router}")
    
    busd = Contract.from_explorer(busd_address)
    tx1 = busd.approve(router, 10e18, {"from":acct})
    tx2 = router.addLiquidityETH(busd,
                            1e18,
                            1e18,
                            1e16,
                            acct,
                            calendar.timegm(time.gmtime()) + 60,
                            {"from":acct,
                            "value":1e16,
                            "gas":2100000,
                            "allow_revert":True})