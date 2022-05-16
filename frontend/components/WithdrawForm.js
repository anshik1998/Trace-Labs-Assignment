import { useWeb3Contract } from "react-moralis"
import { stakingAbi, stakingAddress } from "../constants"
import { Form } from "web3uikit"
import { ethers } from "ethers"

export default function WithdrawForm() {
    const { runContractFunction } = useWeb3Contract()

    let withdrawOptions = {
        abi: stakingAbi,
        contractAddress: stakingAddress,
        functionName: "withdraw",
    }

    async function handleWithdrawSubmit(data) {
        const amountToWithdraw = data.data[0].inputResult
        withdrawOptions.params = {
            amount: ethers.utils.parseUnits(amountToWithdraw, "ether").toString(),
        }
        console.log("Withdrawing...!")
        const tx = await runContractFunction({
            params: withdrawOptions,
            onError: (error) => console.log(error),

        })
        await tx.wait(1)
        console.log("Transaction has been confirmed by 1 block.")
    }

    return (
        <div>
            <Form
                onSubmit={handleWithdrawSubmit}
                data={[
                    {
                        inputWidth: "50%",
                        name: "Amount to withdraw (in TRAC)",
                        type: "number",
                        value: "",
                        key: "amountToWithdraw",
                    },
                ]}
                title="Withdraw staked tokens!"
            ></Form>
        </div>
    )
}