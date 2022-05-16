//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
Your task is to create a bank smart contract which will enable anyone to deposit an amount X of XYZ
ERC20 tokens to their savings (staking) account. The bank smart contract also contains an additional
token reward pool of R XYZ tokens, deposited to the contract by the contract owner (bank owner) at
contract deployment. At deployment the bank owner sets a time period constant T, to be used for reward
calculation.

Contract dynamics (example illustrated below):
● The smart contract is deployed at t0
● The reward pool R is split into 3 subpools
    ○ R1 = 20% of R, available after 2T has passed since contract deployment
    ○ R2 = 30% of R, available after 3T has passed since contract deployment
    ○ R3 = 50% of R, available after 4T has passed since contract deployment


● Deposit period: During the first period of T time the users can deposit tokens. After T has
passed, no more deposits are allowed.

● Lock period: From moment t0+T to t0+2T, users cannot withdraw their tokens (If the user tries to
remove tokens before T time has elapsed since they have deposited, the transaction should
fail).

● Withdraw periods: After T2 has passed since contract deployment, the users can withdraw their
tokens. However, the longer they wait, the bigger the reward they get:
    ○ If a user withdraws tokens during the period t0+2T to t0+3T, they collect a proportional
    amount of the reward pool R1, according to the ratio of the number of tokens they have
    staked compared to the total number of tokens staked on the contract (by all users).
    ○ If a user withdraws tokens during the period t0+3T to t0+4T, they collect a proportional
    amount of the remaining reward pool R1 and R2, according to the proportion of the
    number of tokens they have staked compared to the total number of tokens staked on
    the contract (by all users)
    ○ If the user withdraws tokens after 4T has passed since contract deployment, they can
    receive the full reward of R (R1+R2+R3) proportionally to their ratio of tokens in the
    total pool
    ○ If no user waits for the last period (for 4T to pass), the remaining tokens on the
    contract can be withdrawn by the bank (contract owner). In no other situation can the
    bank owner remove tokens from the contract.


Example:

○ User 1 stakes S1 = 1000 XYZ during deposit period
○ User 2 stakes S2 = 4000 XYZ during deposit period
○ Reward pool R = 1000 XYZ (R1 = 200XYZ, R2 = 300 XYZ, R3 = 500 XYZ)

    ○ User 1 withdraws their tokens in period t0+2T to t0+3T
        ■ User 1 should receive their initial deposit of 1000 XYZ and
        ■ A reward of 40 XYZ, proportional to their amount of tokens in the pool
    ○ User 2 is impatient and withdraws their tokens in period t0+3T to t0+4T
        ■ User 2 should receive their their initial deposit of 4000 XYZ and
        ■ A reward of 460 XYZ, which is 100% of the remaining R1 tokens, and 100% of
        the remaining R2 tokens (as user 2 tokens are 100% of the remaining staked
        tokens in the bank)

    ○ After 4T has passed, the bank can withdraw the remaining reward (500XYZ) since no
    user has any more deposits to withdraw
*/

import "OpenZeppelin/openzeppelin-contracts@4.6.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.6.0/contracts/access/Ownable.sol";
import "OpenZeppelin/openzeppelin-contracts@4.6.0/contracts/security/Pausable.sol";
import "OpenZeppelin/openzeppelin-contracts@4.6.0/contracts/security/ReentrancyGuard.sol";

