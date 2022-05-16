# Trace-Labs-Assignment
Assignment Submission

### Better readme viewing at:

https://thehypedmonkey.notion.site/Origin-Trail-Assignment-efd9cd3c8b7746598e84f7ec35eb2cba

## Assumptions:

1. Created TRAC ERC20 mock token to test the smart contract functionality.
2. Users can stake and withdraw ERC20 tokens in multiple transactions.
3. Most of the code has been written to add flexibility to the contract, and, not hard-coding the values.
4. ERC20 token for rewards can either be the same used for the staking or, some other ERC20 token.


## Deployed Smart Contract Addresses- On Rinkeby Testnet:

Origin Trail TRAC Token: 0x6Ee24fBeadBE7F57D32a2F408C1Ca9Ae162b5fB3
Origin Trail Reward ATRAC Token: 0x85A465621EC715154d4442Fb71706E0f86c2FD8f
Staking: 0xeAe5c266bA5368C58BF4682C062CE4a51550b43e

I do have included accounts I created for the purpose of testing the contract within the code submission. The accounts can be found as JSON at:

[https://github.com/anshik1998/Trace-Labs-Assignment/tree/master/backend](https://github.com/anshik1998/Trace-Labs-Assignment/tree/master/backend)

under the names:  [originTrail.json](https://github.com/anshik1998/Trace-Labs-Assignment/blob/master/backend/originTrail.json), [originTrail2.json](https://github.com/anshik1998/Trace-Labs-Assignment/blob/master/backend/originTrail2.json), [originTrail3.json](https://github.com/anshik1998/Trace-Labs-Assignment/blob/master/backend/originTrail3.json)


## Playing with the numbers!

When issuing rewards to the users, during the first phase, i.e. R1, we do not have to consider anything and just issue them their rewards based on the percentage of tokens they staked.

### R1 Calculation

R1 can be mathematically calculated as:

**Reward Amount, R1** = 20% of the total reward allocated

and, the reward will be based on the proportion of the amount the user has staked within the contract, i.e. (amount staked by user) / (total staked within the contract).

= (20% of total reward allocated) * ((amount staked by user) / (total staked within the contract))

 

```solidity
R1 = _rewardPool1 * (rewardAmount / 100);
regularSavings = (R1 * _amount) / _totalStaked;
```

### R2 and R3 Calculation

R2 and R3 calculations will be a bit different. Why? When the user withdraws the amount during R1, then he actually loses out on R2 and R3 rewards. Now, these rewards that the user might have received if he kept his tokens staked needs to be distributed to other holders.

So, the number of additional tokens that needed to be distributed among other users based on their percentage of stake can be:

**Withdrawn tokens** = The total amount of tokens staked minus(-) token amount staked at the current phase, i.e. R2 or R3

And, multiplying withdrawn tokens with R2 or R3 to find out the number of reward tokens that users might have received, that are now subjected to be distributed to other users.

i.e. **bonusSavings** = (withdrawn tokens / total staked tokens) * (R2 or R3, subjected to the withdrawal phase)

Now, this amount have to be distributed to users having their tokens staked in the protocol.

**bonusSavingsPerUse**r = ((bonusSavings * _amount) / _currentStaked);

```solidity
bonusSavings = (((_totalStaked - _currentStaked) * R2) / _totalStaked);
bonusSavingsPerUser = ((bonusSavings * _amount) / _currentStaked);

/* if R2 withdrawal phase*/
regularSavings = (((R1 + R2) * _amount) / _totalStaked);
/*if R3 withdrawal phase*/
regularSavings = (((R1 + R2 + R3) * _amount) / _totalStaked);

_reward = (regularSavings + bonusSavingsPerUser);
```

### ERC 20 tokens

I’ve deployed two different tokens, i.e. one for staking and the other for reward. At the same time, the code can work with a single deployed ERC20 token for both staking and reward purposes.

## Brownie

I’ve just started learning JavaScript, so it was a bit hard for me to code down in Truffle or Hardhat. For now, I’ve coded the deployment and test scripts in Python using Brownie.

To run the deploy script:

```solidity
brownie run deeply <function name>

brownie run deploy // will run main function
brownie run deploy main // will run main function
brownie run deploy simulation // will run simulation function
```

To run the test script:

```solidity
brownie test -k <function name>
```

## Frontend

Most of the frontend code has been written following Patrick Collin’s recent video titled: **[Build a Full Stack DeFi Application: Code Along](https://www.youtube.com/watch?v=5vhVInexaUI).** In his 90 minutes video, he designed the frontend using NextJs for one of his past backend projects.

Feel free to contact me in case of any queries.
