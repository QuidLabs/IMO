
// TODO replace address
export const addressQD = '0x6AA4B7DE8ADA0A11982dC8F32Dd74407A5e02c54';
export const addressMO = '0xB4a297773b9EFf880B2468133d60C0D7073D1D15'
export const addressSDAI = '0xF4ae7EAd9eCF1C6A302980F1C12eE1a1f7B12d7f';
export const addressSUSDE = '0x1F9cce9751a4d8498cc14646b37A615720211cc8';

export const QUID = [  {
  "inputs": [
    {
      "internalType": "address",
      "name": "_mo",
      "type": "address"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "constructor"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": true,
      "internalType": "address",
      "name": "owner",
      "type": "address"
    },
    {
      "indexed": true,
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "value",
      "type": "uint256"
    }
  ],
  "name": "Approval",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "k",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "sum_w_k",
      "type": "uint256"
    }
  ],
  "name": "Medianizer",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": true,
      "internalType": "address",
      "name": "from",
      "type": "address"
    },
    {
      "indexed": true,
      "internalType": "address",
      "name": "to",
      "type": "address"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "value",
      "type": "uint256"
    }
  ],
  "name": "Transfer",
  "type": "event"
},
{
  "inputs": [],
  "name": "DAYS",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "MAX_PER_DAY",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "Moulinette",
  "outputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "START",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "START_PRICE",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "SUM",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "WAD",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "name": "WEIGHTS",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "owner",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    }
  ],
  "name": "allowance",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    }
  ],
  "name": "approve",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "account",
      "type": "address"
    }
  ],
  "name": "balanceOf",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "blocktimestamp",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "from",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "value",
      "type": "uint256"
    }
  ],
  "name": "burn",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [],
  "name": "calc_avg_return",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "minted",
      "type": "uint256"
    },
    {
      "internalType": "uint256",
      "name": "avg_roi",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "name": "consideration",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "currentBatch",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "batch",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "decimals",
  "outputs": [
    {
      "internalType": "uint8",
      "name": "",
      "type": "uint8"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "subtractedValue",
      "type": "uint256"
    }
  ],
  "name": "decreaseAllowance",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [],
  "name": "deployed",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "period",
      "type": "uint256"
    }
  ],
  "name": "fast_forward",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "name": "feeVotes",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "getPrice",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "price",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "block_timestamp",
      "type": "uint256"
    }
  ],
  "name": "get_total_supply_cap",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "total_supply_cap",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "name": "hasVoted",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "addedValue",
      "type": "uint256"
    }
  ],
  "name": "increaseAllowance",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "account",
      "type": "address"
    }
  ],
  "name": "matureBalanceOf",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "total",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "matureBatches",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    },
    {
      "internalType": "address",
      "name": "pledge",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "token",
      "type": "address"
    }
  ],
  "name": "mint",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "cost",
      "type": "uint256"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [],
  "name": "name",
  "outputs": [
    {
      "internalType": "string",
      "name": "",
      "type": "string"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "from",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "tokenId",
      "type": "uint256"
    },
    {
      "internalType": "bytes",
      "name": "data",
      "type": "bytes"
    }
  ],
  "name": "onERC721Received",
  "outputs": [
    {
      "internalType": "bytes4",
      "name": "",
      "type": "bytes4"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "qd_amt",
      "type": "uint256"
    },
    {
      "internalType": "uint256",
      "name": "block_timestamp",
      "type": "uint256"
    }
  ],
  "name": "qd_amt_to_dollar_amt",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "restart",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [],
  "name": "symbol",
  "outputs": [
    {
      "internalType": "string",
      "name": "",
      "type": "string"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "totalSupply",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "to",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "value",
      "type": "uint256"
    }
  ],
  "name": "transfer",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "from",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "to",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "value",
      "type": "uint256"
    }
  ],
  "name": "transferFrom",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "new_vote",
      "type": "uint256"
    }
  ],
  "name": "vote",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    },
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "name": "voters",
  "outputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "stateMutability": "view",
  "type": "function"
}];

