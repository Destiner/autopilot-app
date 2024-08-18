<template>
  <div>
    <div class="input-wrapper">
      <div class="input">
        <input v-model="amountString" />
        USDC
      </div>
    </div>
    <button @click="swap">Swap</button>
  </div>
</template>

<script setup lang="ts">
import { getCapabilities, sendCalls } from '@wagmi/core/experimental';
import { useAccount, useClient } from '@wagmi/vue';
import { encodeFunctionData, Hex, parseEther, parseUnits } from 'viem';
import { getCode } from 'viem/actions';
import { ref, watchEffect } from 'vue';

import auctionHouseAbi from '@/abi/auctionHouse.js';
import erc20Abi from '@/abi/erc20.js';
import { CHAIN, config } from '@/wagmi';

const account = useAccount();
const client = useClient();

const auctionHouseAddress = '0x0560e40aEcC81b6DAd43Fdca93F0800a5B7bf89E';

const addressCode = ref<Hex | null>(null);
async function fetchCode(): Promise<void> {
  const address = account.address.value;
  if (!address) {
    return;
  }
  if (!client.value) {
    return;
  }
  const code = await getCode(client.value, {
    address,
  });
  addressCode.value = code || null;
}

async function fetcSmartAccount(): Promise<void> {
  await fetchCode();
}

watchEffect(() => {
  fetcSmartAccount();
});

const WETH = '0x4200000000000000000000000000000000000006';
const USDC = '0x0b2c639c533813f4aa9d7837caf62653d097ff85';

const amountString = ref<string>('');

function generateRandomUint256(): bigint {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return BigInt(
    `0x${Array.from(array, (b) => b.toString(16).padStart(2, '0')).join('')}`,
  );
}

async function swap(): Promise<void> {
  if (!client.value) {
    return;
  }
  const capabilities = await getCapabilities(config);
  console.log(capabilities);
  const supportsAtomicBatch = capabilities[CHAIN.id]?.atomicBatch?.supported;
  if (!supportsAtomicBatch) {
    return;
  }

  const id = generateRandomUint256();

  const callId = await sendCalls(config, {
    calls: [
      {
        to: USDC,
        data: encodeFunctionData({
          abi: erc20Abi,
          functionName: 'approve',
          args: [auctionHouseAddress, parseUnits(amountString.value, 6)],
        }),
      },
      {
        to: auctionHouseAddress,
        data: encodeFunctionData({
          abi: auctionHouseAbi,
          functionName: 'createOrder',
          args: [
            id,
            USDC,
            WETH,
            parseUnits(amountString.value, 6),
            100n,
            50n,
            parseEther('1'),
          ],
        }),
      },
    ],
  });
  console.log('swap 5', callId);
}
</script>

<style scoped>
.input-wrapper {
  display: flex;
}

.input {
  display: flex;
  flex-direction: row;
  padding: 4px;
  border: 2px solid rgb(189 0 189);
  border-radius: 4px;
  gap: 8px;
  font-size: 24px;
}

input {
  width: 120px;
  border: none;
  outline: none;
  background: transparent;
  text-align: right;
}

button {
  margin-top: 8px;
  padding: 4px 8px;
  border: none;
  border-radius: 4px;
  background: rgb(189 0 189);
  color: white;
  font-size: 20px;
  cursor: pointer;
}
</style>