contract Staking is Ownable, Pausable, ReentrancyGuard {
    uint256 public R1; // Stage 1 Reward Distribution
    uint256 public R2; // Stage 2 Reward Distribution
    uint256 public R3; // Stage 3 Reward Distribution
    uint256 public users; // Counting the number of participants
    uint256 public vestedTime; // Vested Time Period, denoted by T
    uint256 public startTime; // Contract Start Time, denoted by t0
    uint256 public rewardAmount; // Total amount of tokens to be rewarded
    uint256 public rewardWithdrawn; // Reward that have been withdrawn from the contract treasury
    uint256 private _totalStaked; // Total amount of tokens staked within the contract
    uint256 private _currentStaked; // Total amount of tokens staked at a given time
    uint256 private regularSavings; // Amount of Token Rewards that are based on R1, R2 & R3
    uint256 private bonusSavings; // Amount of Token Rewards, if a user withdraw staked token before t4
    uint256 private bonusSavingsPerUser; // Amount of Token Rewards per user, if a user withdraw staked token before t4
    IERC20 public rewardToken; // Interface for reward token
    IERC20 public stakingToken; // Interface for staking token
    address private _owner;

    // To calculate the reward distribution
    // if someone withdrew his/her/their staked tokens
    bool private firstR2Call;
    bool private firstR3Call;

    /*
    @param:
    _rewardAmount => the amount of token to be distributed as reward
    _vestedTime => the vested time period to manage the withdrawal of tokens and rewards
    _stakingToken => ERC20 token allowed for staking
    _rewardToken => ERC20 token for distribution of rewards
    _rewardPool1 => the percentage of rewards to be distributed in Stage 1
    _rewardPool2 => the percentage of rewards to be distributed in Stage 2
    _rewardPool3 => the percentage of rewards to be distributed in Stage 3
    */
    constructor(
        uint256 _rewardAmount,
        uint256 _vestedTime,
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardPool1,
        uint256 _rewardPool2,
        uint256 _rewardPool3
    ) {
        rewardAmount = _rewardAmount * 10e17;
        vestedTime = _vestedTime;
        startTime = uint256(block.timestamp);
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        R1 = _rewardPool1 * (rewardAmount / 100);
        R2 = _rewardPool2 * (rewardAmount / 100);
        R3 = _rewardPool3 * (rewardAmount / 100);
        _owner = msg.sender;
    }

    /*
    @dev: Modifier checks whether the current timestamp is less 
    than the permitted time period to call the function 'stake'
    */

    modifier beforeTime(uint256 time) {
        require(time > uint256(block.timestamp), "Transaction denied.");
        _;
    }

    /*
    @dev: Modifier checks whether the current timestamp is greater than the 
    permitted time period to call the function 'withdraw' and 'calculateReward'
    */

    modifier afterTime(uint256 time) {
        require(time < uint256(block.timestamp), "Transaction denied.");
        _;
    }

    /*
    @dev:

    _repeatedUser: to check whether the user is a repeating customer, or a new customer
    _stakeBalance: to check the amount of tokens a user has invested in the contract "during that period"
    */

    mapping(address => bool) private _repeatedUser;
    mapping(address => uint256) private _stakeBalance;

    error TransactionFailed();

    /*
    @dev: Stake user's money in the smart contract during t0 to T1, 
    where:

    t0 => startTime => block.timestamp
    T1 => startTime + vestedTime
    T2 => startTime + 2 * vestedTime
    T3 => startTime + 3 * vestedTime
    T4 => startTime + 4 * vestedTime

    '_repeatedUsers' prevents double counting of a user
    Transaction reverts back if 'stakingSuccess' returns false
    */

    function stake(uint256 _amount)
        external
        beforeTime(startTime + vestedTime)
    {
        _amount = (_amount * 10e17);
        require(msg.sender != _owner, "Bank owner is not allowed to stake.");
        require(_amount > 0);
        _stakeBalance[msg.sender] += _amount;
        _totalStaked += _amount;
        _currentStaked += _amount;
        if (!_repeatedUser[msg.sender]) {
            users += 1;
            _repeatedUser[msg.sender] = true;
        }
        bool stakingSuccess = stakingToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        if (!stakingSuccess) {
            revert TransactionFailed();
        }

        emit Staked(msg.sender, address(this), _amount);
    }

    /*
    @dev: To let user withdraw his/her/their staked & reward tokens from the contract, only after T2.
    Transaction reverts back if either 'stakeWithdrawalSuccess' or 'rewardWithdrawalSuccess' returns false. 
    */

    function withdraw(uint256 _amount)
        external
        afterTime(startTime + 2 * vestedTime)
    {
        _amount = _amount * 10e17;
        require(msg.sender != _owner);
        require(_stakeBalance[msg.sender] >= _amount);
        _stakeBalance[msg.sender] -= _amount;
        uint256 _reward = _calculateReward(_amount);
        _currentStaked -= _amount;
        if (_stakeBalance[msg.sender] == 0) {
            users -= 1;
        }
        bool stakeWithdrawalSuccess = stakingToken.transfer(
            msg.sender,
            _amount
        );
        bool rewardWithdrawalSuccess = rewardToken.transfer(
            msg.sender,
            _reward
        );

        if (!stakeWithdrawalSuccess) {
            revert TransactionFailed();
        }
        if (!rewardWithdrawalSuccess) {
            revert TransactionFailed();
        }

        emit Withdrawn(msg.sender, _amount);
    }

    /*
    @dev: To calculate the amount of token to be distributed to the user based on the given condition.
    */

    function _calculateReward(uint256 _amount)
        private
        afterTime(startTime + 2 * vestedTime)
        returns (uint256 _reward)
    {
        if (block.timestamp > (startTime + (4 * vestedTime))) {
            if (!firstR3Call) {
                bonusSavings = (((_totalStaked - _currentStaked) * R3) /
                    _totalStaked);
                bonusSavingsPerUser = ((bonusSavings * _amount) /
                    _currentStaked);
                firstR3Call = true;
            }
            regularSavings = (((R1 + R2 + R3) * _amount) / _totalStaked);
        }
        if (
            (block.timestamp < (startTime + (4 * vestedTime))) &&
            (block.timestamp > (startTime + (3 * vestedTime)))
        ) {
            if (!firstR2Call) {
                bonusSavings = (((_totalStaked - _currentStaked) * R2) /
                    _totalStaked);
                bonusSavingsPerUser = ((bonusSavings * _amount) /
                    _currentStaked);
                firstR2Call = true;
            }
            regularSavings = (((R1 + R2) * _amount) / _totalStaked);
        }

        if (block.timestamp < (startTime + (3 * vestedTime))) {
            regularSavings = (R1 * _amount) / _totalStaked;
        }
        _reward = (regularSavings + bonusSavingsPerUser);
        rewardWithdrawn += _reward;
        return _reward;
    }

    /*
    @dev: To let the bank deposit the reward tokens in the reward pool
    Revert back if 'rewardStakingSuccess' returns false.
    I do have included the same condition for the banks to add pool deposits as user deposits before t0 + T.  
    */

    function addPoolReward()
        external
        beforeTime(startTime + vestedTime)
        onlyOwner
    {
        bool rewardStakingSuccess = rewardToken.transferFrom(
            msg.sender,
            address(this),
            rewardAmount
        );
        if (!rewardStakingSuccess) {
            revert TransactionFailed();
        }
        emit Staked(msg.sender, address(this), rewardAmount);
    }

    /*
    @dev: To let bank withdraw the rewards after T4 in case all the users have withdrawn their staked tokens.
    Revert back if 'rewardClaimedSuccess' returns false. 
    */

    function dissolvePoolReward()
        external
        afterTime(startTime + 4 * vestedTime)
        onlyOwner
    {
        require(_currentStaked == 0, "Transaction denied");
        require(users == 0, "Transaction denied");
        uint256 unspentReward = rewardAmount - rewardWithdrawn;
        bool rewardClaimedSuccess = rewardToken.transfer(
            msg.sender,
            unspentReward
        );
        if (!rewardClaimedSuccess) {
            revert TransactionFailed();
        }
        emit Withdrawn(msg.sender, unspentReward);
    }

    /*
    @dev: To pause and unpause, in case any vulnerability is discovered within the contract. 
    */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* =========== VIEW FUNCTIONS ============*/

    function checkBalance() public view returns (uint256) {
        return _stakeBalance[msg.sender] / 10e17;
    }

    function expectedReward() public view returns (uint256) {
        if (_stakeBalance[msg.sender] > 0) {
            return
                ((_stakeBalance[msg.sender] / _totalStaked) * rewardAmount) /
                10e17;
        } else {
            return 0;
        }
    }

    function rewardValue() public view returns (uint256) {
        return rewardAmount / 10e17;
    }

    /* =============== EVENTS ================ */

    event Staked(address from, address to, uint256 amount);
    event Withdrawn(address from, uint256 amount);
}