export const MO = [ {
  "inputs": [
    {
      "internalType": "address",
      "name": "_usde",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "_susde",
      "type": "address"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "constructor"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": true,
      "internalType": "address",
      "name": "previousOwner",
      "type": "address"
    },
    {
      "indexed": true,
      "internalType": "address",
      "name": "newOwner",
      "type": "address"
    }
  ],
  "name": "OwnershipTransferred",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "int24",
      "name": "upper",
      "type": "int24"
    },
    {
      "indexed": false,
      "internalType": "int24",
      "name": "lower",
      "type": "int24"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount0",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount1",
      "type": "uint256"
    }
  ],
  "name": "RepackMintingNFT",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount0",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount1",
      "type": "uint256"
    }
  ],
  "name": "RepackNFTamountsAfterCollect",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount0",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount1",
      "type": "uint256"
    }
  ],
  "name": "RepackNFTamountsAfterCollectInBurn",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount0",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount1",
      "type": "uint256"
    }
  ],
  "name": "RepackNFTamountsAfterSwap",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount0",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount1",
      "type": "uint256"
    }
  ],
  "name": "RepackNFTamountsBefore",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "int24",
      "name": "twap",
      "type": "int24"
    },
    {
      "indexed": false,
      "internalType": "int24",
      "name": "twapUpper",
      "type": "int24"
    },
    {
      "indexed": false,
      "internalType": "int24",
      "name": "twapLower",
      "type": "int24"
    }
  ],
  "name": "RepackNFTtwap",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount0",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount1",
      "type": "uint256"
    }
  ],
  "name": "SwapAmountsForLiquidity",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "delta0",
      "type": "uint256"
    }
  ],
  "name": "SwapDelta0",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "priceX96",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "sqrtPriceX96Lower",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "sqrtPriceX96Upper",
      "type": "uint256"
    }
  ],
  "name": "SwapPrices",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount0",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount1",
      "type": "uint256"
    }
  ],
  "name": "SwapSell0",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "numerator",
      "type": "uint256"
    }
  ],
  "name": "SwapSell0numerator",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount0",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "amount1",
      "type": "uint256"
    }
  ],
  "name": "SwapSell1",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "numerator",
      "type": "uint256"
    }
  ],
  "name": "SwapSell1numerator",
  "type": "event"
},
{
  "inputs": [],
  "name": "AVG_ROI",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "ID",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "MINTED",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "SUM",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "SUSDE",
  "outputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "USDC",
  "outputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "USDE",
  "outputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "WAD",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "WETH",
  "outputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "qd",
      "type": "uint256"
    },
    {
      "internalType": "bool",
      "name": "burn",
      "type": "bool"
    }
  ],
  "name": "capitalisation",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "beneficiary",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    },
    {
      "internalType": "address",
      "name": "token",
      "type": "address"
    },
    {
      "internalType": "bool",
      "name": "long",
      "type": "bool"
    }
  ],
  "name": "deposit",
  "outputs": [],
  "stateMutability": "payable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "beneficiary",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    },
    {
      "internalType": "bool",
      "name": "sell",
      "type": "bool"
    }
  ],
  "name": "fold",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "who",
      "type": "address"
    }
  ],
  "name": "get_info",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    },
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "who",
      "type": "address"
    }
  ],
  "name": "get_more_info",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    },
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    },
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    },
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "liquidityUnderManagement",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "owner",
  "outputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "renounceOwnership",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [],
  "name": "repackNFT",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "index",
      "type": "uint256"
    }
  ],
  "name": "setFee",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "avg_roi",
      "type": "uint256"
    },
    {
      "internalType": "uint256",
      "name": "minted",
      "type": "uint256"
    }
  ],
  "name": "setMetrics",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "_quid",
      "type": "address"
    }
  ],
  "name": "setQuid",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "bool",
      "name": "up",
      "type": "bool"
    },
    {
      "internalType": "bool",
      "name": "refresh",
      "type": "bool"
    }
  ],
  "name": "set_price_eth",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "from",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "to",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    }
  ],
  "name": "transferHelper",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "newOwner",
      "type": "address"
    }
  ],
  "name": "transferOwnership",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    },
    {
      "internalType": "bool",
      "name": "quid",
      "type": "bool"
    }
  ],
  "name": "withdraw",
  "outputs": [],
  "stateMutability": "payable",
  "type": "function"
}];

export const SDAI = [ {
  "inputs": [],
  "stateMutability": "nonpayable",
  "type": "constructor"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": true,
      "internalType": "address",
      "name": "owner",
      "type": "address"
    },
    {
      "indexed": true,
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "value",
      "type": "uint256"
    }
  ],
  "name": "Approval",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": true,
      "internalType": "address",
      "name": "from",
      "type": "address"
    },
    {
      "indexed": true,
      "internalType": "address",
      "name": "to",
      "type": "address"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "value",
      "type": "uint256"
    }
  ],
  "name": "Transfer",
  "type": "event"
},
{
  "inputs": [],
  "name": "WAD",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "owner",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    }
  ],
  "name": "allowance",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    }
  ],
  "name": "approve",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "account",
      "type": "address"
    }
  ],
  "name": "balanceOf",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "decimals",
  "outputs": [
    {
      "internalType": "uint8",
      "name": "",
      "type": "uint8"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "subtractedValue",
      "type": "uint256"
    }
  ],
  "name": "decreaseAllowance",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "addedValue",
      "type": "uint256"
    }
  ],
  "name": "increaseAllowance",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [],
  "name": "mint",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [],
  "name": "name",
  "outputs": [
    {
      "internalType": "string",
      "name": "",
      "type": "string"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "symbol",
  "outputs": [
    {
      "internalType": "string",
      "name": "",
      "type": "string"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "totalSupply",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "to",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    }
  ],
  "name": "transfer",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "from",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "to",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    }
  ],
  "name": "transferFrom",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
}];


