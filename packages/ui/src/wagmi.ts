import { defaultWagmiConfig } from '@web3modal/wagmi';
import { base } from 'viem/chains';

import { projectId, metadata } from '@/appKit.js';

const chains = [base];
const config = defaultWagmiConfig({
  chains: [base],
  projectId,
  metadata,
});

export { chains, config };
