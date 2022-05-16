from scripts.deploy import main
from brownie import accounts
import brownie
import time
import pytest

accountA = accounts.load('originTrail', 'bank')  # User A aka Bank account
accountB = accounts.load('originTrail2', 'bank')  # User B Account
accountC = accounts.load('originTrail3', 'bank')  # User C Account


def test_staking_contract():
    token, staking = main()

    # assert staking => staking time: within t0 + T seconds
    token.transfer(accountB, 200 * 10e17, {"from": accountA})
    token.transfer(accountC, 800 * 10e17, {"from": accountA})
    token.approve(staking.address, 200 * 10e17, {"from": accountB})
    token.approve(staking.address, 800 * 10e17, {"from": accountC})
    staking.stake(200, {"from": accountB})
    staking.stake(400, {"from": accountC})
    staking.stake(400, {"from": accountC})
    assert(staking.checkBalance({"from": accountB}) == 200)
    assert(staking.users() == 2)

    # assert add pool reward => within t0 + T seconds
    tokenBalance = token.balanceOf(accountA)
    token.approve(staking.address, 100 * 10e17, {"from": accountA})
    staking.addPoolReward({"from": accountA})
    assert (token.balanceOf(accountA) == (tokenBalance - (100 * 10e17)))

    # assert withdrawal => withdrawal time: after t0 + 2T seconds
    time.sleep(22)  # Betweem t0 + 2T and t0 + 3T
    staking.withdraw(200, {"from": accountB})
    time.sleep(11)  # Betweem t0 + 3T and t0 + 4T
    staking.withdraw(800, {"from": accountC})

    # Bank dissolving rewards => after t0 + 4T
    assert (staking.users() == 0)
    assert (staking.checkBalance({"from": accountB}) == 0)
    assert (staking.checkBalance({"from": accountC}) == 0)
    staking.dissolvePoolReward({"from": accountA})
