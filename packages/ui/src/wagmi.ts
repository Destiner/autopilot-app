import { defaultWagmiConfig } from '@web3modal/wagmi';
import { optimism } from 'viem/chains';

import { projectId, metadata } from '@/appKit.js';

const chains = [optimism];
const config = defaultWagmiConfig({
  chains: [optimism],
  projectId,
  metadata,
  auth: {
    email: true,
    socials: ['x', 'farcaster'],
    showWallets: true,
    walletFeatures: true,
  },
});

export { chains, config };
