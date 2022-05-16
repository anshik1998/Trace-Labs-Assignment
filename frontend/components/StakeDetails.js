import { useMoralis, useWeb3Contract } from "react-moralis"
import { stakingAddress, stakingAbi, tokenAbi, tokenAddress, rewardTokenAddress } from "../constants"
import { useState, useEffect } from "react"
import { ethers } from "ethers"

export default function StakeDetails() {
    const { account, isWeb3Enabled } = useMoralis()
    const [TRACBalance, setTRACBalance] = useState("0")
    const [ATRACBalance, setATRACBalance] = useState("0")
    const [stakedBalance, setStakedBalance] = useState("0")
    const [expectedReward, setExpectedReward] = useState("0")

    const { runContractFunction: getTRACBalance } = useWeb3Contract({
        abi: tokenAbi,
        contractAddress: tokenAddress,
        functionName: "balanceOf",
        params: {
            account: account,
        },
    })

    const { runContractFunction: getATRACBalance } = useWeb3Contract({
        abi: tokenAbi,
        contractAddress: rewardTokenAddress,
        functionName: "balanceOf",
        params: {
            account: account,
        },
    })

    const { runContractFunction: getStakedBalance } = useWeb3Contract({
        abi: stakingAbi,
        contractAddress: stakingAddress,
        functionName: "checkBalance",
        params: {
            account: account,
        },
    })

    const { runContractFunction: getExpectedReward } = useWeb3Contract({
        abi: stakingAbi,
        contractAddress: stakingAddress,
        functionName: "expectedReward",
        params: {
            account: account,
        },
    })

    useEffect(() => {
        // update the UI and get balances
        if (isWeb3Enabled && account) {
            updateUiValues()
        }
    }, [account, isWeb3Enabled])

    async function updateUiValues() {
        const TRACBalanceFromContract = (
            await getTRACBalance({ onError: (error) => console.log(error) })
        ).toString()
        const formatttedTRACBalanceFromContract = ethers.utils.formatUnits(
            TRACBalanceFromContract,
            "ether"
        )
        setTRACBalance(formatttedTRACBalanceFromContract)

        const ATRACBalanceFromContract = (
            await getATRACBalance({ onError: (error) => console.log(error) })
        ).toString()
        const formatttedATRACBalanceFromContract = ethers.utils.formatUnits(
            ATRACBalanceFromContract,
            "ether"
        )
        setATRACBalance(formatttedATRACBalanceFromContract)

        const stakedFromContract = (
            await getStakedBalance({ onError: (error) => console.log(error) })
        ).toString()
        const formatttedstakedFromContract = ethers.utils.formatUnits(stakedFromContract, "ether")
        setStakedBalance(formatttedstakedFromContract)

        const expectedRewardFromContract = (
            await getExpectedReward({ onError: (error) => console.log(error) })
        ).toString()

        const formatttedExpectedRewardFromContract = ethers.utils.formatUnits(expectedRewardFromContract, "ether")
        setExpectedReward(formatttedExpectedRewardFromContract)
    }

    return (
        <div>
            <div>TRAC Balance: {TRACBalance}</div>
            <div>ATRAC Balance: {ATRACBalance}</div>
            <div>Staked Balance: {stakedBalance}</div>
            <div>Expected Reward: {expectedReward}</div>
        </div>
    )
}