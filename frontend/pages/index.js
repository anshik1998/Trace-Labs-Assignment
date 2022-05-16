import styles from "../styles/Home.module.css"
import Header from "../components/Header"
import StakeForm from "../components/StakeForm"
import { useChain } from "react-moralis"
import StakeDetails from "../components/StakeDetails"
import WithdrawForm from "../components/WithdrawForm"
import AddPoolRewardForm from "../components/AddPoolRewardForm"

export default function Home() {
  const { switchNetwork, chainId, chain, account } = useChain()
  return (
    <div className={styles.container}>
      <Header />
      <StakeDetails />
      <StakeForm />
      <WithdrawForm />
      <AddPoolRewardForm />
    </div>
  )
}