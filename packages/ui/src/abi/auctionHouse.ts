const abi = [
  {
    inputs: [],
    name: 'AlreadyStarted',
    type: 'error',
  },
  {
    inputs: [],
    name: 'Inactive',
    type: 'error',
  },
  {
    inputs: [
      {
        internalType: 'SD59x18',
        name: 'x',
        type: 'int256',
      },
    ],
    name: 'PRBMath_SD59x18_Exp2_InputTooBig',
    type: 'error',
  },
  {
    inputs: [],
    name: 'Unauthorized',
    type: 'error',
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: 'address',
        name: 'owner',
        type: 'address',
      },
      {
        indexed: true,
        internalType: 'uint256',
        name: 'id',
        type: 'uint256',
      },
      {
        indexed: false,
        internalType: 'uint256',
        name: 'blockStart',
        type: 'uint256',
      },
    ],
    name: 'AuctionStart',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: 'address',
        name: 'owner',
        type: 'address',
      },
      {
        indexed: true,
        internalType: 'uint256',
        name: 'id',
        type: 'uint256',
      },
      {
        indexed: true,
        internalType: 'address',
        name: 'swapper',
        type: 'address',
      },
      {
        indexed: false,
        internalType: 'uint256',
        name: 'amountBuy',
        type: 'uint256',
      },
      {
        indexed: false,
        internalType: 'uint256',
        name: 'amountSell',
        type: 'uint256',
      },
    ],
    name: 'AuctionSwap',
    type: 'event',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'owner',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'id',
        type: 'uint256',
      },
    ],
    name: 'auctionData',
    outputs: [
      {
        internalType: 'address',
        name: 'tokenIn',
        type: 'address',
      },
      {
        internalType: 'address',
        name: 'tokenOut',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'amountInTotal',
        type: 'uint256',
      },
      {
        internalType: 'uint256',
        name: 'auctionBlocks',
        type: 'uint256',
      },
      {
        internalType: 'uint256',
        name: 'halvingBlocks',
        type: 'uint256',
      },
      {
        internalType: 'uint256',
        name: 'initialPrice',
        type: 'uint256',
      },
      {
        internalType: 'uint256',
        name: 'blockStart',
        type: 'uint256',
      },
      {
        internalType: 'uint256',
        name: 'swapAmount',
        type: 'uint256',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'uint256',
        name: 'id',
        type: 'uint256',
      },
      {
        internalType: 'address',
        name: 'tokenIn',
        type: 'address',
      },
      {
        internalType: 'address',
        name: 'tokenOut',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'amountInTotal',
        type: 'uint256',
      },
      {
        internalType: 'uint256',
        name: 'auctionBlocks',
        type: 'uint256',
      },
      {
        internalType: 'uint256',
        name: 'halvingBlocks',
        type: 'uint256',
      },
      {
        internalType: 'uint256',
        name: 'initialPrice',
        type: 'uint256',
      },
    ],
    name: 'createOrder',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'swapper',
        type: 'address',
      },
      {
        internalType: 'address',
        name: 'owner',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'id',
        type: 'uint256',
      },
      {
        internalType: 'uint256',
        name: 'amountIn',
        type: 'uint256',
      },
    ],
    name: 'swap',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
] as const;

export default abi;
