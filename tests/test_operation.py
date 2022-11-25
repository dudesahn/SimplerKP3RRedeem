import brownie
from brownie import Contract
import pytest


def test_operation(
    chain,
    accounts,
    user,
    gov,
    simple_redeem,
):
    # Approve spending on our contract
    usdc = Contract(simple_redeem.usdc())
    rkpr = Contract(simple_redeem.rkp3r())
    kpr = Contract(simple_redeem.kp3r())
    usdc.approve(simple_redeem, 2**256 - 1, {"from": gov})
    rkpr.approve(simple_redeem, 2**256 - 1, {"from": gov})

    # redeem 100 rKP3R
    to_redeem = 100e18
    usdc_before = usdc.balanceOf(gov)
    kpr_before = kpr.balanceOf(gov)
    simple_redeem.redeem(to_redeem, {"from": gov})
    kpr_after = kpr.balanceOf(gov)
    profit = kpr_after - kpr_before
    assert profit == to_redeem
    usdc_spent = usdc_before - usdc.balanceOf(gov)
    print("USDC Spent:", usdc_spent / 1e6)
    print("KP3R Received:", profit / 1e18)


def test_sweep(
    chain,
    accounts,
    user,
    gov,
    simple_redeem,
):
    # send our contract some usdc, oops
    usdc = Contract(simple_redeem.usdc())
    usdc_before = usdc.balanceOf(gov)
    usdc.transfer(simple_redeem, 100e6, {"from": gov})
    assert usdc.balanceOf(simple_redeem) == 100e6

    # sweep it back out
    simple_redeem.sweep(usdc, {"from": gov})
    assert usdc.balanceOf(gov) == usdc_before
