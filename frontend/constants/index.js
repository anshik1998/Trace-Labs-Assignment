// const stakingAddress = "0x7A6e241940eA4c45A16D887730842f4D54A9D7Ca"
const tokenAddress = "0x6Ee24fBeadBE7F57D32a2F408C1Ca9Ae162b5fB3"
const rewardTokenAddress = "0x85A465621EC715154d4442Fb71706E0f86c2FD8f";
const stakingAddress = "0xeAe5c266bA5368C58BF4682C062CE4a51550b43e"

const stakingAbi = require("./stakingAbi.json")
const tokenAbi = require("./ERC20TokenAbi.json")

module.exports = {
    stakingAbi,
    tokenAbi,
    stakingAddress,
    tokenAddress,
    rewardTokenAddress
}