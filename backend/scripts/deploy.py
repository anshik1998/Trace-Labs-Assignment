import time
from brownie import accounts, Staking, ERC20Token

# Smart Contract details: deployed on Rinkeby Testnet
# TRAC Token: 0x6Ee24fBeadBE7F57D32a2F408C1Ca9Ae162b5fB3
# TRAC Reward: 0x85A465621EC715154d4442Fb71706E0f86c2FD8f
# Staking: 0xeAe5c266bA5368C58BF4682C062CE4a51550b43e

accountA = accounts.load('originTrail', 'bank')  # User A aka Bank account
accountB = accounts.load('originTrail2', 'bank')  # User B Account
accountC = accounts.load('originTrail3', 'bank')  # User C Account


def main():
    token = ERC20Token.deploy(
        "Origin Trail", "TRAC", {"from": accountA})
    reward_token = ERC20Token.deploy(
        "Origin Trail Reward", "ATRAC", {"from": accountA})
    staked_token_address = token.address
    reward_token_address = reward_token.address
    # @staking params: rewardAmount, vestedTime (in secs), stakingTokenAddress, rewardTokenAddress,
    # rewardPool1 i.e. 20%, rewardPool2 i.e. 30%, rewardPool3 i.e. 50%
    staking = Staking.deploy(1000, 300, staked_token_address,
                             reward_token_address, 20, 30, 50, {"from": accountA})
    return token, reward_token, staking


def simulation():
    token, reward_token, staking = main()

    # Staking: staking time: t0 + T seconds

    # Account A transferring token to account B and account C
    token.transfer(accountB, 400 * 10e17, {"from": accountA})
    token.transfer(accountC, 600 * 10e17, {"from": accountA})
    # Account B and Account C approving contract to stake his/her/them staking token
    token.approve(staking.address, 400 * 10e17, {"from": accountB})
    token.approve(staking.address, 600 * 10e17, {"from": accountC})
    # Account B and Account C staking ERC20 token
    staking.stake(100, {"from": accountB})
    staking.stake(300, {"from": accountC})
    staking.stake(200, {"from": accountB})
    staking.stake(100, {"from": accountC})
    staking.stake(100, {"from": accountB})
    staking.stake(200, {"from": accountC})

    # Verification checkpoints!

    # Checking the staked balance of account B: expected: 400, 600
    print(
        f'Staked TRAC token: Account B => {staking.checkBalance({"from": accountB})}')
    print(
        f'Staked TRAC token: Account C => {staking.checkBalance({"from": accountC})}')
    # Count of users: expected: 2
    print(f'Users participated in staking => {staking.users()}')
    # Token balance of account A, account B, and account C: expected: 999000, 0, 0
    print(f"Account A TRAC Tokens: {token.balanceOf(accountA) / 10e17}")
    print(f"Account B TRAC Tokens: {token.balanceOf(accountB) / 10e17}")
    print(f"Account C TRAC Tokens: {token.balanceOf(accountC) / 10e17}")

    # Depositing Pool Reward: t0 + T seconds

    # Account A approving contract to deposit his/her/them reward token
    reward_token.approve(staking.address, 1000 * 10e17, {"from": accountA})
    # Depositing pool reward
    staking.addPoolReward({"from": accountA})

    # Withdraw: Withdrawal time: after t0 + 2T seconds

    # Withdrawal between t0 + 2T and t0 + 3T: Eligible for 20 % reward tokens
    time.sleep(620)
    staking.withdraw(200, {"from": accountB})
    staking.withdraw(100, {"from": accountC})
    # Account B and Account C TRAC balance should reflect their withdrawal token amount
    # Expected: 999000, 200, 100
    print(f"Account A TRAC Tokens: {token.balanceOf(accountA) / 10e17}")
    print(f"Account B TRAC Tokens: {token.balanceOf(accountB) / 10e17}")
    print(f"Account C TRAC Tokens: {token.balanceOf(accountC) / 10e17}")
    # Account B and Account C should have received 20% reward based on the proportional staked amount
    print(f"Withdrawn reward ATRAC Tokens: {staking.rewardWithdrawn()}")
    print(
        f"Account A ATRAC Tokens: {reward_token.balanceOf(accountA) / 10e17}")
    print(
        f"Account B ATRAC Tokens: {reward_token.balanceOf(accountB) / 10e17}")
    print(
        f"Account C ATRAC Tokens: {reward_token.balanceOf(accountC) / 10e17}")

    # Withdrawal between t0 + 3T and t0 + 4T: Eligible for 30 % additional reward tokens (total = 50%)
    time.sleep(310)
    staking.withdraw(200, {"from": accountB})
    staking.withdraw(200, {"from": accountC})
    # Account B and Account C TRAC balance should reflect their withdrawal token amount
    # Expected: 999000, 400, 300
    print(f"Account A TRAC Tokens: {token.balanceOf(accountA) / 10e17}")
    print(f"Account B TRAC Tokens: {token.balanceOf(accountB) / 10e17}")
    print(f"Account C TRAC Tokens: {token.balanceOf(accountC) / 10e17}")
    # Account B and Account C should have received additional 30% reward (total 50%)
    # based on the proportional staked amount and some other additional rewards
    print(f"Withdrawn reward ATRAC Tokens: {staking.rewardWithdrawn()}")
    print(
        f"Account A ATRAC Tokens: {reward_token.balanceOf(accountA) / 10e17}")
    print(
        f"Account B ATRAC Tokens: {reward_token.balanceOf(accountB) / 10e17}")
    print(
        f"Account C ATRAC Tokens: {reward_token.balanceOf(accountC) / 10e17}")

    # Withdrawal after t0 + 4T: Eligible for 50 % additional reward tokens (total = 100%)
    time.sleep(310)
    staking.withdraw(300, {"from": accountC})
    # Account B and Account C TRAC balance should reflect their withdrawal token amount
    # Expected: 999000, 400, 600
    print(f"Account A TRAC Tokens: {token.balanceOf(accountA) / 10e17}")
    print(f"Account B TRAC Tokens: {token.balanceOf(accountB) / 10e17}")
    print(f"Account C TRAC Tokens: {token.balanceOf(accountC) / 10e17}")
    # Account B and Account C should have received additional 50% reward (total 100%)
    # based on the proportional staked amount and some other additional rewards
    print(f"Withdrawn reward ATRAC Tokens: {staking.rewardWithdrawn()}")
    print(
        f"Account A ATRAC Tokens: {reward_token.balanceOf(accountA) / 10e17}")
    print(
        f"Account B ATRAC Tokens: {reward_token.balanceOf(accountB) / 10e17}")
    print(
        f"Account C ATRAC Tokens: {reward_token.balanceOf(accountC) / 10e17}")
    # As Account B and Account C users has withdrawn their stake, user participation should be zero.
    print(f'Users participated in staking => {staking.users()}')


# If we're having same ERC20 tokens for the purpose of staking and the issuance of rewards.
#
# def main():
#     token = ERC20Token.deploy(
#         "Origin Trail", "TRAC", {"from": accountA})
#     staked_token_address = token.address
#     reward_token_address = token.address
#     staking = Staking.deploy(100, 10, staked_token_address,
#                              reward_token_address, 20, 30, 50, {"from": accountA})

#     return token, staking
