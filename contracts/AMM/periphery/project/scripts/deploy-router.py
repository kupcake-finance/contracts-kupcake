from brownie import KupcakeRouter, accounts, Contract, interface
import calendar;
import time

from brownie.network.contract import InterfaceConstructor
ts = calendar.timegm(time.gmtime())

def main():
    acct = accounts.load('ftl')
    factory_address = "0x0233b463646A0f1c33e549E86faaCde7a77c8bD7"
    wbnb = "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd"
    busd_address = "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7"
    factory = Contract.from_explorer(factory_address)
    router = KupcakeRouter.deploy(factory_address, wbnb, {"from":acct}, publish_source=True)
    
    #router = PancakeRouter.at("0x226B2C0545b0dA0F77a89668Bc1b0eb1E1422D99")
    print(f"Router:{router}")

    busd = Contract.from_explorer(busd_address)
    tx1 = busd.approve(router, 10e18, {"from":acct})
    tx2 = router.addLiquidityETH(busd,
                            1e16,
                            0,
                            0,
                            acct,
                            calendar.timegm(time.gmtime()) + 60,
                            {"from":acct,
                            "value":1e16,
                            "allow_revert":True})

    pair_address = factory.getPair(wbnb, busd)
    pair = interface.IKupcakePair(pair_address)
    pair.approve(router, 10e18, {"from":acct})

    tx4 = pair.approve(router, 10e18, {"from":acct})
    tx5 = router.removeLiquidityETH(
                        busd,
                        1e9,
                        0,
                        0,
                        acct,
                        calendar.timegm(time.gmtime()) + 60,
                        {"from":acct,
                        "allow_revert":True})

    print(f"Factory: {factory_address}")
    print(f"Router: {router}")