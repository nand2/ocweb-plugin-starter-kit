<script setup>
import { ref, computed, defineProps } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';

import MarkdownPage from './MarkdownPage.vue';

const props = defineProps({
  page: {
    type: Object,
  },
})

// Fetch the /variables.json from the injected variables plugin
const { isSuccess: variablesIsSuccess, data: variables } = useQuery({
  queryKey: ['injectedVariables'],
  queryFn: async () => {
    const response = await fetch(`/variables.json`);
    if (!response.ok) {
      throw new Error('Network response was not ok');
    }
    return response.json();
  }
});


</script>

<template>
  <div class="body">

    <MarkdownPage v-if="page" :page="page" />
    
    <div v-else>
      <h2>
        Welcome to your website
      </h2>

      <p>
        Your website is a smart contract, accessible via the <a href="web3://web3url.eth" target="_blank"><code style="font-weight: bold;">web3://</code></a> protocol with a native browser, or via an HTTPS gateway.
      </p>

      <div v-if="variablesIsSuccess" class="web3Address">
        web3://{{ variables.self }}
      </div>

      <p>
        In short, <code style="font-weight: bold;">web3://</code> is like <code style="font-weight: bold;">https://</code>, but websites are smart contracts, and the blockchain is the server.
      </p>

      <h3>
        OCWebsite
      </h3>

      <div class="ocwebsite-section">
        <img src="/logo.svg" class="logo" />
        <div>
          <p style="margin-top: 0">
            Your website is an OCWebsite : a <code style="font-weight: bold;">web3://</code> website prepackaged with a plugin system and an admin interface. It appears as a NFT in your wallet.
          </p>

          <p>
            You can configure your OCWebsite, add/remove plugins by going to your <a href="/admin/">admin section</a>.
          </p>

          <p style="text-align: center;">
            <a href="web3://ocweb.eth" target="_blank" class="btn" style="font-size: 0.9em;">
              Mint another OCWebsite at web3://ocweb.eth
            </a>
          </p>
        </div>
      </div>


      <h3>
        Theme About Me
      </h3>

      <p>
        You are currently using the "About Me" theme plugin, which let you present yourself with some static pages, and links to external pages. Configure it in your <a href="/admin/">admin section</a>.
      </p>

      
    </div>
  </div>
</template>

<style scoped>
.body {
  flex: 1 1 500px;
}

.logo {
  height: 6em;
  
  will-change: filter;
  transition: filter 300ms;
}

.web3Address {
  font-family: monospace;
  padding: 0.8em 1.3em;
  font-size: 1.0em;
  border: 1px solid #555;
  background-color: var(--color-button-bg);
  margin-bottom: 1em;
  word-break: break-all;
  text-align: center;
}
@media (prefers-color-scheme: light) {
  .web3Address {
    border-color: #ccc;
  }
}

.ocwebsite-section {
  display: flex;
  gap: 2em;
}
.ocwebsite-section img {
  /* margin-top: 1.17em; */
}

@media (max-width: 800px) {
  .ocwebsite-section {
    flex-direction: column;
    gap: 1em;
  }
}




</style>
