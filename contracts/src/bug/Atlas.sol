// SPDX-License-Identifier: ISC
pragma solidity ^0.8.17;

// https://basescan.org/address/0x8cb5722179de0860b0bce7564b28523bba902d5c
// https://ethereum.stackexchange.com/questions/164865/contract-got-hacked-whats-wrong-with-it

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUniswapV2.sol";
import "./interfaces/IEliteSwapRouter.sol";
import "./interfaces/IEqualizerRouter.sol";
import "./interfaces/IBeethovenXVault.sol";
import "./interfaces/ICurvePool.sol";
import "./interfaces/IArbiTricrypto.sol";
import "./interfaces/IMummyVault.sol";
import "./interfaces/IUniswapV3.sol";
import "./interfaces/IAtlas.sol";

contract Atlas {
    using SafeERC20 for IERC20;

    event log_uint(uint);
    event log_address(address);

    mapping(address => bool) private whitelist;

    constructor(address quoter) {
        whitelist[msg.sender] = true;
        if (quoter != address(0)) {
            whitelist[quoter] = true;
        }
    }

    // ******** //
    // Swappers //
    // ******** //

    // 3 fee pool tiers in v3: 500, 3000, 10000
    function univ3Swap(
        address router,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint amt
    ) private returns (uint) {
        IERC20(tokenIn).approve(router, amt);

        IUniswapV3.ExactInputSingleParams memory params;
        params.tokenIn = tokenIn;
        params.tokenOut = tokenOut;
        params.fee = fee;
        params.recipient = address(this);
        params.amountIn = amt;
        params.amountOutMinimum = 0;
        params.sqrtPriceLimitX96 = 0;

        return IUniswapV3(router).exactInputSingle(params);
    }

    function mummySwap(
        address vault,
        address tokenIn,
        address tokenOut,
        uint amt
    ) private returns (uint) {
        IERC20(tokenIn).transfer(vault, amt);
        uint amtOut = IMummyVault(vault).swap(tokenIn, tokenOut, address(this));
        return amtOut;
    }

    // Works with Curve 2/3Pools
    function curveSwap(
        address pool,
        address tokenIn,
        address tokenOut,
        int128 i,
        int128 j,
        uint amt
    ) private returns (uint) {
        IERC20(tokenIn).safeApprove(pool, amt);

        uint amtOut;
        if (pool == 0x3a1659Ddcf2339Be3aeA159cA010979FB49155FF) {
            // Curve Tricrypto FTM
            amtOut = ICurvePool(pool).exchange(
                uint(int256(i)),
                uint(int256(j)),
                amt,
                0
            ); // Tricrypto Pools
        } else if (pool == 0x960ea3e3C7FB317332d990873d354E18d7645590) {
            // Curve Tricrypto Arbi
            uint amtTokenBefore = IERC20(tokenOut).balanceOf(address(this));
            IArbiTricrypto(pool).exchange(
                uint(int256(i)),
                uint(int256(j)),
                amt,
                0
            );
            amtOut = IERC20(tokenOut).balanceOf(address(this)) - amtTokenBefore;
        } else {
            amtOut = ICurvePool(pool).exchange(i, j, amt, 0); // Standard Curve Pools
        }

        return amtOut;
    }

    // Equalizer Router
    // Note: only the DAI USDC pool is stable
    function equalizerSwap(
        address router,
        address tokenIn,
        address tokenOut,
        bool stable,
        uint amountIn
    ) private returns (uint) {
        IERC20(tokenIn).safeApprove(router, amountIn);

        uint deadline = block.timestamp + 300;
        uint[] memory amts = IEqualizerRouter(router)
            .swapExactTokensForTokensSimple(
                amountIn,
                1,
                tokenIn,
                tokenOut,
                stable,
                address(this),
                deadline
            );
        return amts[amts.length - 1];
    }

    // UniV2
    function uniV2Swap(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amt
    ) private returns (uint) {
        IERC20(tokenIn).safeApprove(router, amt);

        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint deadline = block.timestamp + 300;

        // AmtOutMin
        uint[] memory amtsOut = IUniswapV2(router).swapExactTokensForTokens(
            amt,
            1,
            path,
            address(this),
            deadline
        );
        return amtsOut[amtsOut.length - 1];
    }

    // Eliteness
    function eliteSwap(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amt,
        uint256 pairBinPid
    ) private returns (uint) {
        IERC20(tokenIn).safeApprove(router, amt);
        IEliteSwapRouter.Path memory path = _buildPath(
            IERC20(tokenIn),
            IERC20(tokenOut),
            pairBinPid
        );

        uint deadline = block.timestamp + 300;
        // AmtOutMin
        uint amtOut = IEliteSwapRouter(router).swapExactTokensForTokens(
            amt,
            1,
            path,
            address(this),
            deadline
        );
        return amtOut;
    }

    // ********************
    // Swap Main Functions
    // external caller for multiswap
    function multiswap(
        IAtlas.SwapData calldata swapdata
    ) external returns (uint) {
        require(whitelist[msg.sender] == true, "uauth");
        return multiswapInternal(swapdata);
    }

    // RouterType: 0 = Univ2 | 1 = Elite | 2 = Equalizer | 3 = Curve | 4 = Mummy | 5 = univ3
    // Equalizer: FTM - USDC PID 20 | USDT - USDC PID 1
    function multiswapInternal(
        IAtlas.SwapData calldata swapdata
    ) private returns (uint) {
        require(
            swapdata.routers.length == swapdata.tokensIn.length,
            "Invalid Input"
        );
        require(
            swapdata.tokensIn.length == swapdata.tokensOut.length,
            "Invalid Input"
        );

        uint tAmount = swapdata.amt;
        for (uint i = 0; i < swapdata.routers.length; i++) {
            if (swapdata.routerType[i] == 0) {
                tAmount = uniV2Swap(
                    swapdata.routers[i],
                    swapdata.tokensIn[i],
                    swapdata.tokensOut[i],
                    tAmount
                );
            } else if (swapdata.routerType[i] == 1) {
                tAmount = eliteSwap(
                    swapdata.routers[i],
                    swapdata.tokensIn[i],
                    swapdata.tokensOut[i],
                    tAmount,
                    swapdata.pairBinId[i]
                );
            } else if (swapdata.routerType[i] == 2) {
                tAmount = equalizerSwap(
                    swapdata.routers[i],
                    swapdata.tokensIn[i],
                    swapdata.tokensOut[i],
                    false,
                    tAmount
                ); // Note: only the DAI USDC pool is stable
            } else if (swapdata.routerType[i] == 3) {
                tAmount = curveSwap(
                    swapdata.routers[i],
                    swapdata.tokensIn[i],
                    swapdata.tokensOut[i],
                    swapdata.curvei[i],
                    swapdata.curvej[i],
                    tAmount
                ); // routers[i] here is the curve pool
            } else if (swapdata.routerType[i] == 4) {
                tAmount = mummySwap(
                    swapdata.routers[i],
                    swapdata.tokensIn[i],
                    swapdata.tokensOut[i],
                    tAmount
                );
            } else if (swapdata.routerType[i] == 5) {
                tAmount = univ3Swap(
                    swapdata.routers[i],
                    swapdata.tokensIn[i],
                    swapdata.tokensOut[i],
                    500,
                    tAmount
                ); // leave the fee at 500 pools for now @todo
            }
        }

        return tAmount;
    }

    function arbswap(
        IAtlas.SwapData calldata swapdata
    ) external returns (uint) {
        //require (whitelist[msg.sender] == true, "uauth");
        require(
            swapdata.tokensIn[0] ==
                swapdata.tokensOut[swapdata.tokensOut.length - 1],
            "Incomplete Path"
        );

        uint amtOut = multiswapInternal(swapdata);
        require(amtOut > swapdata.amt, "Failed: NP");
        return amtOut;
    }

    // ***** //
    // Views //
    // ***** //

    /*
    function queryBeethovenX(address vault) public view returns (uint) {

    } */

    function equalizerAmountsOut(
        address router,
        address tokenIn,
        address tokenOut,
        uint amount
    ) public view returns (uint) {
        (uint amtOut, ) = IEqualizerRouter(router).getAmountOut(
            amount,
            tokenIn,
            tokenOut
        );
        return amtOut;
    }

    function eliteAmountsOut(
        address router,
        address pool,
        uint128 amountIn,
        bool swapForY
    ) public view returns (uint) {
        (, uint amtOut, ) = IEliteSwapRouter(router).getSwapOut(
            pool,
            amountIn,
            swapForY
        );
        return amtOut;
    }

    function uniV2AmountsOut(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amt
    ) public view returns (uint) {
        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint[] memory amtsOut = IUniswapV2(router).getAmountsOut(amt, path);
        return amtsOut[amtsOut.length - 1];
    }

    // ********************** //
    //  Supporting Functions  //
    // ********************** //

    function recoverEth() external {
        require(whitelist[msg.sender] = true, "uauth");
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverTokens(address token, uint amount) external {
        require(whitelist[msg.sender] == true, "uauth");
        if (amount == 0) {
            IERC20(token).transfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    function getBalance(address token) external view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function addWhitelist(address allow) external {
        require(whitelist[msg.sender] == true, "uauth");
        whitelist[allow] = true;
    }

    function removeWhitelist(address remove) external {
        require(whitelist[msg.sender] == true, "uauth");
        whitelist[remove] = false;
    }

    // For Elite Router
    function _buildPath(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint pairBinPid
    ) private pure returns (IEliteSwapRouter.Path memory path) {
        path.pairBinSteps = new uint256[](1);
        path.pairBinSteps[0] = pairBinPid;

        path.versions = new IEliteSwapRouter.Version[](1);
        path.versions[0] = IEliteSwapRouter.Version.V2_1;

        path.tokenPath = new IERC20[](2);
        path.tokenPath[0] = tokenIn;
        path.tokenPath[1] = tokenOut;
    }
}
