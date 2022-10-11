require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config()
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.4",
  networks: {
    "optikovan": {
      url: "https://goerli.optimism.io",
      accounts: {
        mnemonic: process.env.MNEMONICS
      }
    }
  }
};