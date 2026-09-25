import { resolve } from 'node:path'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'electron-vite'

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
      rollupOptions: { input: { index: resolve('electron/preload/index.ts') } }
    }
  },
  renderer: {
    root: resolve('electron/renderer'),
    base: './',
    plugins: [react()],
    build: {
      outDir: resolve('dist/game/renderer'),
      rollupOptions: { input: { index: resolve('electron/renderer/index.html') } }
    }
  }
})
