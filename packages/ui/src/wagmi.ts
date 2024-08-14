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
    socials: [
      'google',
      'x',
      'github',
      'discord',
      'apple',
      'facebook',
      'farcaster',
    ],
    showWallets: true,
    walletFeatures: true, // default to true
  },
});

export { chains, config };
