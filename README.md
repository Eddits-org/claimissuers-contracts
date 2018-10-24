# eth-kyc SmartContract

## Build and test on local dev chain (parity)

```
# Install dependencies
yarn install

# Start local chain
parity --chain dev --unlock 0x00a329c0648769A73afAc7F9381E08FB43dBEA72 --password ./password --jsonrpc-cors=all

# Compile, deploy and test Smart Contracts
yarn run dev
```
