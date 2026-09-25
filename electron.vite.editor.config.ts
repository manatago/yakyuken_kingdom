import { resolve } from 'node:path'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'electron-vite'

export default defineConfig({
  main: {
    build: {
      outDir: resolve('dist/editor/main'),
      rollupOptions: { input: { index: resolve('electron/main/editor.ts') } }
    }
  },
  preload: {
    build: {
      outDir: resolve('dist/editor/preload'),
      rollupOptions: { input: { index: resolve('electron/preload/index.ts') } }
    }
  },
  renderer: {
    root: resolve('electron/editor'),
    base: './',
    plugins: [react()],
    build: {
      outDir: resolve('dist/editor/renderer'),
      rollupOptions: { input: { index: resolve('electron/editor/index.html') } }
    }
  }
})
