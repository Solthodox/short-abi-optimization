// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract a is ERC20 {
    constructor() ERC20("Chainlink", "LINK") {
        _mint(msg.sender, 20000000 * (10**18));
    }

    function mint() public {
        _mint(msg.sender, 20000000 * (10**18));
    }
}

contract b is ERC20 {
    constructor() ERC20("Optimism", "OP") {
        _mint(msg.sender, 20000000 * (10**18));
    }

    function mint() public {
        _mint(msg.sender, 20000000 * (10**18));
    }
}