export const SUSDE = [{
  "inputs": [
    {
      "internalType": "contract ERC20",
      "name": "asset",
      "type": "address"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "constructor"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": true,
      "internalType": "address",
      "name": "owner",
      "type": "address"
    },
    {
      "indexed": true,
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "value",
      "type": "uint256"
    }
  ],
  "name": "Approval",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": true,
      "internalType": "address",
      "name": "sender",
      "type": "address"
    },
    {
      "indexed": true,
      "internalType": "address",
      "name": "owner",
      "type": "address"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "assets",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "shares",
      "type": "uint256"
    }
  ],
  "name": "Deposit",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": true,
      "internalType": "address",
      "name": "from",
      "type": "address"
    },
    {
      "indexed": true,
      "internalType": "address",
      "name": "to",
      "type": "address"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "value",
      "type": "uint256"
    }
  ],
  "name": "Transfer",
  "type": "event"
},
{
  "anonymous": false,
  "inputs": [
    {
      "indexed": true,
      "internalType": "address",
      "name": "sender",
      "type": "address"
    },
    {
      "indexed": true,
      "internalType": "address",
      "name": "receiver",
      "type": "address"
    },
    {
      "indexed": true,
      "internalType": "address",
      "name": "owner",
      "type": "address"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "assets",
      "type": "uint256"
    },
    {
      "indexed": false,
      "internalType": "uint256",
      "name": "shares",
      "type": "uint256"
    }
  ],
  "name": "Withdraw",
  "type": "event"
},
{
  "inputs": [],
  "name": "WAD",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "owner",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    }
  ],
  "name": "allowance",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    }
  ],
  "name": "approve",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [],
  "name": "asset",
  "outputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "account",
      "type": "address"
    }
  ],
  "name": "balanceOf",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "shares",
      "type": "uint256"
    }
  ],
  "name": "convertToAssets",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "assets",
      "type": "uint256"
    }
  ],
  "name": "convertToShares",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "decimals",
  "outputs": [
    {
      "internalType": "uint8",
      "name": "",
      "type": "uint8"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "subtractedValue",
      "type": "uint256"
    }
  ],
  "name": "decreaseAllowance",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "assets",
      "type": "uint256"
    },
    {
      "internalType": "address",
      "name": "receiver",
      "type": "address"
    }
  ],
  "name": "deposit",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "spender",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "addedValue",
      "type": "uint256"
    }
  ],
  "name": "increaseAllowance",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "name": "maxDeposit",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "",
      "type": "address"
    }
  ],
  "name": "maxMint",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "owner",
      "type": "address"
    }
  ],
  "name": "maxRedeem",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "owner",
      "type": "address"
    }
  ],
  "name": "maxWithdraw",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "mint",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "shares",
      "type": "uint256"
    },
    {
      "internalType": "address",
      "name": "receiver",
      "type": "address"
    }
  ],
  "name": "mint",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [],
  "name": "name",
  "outputs": [
    {
      "internalType": "string",
      "name": "",
      "type": "string"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "assets",
      "type": "uint256"
    }
  ],
  "name": "previewDeposit",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "shares",
      "type": "uint256"
    }
  ],
  "name": "previewMint",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "shares",
      "type": "uint256"
    }
  ],
  "name": "previewRedeem",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "assets",
      "type": "uint256"
    }
  ],
  "name": "previewWithdraw",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "shares",
      "type": "uint256"
    },
    {
      "internalType": "address",
      "name": "receiver",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "owner",
      "type": "address"
    }
  ],
  "name": "redeem",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [],
  "name": "symbol",
  "outputs": [
    {
      "internalType": "string",
      "name": "",
      "type": "string"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "totalAssets",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [],
  "name": "totalSupply",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "view",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "to",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    }
  ],
  "name": "transfer",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "address",
      "name": "from",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "to",
      "type": "address"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    }
  ],
  "name": "transferFrom",
  "outputs": [
    {
      "internalType": "bool",
      "name": "",
      "type": "bool"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
},
{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "assets",
      "type": "uint256"
    },
    {
      "internalType": "address",
      "name": "receiver",
      "type": "address"
    },
    {
      "internalType": "address",
      "name": "owner",
      "type": "address"
    }
  ],
  "name": "withdraw",
  "outputs": [
    {
      "internalType": "uint256",
      "name": "",
      "type": "uint256"
    }
  ],
  "stateMutability": "nonpayable",
  "type": "function"
}];