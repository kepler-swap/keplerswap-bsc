// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '../interfaces/IKeplerRouter.sol';
import '../interfaces/IKeplerFactory.sol';
import '../libraries/KeplerLibrary.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/IWETH.sol';
import '../interfaces/IFeeDispatcher.sol';
import '../interfaces/IMasterChef.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'hardhat/console.sol';
contract KeplerRouter is IKeplerRouter {
    using SafeMath for uint256;

    address public immutable override factory;
    address public immutable override WETH;
    IMasterChef public masterChef;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BabyRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH, IMasterChef _masterChef) {
        factory = _factory;
        WETH = _WETH;
        masterChef = _masterChef;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) private returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IKeplerFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IKeplerFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = KeplerLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = KeplerLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'KeplerRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = KeplerLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'KeplerRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint lockType
    ) external override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = KeplerLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        if (address(masterChef) != address(0)) {
            liquidity = IKeplerPair(pair).mint(address(this));
            IKeplerPair(pair).approve(address(masterChef), liquidity);
            masterChef.depositFor(IKeplerPair(pair), liquidity, lockType, to);
        } else {
            liquidity = IKeplerPair(pair).mint(to);
        }
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint lockType
    ) external override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = KeplerLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IKeplerPair(pair).mint(to);
        if (address(masterChef) != address(0)) {
            liquidity = IKeplerPair(pair).mint(address(this));
            IKeplerPair(pair).approve(address(masterChef), liquidity);
            masterChef.depositFor(IKeplerPair(pair), liquidity, lockType, to);
        } else {
            liquidity = IKeplerPair(pair).mint(to);
        }
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH); // refund dust eth, if any
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = KeplerLibrary.pairFor(factory, tokenA, tokenB);
        IKeplerPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IKeplerPair(pair).burn(to);
        (address token0,) = KeplerLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'KeplerRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'KeplerRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = KeplerLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? KeplerLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IKeplerPair(KeplerLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to);
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        uint256[] memory fees = IKeplerFactory(factory).getTransferFee(path);
        amounts = KeplerLibrary.getAmountsOut(factory, amountIn, path, fees);
        address feeTo = IKeplerFactory(factory).feeTo();
        for (uint i = 0; i < fees.length - 1; i ++) {
            if (fees[i] == 0) continue;
            uint fee = amounts[i].mul(fees[i]).div(1000);
            TransferHelper.safeTransferFrom(path[i], msg.sender, address(this), fee);
            IERC20(path[i]).approve(feeTo, fee);
            IFeeDispatcher(feeTo).doHardWork(KeplerLibrary.pairFor(factory, path[i], path[i + 1]), path[i], msg.sender, fee);
            amounts[i] = amounts[i].sub(fee);        
        }
        require(amounts[amounts.length - 1] >= amountOutMin, 'KeplerRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        console.log("current allowance: ", IERC20(path[0]).allowance(msg.sender, address(this)));
        TransferHelper.safeTransferFrom(path[0], msg.sender, KeplerLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        uint256[] memory fees = IKeplerFactory(factory).getTransferFee(path);
        amounts = KeplerLibrary.getAmountsIn(factory, amountOut, path, fees);
        address feeTo = IKeplerFactory(factory).feeTo();
        for (uint i = 0; i < fees.length - 1; i ++) {
            IERC20(path[i]).approve(feeTo, fees[i]);
            IFeeDispatcher(feeTo).doHardWork(KeplerLibrary.pairFor(factory, path[i], path[i + 1]), path[i], msg.sender, fees[i]);
            amounts[i] = amounts[i].sub(fees[i]);        
        }
        require(amounts[0] <= amountInMax, 'KeplerRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, KeplerLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'KeplerRouter: INVALID_PATH');
        uint256[] memory fees = IKeplerFactory(factory).getTransferFee(path);
        amounts = KeplerLibrary.getAmountsOut(factory, msg.value, path, fees);
        address feeTo = IKeplerFactory(factory).feeTo();
        for (uint i = 0; i < fees.length - 1; i ++) {
            IERC20(path[i]).approve(feeTo, fees[i]);
            IFeeDispatcher(feeTo).doHardWork(KeplerLibrary.pairFor(factory, path[i], path[i + 1]), path[i], msg.sender, fees[i]);
            amounts[i] = amounts[i].sub(fees[i]);        
        }
        require(amounts[amounts.length - 1] >= amountOutMin, 'KeplerRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(KeplerLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'BabyRouter: INVALID_PATH');
        uint256[] memory fees = IKeplerFactory(factory).getTransferFee(path);
        amounts = KeplerLibrary.getAmountsIn(factory, amountOut, path, fees);
        address feeTo = IKeplerFactory(factory).feeTo();
        for (uint i = 0; i < fees.length - 1; i ++) {
            IERC20(path[i]).approve(feeTo, fees[i]);
            IFeeDispatcher(feeTo).doHardWork(KeplerLibrary.pairFor(factory, path[i], path[i + 1]), path[i], msg.sender, fees[i]);
            amounts[i] = amounts[i].sub(fees[i]);        
        }
        require(amounts[0] <= amountInMax, 'KeplerRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, KeplerLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'KeplerRouter: INVALID_PATH');
        uint256[] memory fees = IKeplerFactory(factory).getTransferFee(path);
        amounts = KeplerLibrary.getAmountsOut(factory, amountIn, path, fees);
        address feeTo = IKeplerFactory(factory).feeTo();
        for (uint i = 0; i < fees.length - 1; i ++) {
            IERC20(path[i]).approve(feeTo, fees[i]);
            IFeeDispatcher(feeTo).doHardWork(KeplerLibrary.pairFor(factory, path[i], path[i + 1]), path[i], msg.sender, fees[i]);
            amounts[i] = amounts[i].sub(fees[i]);        
        }
        require(amounts[amounts.length - 1] >= amountOutMin, 'KeplerRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, KeplerLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'KeplerRouter: INVALID_PATH');
        uint256[] memory fees = IKeplerFactory(factory).getTransferFee(path);
        amounts = KeplerLibrary.getAmountsIn(factory, amountOut, path, fees);
        address feeTo = IKeplerFactory(factory).feeTo();
        for (uint i = 0; i < fees.length - 1; i ++) {
            IERC20(path[i]).approve(feeTo, fees[i]);
            IFeeDispatcher(feeTo).doHardWork(KeplerLibrary.pairFor(factory, path[i], path[i + 1]), path[i], msg.sender, fees[i]);
            amounts[i] = amounts[i].sub(fees[i]);        
        }
        require(amounts[0] <= msg.value, 'KeplerRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(KeplerLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]); // refund dust eth, if any
    }
}
