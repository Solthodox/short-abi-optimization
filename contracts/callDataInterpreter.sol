// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
pragma solidity ^0.8.0;

// DEX INTERFACE
interface IDex {
    function removeLiquidity(address sender, uint256 _shares)
        external
        returns (uint256 amount0, uint256 amount1);

    function addLiquidity(
        address sender,
        uint256 _amount0,
        uint256 _amount1
    ) external returns (uint256 shares);

    function swap(
        address sender,
        address _tokenIn,
        uint256 _amountIn
    ) external returns (uint256 amountOut);
}

contract callDataInterpreter is Ownable {
    // dex contract
    IDex private _dex;
    // ERRORS
    error CalldataLimitExceeded();
    error BeyondCallDataSize();

    // The dex contract is set after deployment
    function setDexContract(address contractAddress) external onlyOwner {
        _dex = IDex(contractAddress);
    }

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
}
