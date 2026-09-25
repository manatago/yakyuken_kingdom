import { app, BrowserWindow } from 'electron'
import { join } from 'node:path'

export function startWindow(title: string): void {
  const createWindow = (): void => {
    const window = new BrowserWindow({
      width: 1280,
      height: 720,
      title,
      webPreferences: {
        preload: join(__dirname, '../preload/index.js'),
        contextIsolation: true,
        sandbox: true,
        nodeIntegration: false
      }
    })

    if (process.argv.includes('--smoke-test')) {
      window.webContents.once('did-finish-load', () => {
        console.log(`SMOKE_OK ${title}`)
        app.quit()
      })
      window.webContents.once('did-fail-load', (_event, code, message) => {
        console.error(`SMOKE_FAIL ${code} ${message}`)
        app.exit(1)
      })
    }

    const devUrl = process.env.ELECTRON_RENDERER_URL
    if (devUrl) {
      void window.loadURL(devUrl)
    } else {
      void window.loadFile(join(__dirname, '../renderer/index.html'))
    }
  }

  void app.whenReady().then(() => {
    createWindow()
    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) createWindow()
    })
  })

  app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit()
  })
}
