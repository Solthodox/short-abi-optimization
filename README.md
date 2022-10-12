# Calldata Optimization

## Introduction

This is a simplified demonstration of how L2 Optimistic rollups reduce optimize their gas use. Rollups are L2 that process transactions off-chain and then stores them in batches in the Ethereum , so relying in this blockchain makes them extremely secure. This brings a very cheap and scalable solution. But we know that storing data on the mainnet is expensive, that's why rollups like Optimism or Arbitrum use this system to make it cheaper. Its called calldata.

## ABI

Most smart contracts are written in Solidity and interpreted by the ABI(Aplication Binary Interface). The ABI was designed for the L1, where a byte of calldata equals 4 arithmetic operations whereas in L2 is over a thousand. Calldata is divided as follows:

| Section          | Length          | Bytes |Wasted bytes|Wasted gas|Necessary bytes| Necessary gas|
| :------------    |----------------:| -----:| ----------:|---------:|--------------:|-------------:|
| Function selector| 4               | 0-3	 |  3         |48 | 1 | 16|
| Zeroes           | 12              |  4-15 |  12        |48 | 0 |0 |
| Destination Address| 20            |  16-35|  0         |0 | 20 |320|
| Amount            | 32             | 36-67 |  17        |64 | 15 |240
| TOTAL            |  68|||160||576|
