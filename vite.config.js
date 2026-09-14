import { fileURLToPath, URL } from 'node:url'
import process from 'node:process'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

const repositoryName = process.env.GITHUB_REPOSITORY?.split('/')[1]
const githubPagesBase = repositoryName ? `/${repositoryName}/` : '/'

// https://vite.dev/config/
export default defineConfig({
  // GitHub Pages project sites are served below /<repository-name>/.
  // VITE_BASE_PATH can override this for a custom domain or another host.
  base: process.env.VITE_BASE_PATH || (process.env.GITHUB_ACTIONS ? githubPagesBase : '/'),
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
})
