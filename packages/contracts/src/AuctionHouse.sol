// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { convert, exp2, sd } from "@prb/math/SD59x18.sol";

/**
 * @title AuctionHouse
 * @dev A public auction house contract that uses gradual dutch auctions to sell tokens over time
 * @author Timur Badretdinov
 */
contract AuctionHouse {
    error AlreadyStarted();
    error Inactive();
    error Unauthorized();

    event AuctionStart(address indexed owner, uint256 indexed id, uint256 blockStart);
    event AuctionSwap(
        address indexed owner,
        uint256 indexed id,
        address indexed swapper,
        uint256 amountBuy,
        uint256 amountSell
    );

    struct AuctionData {
        address tokenIn;
        address tokenOut;
        uint256 amountInTotal;
        uint256 auctionBlocks;
        uint256 halvingBlocks;
        uint256 initialPrice;
        uint256 blockStart;
        uint256 swapAmount;
    }

    mapping(address owner => mapping(uint256 id => AuctionData data)) public auctionData;

    function createOrder(
        uint256 id,
        address tokenIn,
        address tokenOut,
        uint256 amountInTotal,
        uint256 auctionBlocks,
        uint256 halvingBlocks,
        uint256 initialPrice
    )
        external
    {
        // create an auction order
        AuctionData storage auction = auctionData[msg.sender][id];

        if (auction.blockStart != 0) {
            revert AlreadyStarted();
        }

        auction.tokenIn = tokenIn;
        auction.tokenOut = tokenOut;
        auction.amountInTotal = amountInTotal;
        auction.auctionBlocks = auctionBlocks;
        auction.halvingBlocks = halvingBlocks;
        auction.initialPrice = initialPrice;
        auction.blockStart = block.number;
        auction.swapAmount = amountInTotal;

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountInTotal);

        // emit the AuctionStart event
        emit AuctionStart(msg.sender, id, block.timestamp);
    }

    function getAmountOut(
        address owner,
        uint256 id,
        uint256 amountIn
    )
        public
        view
        returns (uint256 amountOut)
    {
        // get the auction data
        AuctionData storage auction = auctionData[owner][id];

        // check if the auction is active
        if (
            block.number < auction.blockStart
                || block.number > auction.blockStart + auction.auctionBlocks
        ) {
            revert Inactive();
        }

        // get the amount of tokenOut to be swapped
        amountOut = _calculateAmountOut(
            amountIn,
            auction.swapAmount,
            auction.amountInTotal,
            block.number,
            auction.blockStart,
            auction.initialPrice,
            auction.halvingBlocks,
            auction.auctionBlocks
        );
    }

    function swap(address swapper, address owner, uint256 id, uint256 amountIn) external {
        // get the auction data
        AuctionData storage auction = auctionData[owner][id];

        if (auction.blockStart == 0) {
            revert Inactive();
        }

        // check if the auction is active
        if (
            block.number < auction.blockStart
                || block.number > auction.blockStart + auction.auctionBlocks
        ) {
            revert Inactive();
        }

        // get the amount of tokenOut to be swapped
        uint256 amountOut = _calculateAmountOut(
            amountIn,
            auction.swapAmount,
            auction.amountInTotal,
            block.number,
            auction.blockStart,
            auction.initialPrice,
            auction.halvingBlocks,
            auction.auctionBlocks
        );
        auctionData[owner][id].swapAmount -= amountOut;

        // transfer the tokens
        IERC20(auction.tokenOut).transferFrom(swapper, owner, amountOut);
        IERC20(auction.tokenIn).transfer(swapper, amountIn);

        // emit the AuctionSwap event
        emit AuctionSwap(owner, id, swapper, amountIn, amountOut);
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
}
