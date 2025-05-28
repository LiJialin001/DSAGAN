import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://172.16.2.131:8001',
        changeOrigin: true,
        // rewrite: (path) => path.replace(/^\/api/, '')
      },
      '/uploads/api': {
        target: 'http://172.16.2.131:8001',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/uploads\/api/, '')
      },
      // '/reconstruction/api': {
      //   target: 'http://172.16.0.55:8000',
      //   changeOrigin: true,
      //   rewrite: (path) => path.replace(/^\/reconstruction\/api/, '')
      // }
    }
  }
})
