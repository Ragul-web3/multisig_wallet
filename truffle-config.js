const HDWalletProvider = require("@truffle/hdwallet-provider");

require('dotenv').config()

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1", // Localhost (default: none)
      port: 8545, // Standard Ethereum port (default: none)
      network_id: "*", // Any network (default: none)
    },
    "ropsten-infura": {
      provider: () => {
        return new HDWalletProvider(process.env.MNEMONIC, `wss://ropsten.infura.io/ws/v3/${process.env.API_KEY}`)
      },
      network_id: 3,
      gas: 0x31c02f,
      gasPrice: 100000000,
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.9", // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 1000
        },
        evmVersion: "homestead"
      }
    },
  },
};
