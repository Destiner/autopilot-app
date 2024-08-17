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
        <div class="prompt-header">
          <div
            class="button button-connect"
            @click="open"
          >
            Connect
          </div>
          to get started
        </div>
      </div>
      <div
        v-else-if="account.status.value === 'connecting'"
        class="prompt"
      >
        <div class="prompt-header">Connecting…</div>
      </div>
      <div
        v-else-if="wrongChain"
        class="prompt"
      >
        <div class="prompt-header">
          <div
            class="button button-chain"
            @click="switchChain"
          >
            Switch to Optimism
          </div>
          to continue
        </div>
      </div>
      <div
        v-else-if="isEoa"
        class="prompt"
      >
        <div class="prompt-header">
          <div
            class="button button-account"
            @click="open"
          >
            Switch to smart account
          </div>
          to continue
        </div>
        <div>
          <button @click="markAsSmartAccount">Complete</button>
        </div>
        <div class="prompt-guide">
          <video
            src="/assets/guides/wallet_smart_account.mp4"
            autoplay
            loop
          />
        </div>
      </div>
      <div
        v-else-if="!hasBalance"
        class="prompt"
      >
        <div class="prompt-header">Fetching your balance…</div>
      </div>
      <div
        v-else-if="isEmpty"
        class="prompt"
      >
        <div class="prompt-header">
          <div
            class="button button-buy"
            @click="open"
          >
            Buy some crypto
          </div>
          to make your first swap
        </div>
        <div class="prompt-guide">
          <video
            src="/assets/guides/wallet_onramp.mp4"
            autoplay
            loop
          />
        </div>
      </div>
      <div
        v-else-if="swapType === null"
        class="swap-select-view"
      >
        <h2>Choose a swap type</h2>
        <div class="swap-cards">
          <div
            class="card"
            @click="swapType = 'instant'"
          >
            <div class="card-title">Instant</div>
            <div class="card-description">
              Make a regular swap that will execute immediately
            </div>
          </div>
          <div
            class="card"
            @click="swapType = 'gradual'"
          >
            <div class="card-title">Gradual</div>
            <div class="card-description">
              Create a swap order that will execute regularly
            </div>
          </div>
        </div>
      </div>
      <div
        v-else-if="swapType === 'instant'"
        class="swap-view"
      >
        <h2>Instant Swap</h2>
        <div class="prompt">
          <div class="prompt-header">
            <div
              class="button button-swap"
              @click="open"
            >
              Swap
            </div>
            with your wallet
          </div>
          <div class="prompt-guide">
            <video
              src="/assets/guides/wallet_swaps.mp4"
              autoplay
              loop
            />
          </div>
        </div>
        <button @click="swapType = null">Go back</button>
      </div>
      <div
        v-else-if="swapType === 'gradual'"
        class="swap-view"
      >
        <h2>Gradual Swap</h2>
        <GradualSwap />
        <button @click="swapType = null">Go back</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useIntervalFn } from '@vueuse/core';
import { useAccount, useClient, useSwitchChain } from '@wagmi/vue';
import { createWeb3Modal, useWeb3Modal } from '@web3modal/wagmi/vue';
import { Address, Hex, size } from 'viem';
import { getBalance, getCode, readContract } from 'viem/actions';
import { optimism } from 'viem/chains';
import { computed, ref, watch } from 'vue';

import erc20Abi from '@/abi/erc20.js';
import { projectId } from '@/appKit';
import GradualSwap from '@/components/GradualSwap.vue';
import { config } from '@/wagmi';

type SwapType = 'instant' | 'gradual';

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

const USDC: Address = '0x0b2c639c533813f4aa9d7837caf62653d097ff85';

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
const markedAsSmartAccount = ref<boolean>(false);
const isEoa = computed(() => {
  if (markedAsSmartAccount.value) {
    return false;
  }
  if (!addressCode.value) {
    return true;
  }
  return size(addressCode.value) === 0;
});

function markAsSmartAccount(): void {
  markedAsSmartAccount.value = true;
}

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
const usdcBalance = ref<bigint | null>(0n);
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

const swapType = ref<SwapType | null>(null);
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
  min-width: 640px;
  max-width: 640px;
  margin-top: 120px;
  gap: 64px;
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
  flex-direction: column;
  gap: 24px;
}

.prompt-header {
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

.swap-cards {
  display: flex;
  gap: 32px;
}

.card {
  display: flex;
  flex: 1;
  flex-direction: column;
  justify-content: space-between;
  min-height: 320px;
  padding: 16px;
  transition: all 0.2s ease;
  border: 2px solid rgb(189 0 189);
  border-radius: 16px;
  cursor: pointer;

  & .card-title {
    color: #0a0a0a;
    font-size: 1.5rem;
    font-weight: 200;
  }

  & .card-description {
    color: #333;
    font-size: 1rem;
    font-weight: 400;
  }

  &:hover {
    background: rgb(189 0 189);

    & .card-title {
      color: #fafafa;
    }

    & .card-description {
      color: #e2e2e2;
    }
  }
}

.swap-select-view,
.swap-view {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
</style>
