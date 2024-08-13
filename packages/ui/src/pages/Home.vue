<template>
  <div class="page">
    <div class="content">
      <div class="header">
        <h1>autopilot</h1>
        <h2>buy and sell crypto automatically, at the best rates</h2>
      </div>
      <div
        v-if="!account.address"
        class="connect-prompt"
      >
        <div
          class="button button-connect"
          @click="open"
        >
          Connect
        </div>
        to get started
      </div>
      <div
        v-else-if="isEmpty"
        class="fund-prompt"
      >
        <div
          class="button button-buy"
          @click="open"
        >
          Buy some crypto
        </div>
        to make your first swap
      </div>
      <div v-else>
        <h2>ETH Balance</h2>
        <p>{{ ethBalance.data.value.value / 1e18 }} ETH</p>
        <p>{{ usdcBalance.data / 1e6 }} USDC</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useAccount, useBalance, useReadContract } from '@wagmi/vue';
import { computed, watchEffect } from 'vue';

import erc20Abi from '@/abi/erc20.js';

const account = useAccount();

const USDC = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913';

const ethBalance = useBalance({
  address: account.address,
});
const usdcBalance = useReadContract({
  abi: erc20Abi,
  address: USDC,
  functionName: 'balanceOf',
  args: [account.address],
});

const isEmpty = computed(() => {
  const hasEth = ethBalance.data.value.value > 0n;
  const hasUsdc = usdcBalance.data > 0n;
  return !hasEth && !hasUsdc;
});

watchEffect(() => {
  if (account.address) {
    console.log('Connected:', account.address);
  }
});
</script>

<style scoped>
.page {
  display: flex;
  justify-content: center;
  height: 100vh;
}

.content {
  display: flex;
  flex-direction: column;
  max-width: 640px;
  margin-top: 120px;
  gap: 32px;
}

.header {
  display: flex;
  gap: 8px;
  flex-direction: column;
}

h1 {
  margin: 0;
  font-size: 2.5rem;
  font-weight: 200;
}

h2 {
  margin: 0;
  font-size: 1.5rem;
  font-weight: 400;
}

.fund-prompt,
.connect-prompt {
  display: flex;
  gap: 8px;
  align-items: center;
}

.button {
  padding: 4px;
  border: 1px solid black;
  border-radius: 4px;
  cursor: pointer;
}

.button-connect {
  border-color: #5773ff;
  color: #5773ff;
}

.button-buy {
  border-color: #25d962;
  color: #25d962;
}
</style>
