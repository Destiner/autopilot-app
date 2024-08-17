// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.26;

import { IERC7579Account, Execution } from "modulekit/Accounts.sol";
import { SchedulingBase } from "modulekit/Modules.sol";
import { ERC20Integration } from "modulekit/Integrations.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { ModeLib } from "erc7579/lib/ModeLib.sol";
import { ExecutionLib } from "erc7579/lib/ExecutionLib.sol";
import { convert, exp2, sd } from "@prb/math/SD59x18.sol";

/**
 * @title ScheduledTokenAuctions
 * @dev Module that allows users to schedule swaps to be executed at a later time
 * @author Timur Badretdinov
 */
contract ScheduledTokenAuctions is SchedulingBase {
    using ERC20Integration for IERC20;

    struct AuctionData {
        uint256 blockStart;
        uint256 swapAmount;
    }

    event AuctionStart(address indexed owner, uint256 indexed jobId, uint256 blockStart);
    event AuctionSwap(
        address indexed owner,
        uint256 indexed jobId,
        address indexed swapper,
        uint256 amountBuy,
        uint256 amountSell
    );

    error AlreadyStarted();
    error Inactive();
    error Unauthorized();

    mapping(address owner => mapping(uint256 id => AuctionData data)) public auctionData;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODULE LOGIC
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * Executes a scheduled swap order
     *
     * @param jobId unique identifier for the job
     */
    function executeOrder(uint256 jobId) external override canExecute(jobId) {
        // get the execution config
        ExecutionConfig storage executionConfig = executionLog[msg.sender][jobId];

        // get the auction data
        AuctionData storage auction = auctionData[msg.sender][jobId];

        // check if the auction has already started
        if (auction.blockStart != 0) {
            revert AlreadyStarted();
        }

        // decode from executionData: tokenIn, tokenOut, amountIn
        (,, uint256 amountIn,,,) = abi.decode(
            executionConfig.executionData, (address, address, uint256, uint256, uint256, uint256)
        );

        // trigger the auction start
        auctionData[msg.sender][jobId].blockStart = block.number;
        auctionData[msg.sender][jobId].swapAmount = amountIn;

        // update the execution config
        executionConfig.lastExecutionTime = uint48(block.timestamp);
        executionConfig.numberOfExecutionsCompleted += 1;

        // emit the AuctionStart event
        emit AuctionStart(msg.sender, jobId, block.timestamp);
    }

    function swap(address swapper, uint256 jobId, uint256 amountIn) external {
        // get the auction data
        AuctionData storage auction = auctionData[msg.sender][jobId];
        // get the execution config
        ExecutionConfig storage executionConfig = executionLog[msg.sender][jobId];

        if (auction.blockStart == 0) {
            revert Inactive();
        }

        // decode from executionData: tokenIn, tokenOut, amountIn
        (
            address tokenIn,
            address tokenOut,
            uint256 amountInTotal,
            uint256 auctionBlocks,
            uint256 halvingBlocks,
            uint256 initialPrice
        ) = abi.decode(
            executionConfig.executionData, (address, address, uint256, uint256, uint256, uint256)
        );

        // check if the auction is active
        if (block.number < auction.blockStart || block.number > auction.blockStart + auctionBlocks)
        {
            revert Inactive();
        }

        // get the amount of tokenOut to be swapped
        uint256 amountOut = _calculateAmountOut(
            amountIn,
            auction.swapAmount,
            amountInTotal,
            block.number,
            auction.blockStart,
            initialPrice,
            halvingBlocks,
            auctionBlocks
        );
        auctionData[msg.sender][jobId].swapAmount -= amountOut;

        // transfer the tokens
        IERC20(tokenOut).safeTransferFrom(swapper, msg.sender, amountOut);
        Execution memory execution = ERC20Integration.transfer(IERC20(tokenIn), swapper, amountIn);

        // execute the transfer
        IERC7579Account(msg.sender).executeFromExecutor(
            ModeLib.encodeSimpleSingle(),
            ExecutionLib.encodeSingle(execution.target, execution.value, execution.callData)
        );

        // emit the AuctionSwap event
        emit AuctionSwap(msg.sender, jobId, swapper, amountIn, amountOut);
    }

    function getAmountOut(address owner, uint256 jobId) public view returns (uint256 amountOut) {
        // get the auction data
        AuctionData storage auction = auctionData[owner][jobId];
        // get the execution config
        ExecutionConfig storage executionConfig = executionLog[owner][jobId];

        // decode from executionData: tokenIn, tokenOut, amountIn
        (
            ,
            ,
            uint256 amountInTotal,
            uint256 auctionBlocks,
            uint256 halvingBlocks,
            uint256 initialPrice
        ) = abi.decode(
            executionConfig.executionData, (address, address, uint256, uint256, uint256, uint256)
        );

        // check if the auction is active
        if (block.number < auction.blockStart || block.number > auction.blockStart + auctionBlocks)
        {
            revert Inactive();
        }

        // get the amount of tokenOut to be swapped
        amountOut = _calculateAmountOut(
            auction.swapAmount,
            auction.swapAmount,
            amountInTotal,
            block.number,
            auction.blockStart,
            initialPrice,
            halvingBlocks,
            auctionBlocks
        );
    }

    function _calculateAmountOut(
        uint256 amountInBuyer,
        uint256 amountInSwap,
        uint256 amountInTotal,
        uint256 blockNumber,
        uint256 blockStart,
        uint256 initialPrice,
        uint256 halvingBlocks,
        uint256 durationBlocks
    )
        internal
        pure
        returns (uint256 amountOut)
    {
        uint256 boughtAmount = amountInTotal - amountInSwap + amountInBuyer;
        int256 exponent = (
            (int256(blockNumber) - int256(blockStart)) * 1 ether
                - (int256(boughtAmount) * 1 ether / int256(amountInTotal)) * int256(durationBlocks)
        ) / int256(halvingBlocks);
        amountOut = uint256(int256(initialPrice) * 1 ether / convert(exp2(sd(exponent))));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     METADATA
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * Returns the name of the module
     *
     * @return name of the module
     */
    function name() external pure virtual returns (string memory) {
        return "ScheduledOrders";
    }

    /**
     * Returns the version of the module
     *
     * @return version of the module
     */
    function version() external pure virtual returns (string memory) {
        return "1.0.0";
    }
}
