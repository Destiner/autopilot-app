<template>
  <div id="app">
    <router-view />
  </div>
</template>

<script setup>
import { createWeb3Modal } from '@web3modal/wagmi';

import { projectId } from '@/appKit';
import { config } from '@/wagmi';

createWeb3Modal({
  themeMode: 'light',
  wagmiConfig: config,
  projectId,
  enableAnalytics: true,
  enableOnramp: true,
  enableSwaps: true,
});
</script>

<style>
:root {
  --font-sans: -apple-system, 'BlinkMacSystemFont', avenir next, avenir,
    segoe ui, helvetica neue, helvetica, 'Ubuntu', roboto, noto, arial,
    sans-serif;
  --font-serif: 'Iowan Old Style', 'Apple Garamond', 'Baskerville',
    'Times New Roman', 'Droid Serif', 'Times', 'Source Serif Pro', serif,
    'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol';
  --font-mono: 'Menlo', 'Consolas', 'Monaco', 'Liberation Mono',
    'Lucida Console', monospace;
}

body {
  margin: 0;
  background-color: #f9fafb;
  font-family: var(--font-sans);
}

/* Reset */

*,
*::before,
*::after {
  box-sizing: border-box;
}

html,
body {
  height: 100%;
}

img,
picture,
video,
canvas,
svg {
  display: block;
  max-width: 100%;
}

input,
button,
textarea,
select {
  font: inherit;
}

p,
h1,
h2,
h3,
h4,
h5,
h6 {
  overflow-wrap: break-word;
}

#app {
  isolation: isolate;
}
</style>
