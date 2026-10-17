import { resolve } from 'node:path'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'electron-vite'
import { contentAssetPlugin } from './electron.asset-plugin'

export default defineConfig({
  main: {
    build: {
      outDir: resolve('dist/game/main'),
      rollupOptions: { input: { index: resolve('electron/main/game.ts') } }
    }
  },
  preload: {
    build: {
      outDir: resolve('dist/game/preload'),
      rollupOptions: { input: { index: resolve('electron/preload/game.ts') } }
    }
  },
  renderer: {
    root: resolve('electron/renderer'),
    base: './',
    plugins: [react(), contentAssetPlugin()],
    build: {
      outDir: resolve('dist/game/renderer'),
      rollupOptions: { input: { index: resolve('electron/renderer/index.html') } }
    }
  }
})
