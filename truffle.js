module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "17",
      from: "0x00a329c0648769A73afAc7F9381E08FB43dBEA72"
    },
    ropsten: {
      host: "localhost",
      port: 8545,
      network_id: "3",
      from: "0x46F19554296d59f3400895F7e3e06D3Bfb4f574f",
      gas: 4000000
    },
    kovan: {
      host: "localhost",
      port: 8545,
      network_id: "42",
      from: "0x46F19554296d59f3400895F7e3e06D3Bfb4f574f",
      gas: 4000000
    }
  }
};