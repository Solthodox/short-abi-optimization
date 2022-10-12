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


## Code overview

For this example we will have a main contract(dex) that only will be called from a proxy contract that receives the function calls as calldata. For this , we will a function to intrepret the calldata: 

```
/**  
@dev Isolates and returns a number of bytes from the calldata from @param startbyte to @param startbyte + @param length
*/
function calldataVal(uint256 startByte, uint256 length)
        private
        pure
        returns (uint256)
    {
        uint256 v;
        if (length < 0x21) revert CalldataLimitExceeded();
        if (length + startByte <= msg.data.length) revert BeyondCallDataSize();
        assembly {
            v := calldataload(startByte) // use calldataload opcode to extract the bytes
        }
        v = v >> (256 - length * 8); // rigth shift
        return v;
    }
```

So assuming we have a 32 bytes calldata (256 bits), using this function we will get a piece of that calldata. First, we make sure that length is smaller than 0x21(32) for obvious reasons. Second, we make sure that the calldata is long enough to reach "startByte" + "length". Using assembly and the "CALLDATALOAD" opcpde we extract tbe bytes from the startByte. Finally we use the right shift to remove the part we don't want.

To make this work we need a fallback function to handle the raw calls:

```
 fallback() external {
        uint256 func;
        func = calldataVal(0, 1); // the first byte is the function selector

        if (func == 1) {
            _dex.swap(
                msg.sender,
                address(uint160(calldataVal(1, 20))),
                calldataVal(21, 2)
            );
        }

        if (func == 2) {
            _dex.addLiquidity(msg.sender, calldataVal(1, 2), calldataVal(3, 2));
        }

        if (func == 3) {
            _dex.removeLiquidity(msg.sender, calldataVal(1, 2));
        }
    }
```

First of all, we will interpret only the first byte of the data as it's the function selector. In the case is 1, it will perform a swap in the dex, if 2 add liquidity and if is 3 remove liquidity. The neccesary data to call this functions is presupposed to be in the data too, such as the address of the token to swap, amount etc.
