<template>
  <div class="page">
    <div class="content">
      <div class="header">
        <h1>autopilot</h1>
        <h2>buy and sell crypto automatically, at the best rates</h2>
      </div>
      <div
        v-if="!account.address.value || account.status.value === 'disconnected'"
        class="prompt"
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
        v-else-if="wrongChain"
        class="prompt"
      >
        <div
          class="button button-chain"
          @click="switchChain"
        >
          Switch to Optimism
        </div>
        to continue
      </div>
      <div
        v-else-if="isEoa"
        class="prompt"
      >
        <div
          class="button button-account"
          @click="open"
        >
          Switch to smart account
        </div>
        to continue
      </div>
      <div
        v-else-if="!hasBalance"
        class="prompt"
      >
        Fetching your balance…
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
        <h2>Balance</h2>
        <div>
          <span v-if="ethBalance !== null">{{ ethBalance }}</span>
          <span v-else>???</span> ETH
        </div>
        <div>
          <span v-if="usdcBalance !== null">{{ usdcBalance }}</span>
          <span v-else>???</span>
          USDC
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useIntervalFn } from '@vueuse/core';
import { useAccount, useClient, useSwitchChain } from '@wagmi/vue';
import { createWeb3Modal, useWeb3Modal } from '@web3modal/wagmi/vue';
import { Address, Hex, size } from 'viem';
import { readContract, getBalance, getCode } from 'viem/actions';
import { optimism } from 'viem/chains';
import { computed, ref, watch } from 'vue';

import erc20Abi from '@/abi/erc20.js';
import { projectId } from '@/appKit';
import { config } from '@/wagmi';

createWeb3Modal({
  wagmiConfig: config,
  projectId,
  enableAnalytics: true,
  enableOnramp: true,
  enableSwaps: true,
});

const { open: openModal } = useWeb3Modal();
const { chains, switchChain: switchAccountChain } = useSwitchChain();
const account = useAccount();
const client = useClient();

const USDC: Address = '0x7f5c764cbc14f9669b88837ca1490cca17c31607';

function open(): void {
  console.log('open modal');
  openModal();
}

function switchChain(): void {
  console.log('switch chain', chains);
  switchAccountChain({
    chainId: optimism.id,
  });
}

const wrongChain = computed(() => {
  if (!account.chainId.value) {
    return false;
  }
  return account.chainId.value !== optimism.id;
});

const addressCode = ref<Hex | null>(null);
const isEoa = computed(() => {
  if (!addressCode.value) {
    return true;
  }
  return size(addressCode.value) === 0;
});

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

const ethBalance = ref<bigint | null>(null);
const usdcBalance = ref<bigint | null>(null);
const hasBalance = computed(
  () => ethBalance.value !== null && usdcBalance.value !== null,
);

async function fetchEthBalance(): Promise<void> {
  const address = account.address.value;
  if (!address) {
    return;
  }
  if (!client.value) {
    return;
  }
  const balance = await getBalance(client.value, {
    address,
  });
  ethBalance.value = balance;
}

async function fetchUsdcBalance(): Promise<void> {
  const address = account.address.value;
  if (!address) {
    return;
  }
  if (!client.value) {
    return;
  }
  const balance = await readContract(client.value, {
    abi: erc20Abi,
    address: USDC,
    functionName: 'balanceOf',
    args: [address],
  });
  usdcBalance.value = balance;
}

const isEmpty = computed(() => {
  if (ethBalance.value === null || usdcBalance.value === null) {
    return true;
  }
  const hasEth = ethBalance.value > 0n;
  const hasUsdc = usdcBalance.value > 0n;
  return !hasEth && !hasUsdc;
});

watch(account.address, () => {
  fetchCode();
  fetchEthBalance();
  fetchUsdcBalance();
});

useIntervalFn(() => {
  fetchEthBalance();
  fetchUsdcBalance();
}, 5 * 1000);
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

.prompt {
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

.button-chain {
  border-color: #ff0421;
  color: #ff0421;
}

.button-buy {
  border-color: #25d962;
  color: #25d962;
}

.button-account {
  border-color: #270005;
  color: #270005;
}
</style>
