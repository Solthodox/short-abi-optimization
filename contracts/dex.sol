// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    bool private _paused;
    address public token0;
    address public token1;

    mapping(address => uint256) public _reserves;
    uint256 public totalSupply;

    mapping(address => uint256) public _balances;
    address public PROXY;

    modifier onlyProxy() {
        require(msg.sender == PROXY);
        _;
    }

    constructor(
        address _token0,
        address _token1,
        address _proxy
    ) {
        token0 = _token0;
        token1 = _token1;
        PROXY = _proxy;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function pause() external onlyProxy {
        _paused = !_paused;
    }

    function swap(
        address sender,
        address _tokenIn,
        uint256 _amountIn
    ) external onlyProxy returns (uint256 amountOut) {
        require(_tokenIn == token0 || _tokenIn == token1, "Invalid token");
        require(_amountIn > 0, "Amount is 0");
        //pull token in
        bool tokenIs0 = _tokenIn == token0 ? true : false;
        (
            address tokenIn,
            address tokenOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) = tokenIs0
                ? (token0, token1, _reserves[token0], _reserves[token1])
                : (token1, token0, _reserves[token1], _reserves[token0]);
        IERC20(tokenIn).transferFrom(sender, address(this), _amountIn);
        // Calculate token out => 0.3% fee
        // ydx / (x + dx) = dy
        uint256 amountInWithFee = (_amountIn * 977) / 1000;
        amountOut =
            (reserveOut * amountInWithFee) /
            (reserveIn + amountInWithFee);
        // Transfer token out
        IERC20(tokenOut).transfer(sender, amountOut);
        //update reserves
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }

    function addLiquidity(
        address sender,
        uint256 _amount0,
        uint256 _amount1
    ) external onlyProxy returns (uint256 shares) {
        // Pull in token0 and token1
        IERC20(token0).transferFrom(sender, address(this), _amount0);
        IERC20(token1).transferFrom(sender, address(this), _amount1);

        // require (dy / dx = y/x)
        if (_reserves[token0] > 0 || _reserves[token1] > 0) {
            require(
                _reserves[token0] * _amount1 == _reserves[token1] * _amount0,
                "dy / dx != y / x"
            );
        }

        // Mint shares
        // f(x,y) = value of liauidity = sqrt(xy)
        // s = dx / x * T = dy/y * T
        if (totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
        } else {
            shares = _min(
                // for security we will pick the less big number of both calculations
                (_amount0 * totalSupply) / _reserves[token0],
                (_amount1 * totalSupply) / _reserves[token1]
            );
        }
        require(shares > 0, "Shares = 0");
        // mint the shares
        _mint(sender, shares);
        // update reserves
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }

    function removeLiquidity(address sender, uint256 _shares)
        external
        onlyProxy
        returns (uint256 amount0, uint256 amount1)
    {
        // calculate amount 0 and amount 1 to withdraw
        // dx = s / T * x
        // dy = s / T * y
        uint256 bal0 = IERC20(token0).balanceOf(address(this));
        uint256 bal1 = IERC20(token1).balanceOf(address(this));

        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal0) / totalSupply;
        require(amount0 > 0 && amount1 > 0, "Amount0 or amount1 = 0");
        // Burn shares
        _burn(sender, _shares);
        // Update reserves
        _update(bal0 - amount0, bal1 - amount1);
        // Trasfer tokens
        IERC20(token0).transfer(sender, amount0);
        IERC20(token1).transfer(sender, amount1);
    }

    function _mint(address _to, uint256 _amount) private {
        _balances[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        _balances[_from] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint256 _res0, uint256 _res1) private {
        _reserves[token0] = _res0;
        _reserves[token1] = _res1;
    }

    // Square root function
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
