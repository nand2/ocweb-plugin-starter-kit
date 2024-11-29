import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  // Starter Kit Plugin: Added this setting so that the app can be served from any subdirectory
  base: "./",
  build: {
    target: "esnext"
  },
})
