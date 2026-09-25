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
        void window.webContents.executeJavaScript(`
          new Promise((resolve, reject) => {
            const deadline = Date.now() + 5000
            const waitForHeading = () => {
              const heading = document.querySelector('main h1')?.textContent?.trim()
              if (heading) return resolve(heading)
              if (Date.now() >= deadline) return reject(new Error('Rendered heading not found'))
              setTimeout(waitForHeading, 50)
            }
            waitForHeading()
          })
        `).then((heading: string) => {
          if (heading !== title) {
            console.error(`SMOKE_FAIL Expected ${title}, rendered ${heading}`)
            app.exit(1)
            return
          }
          console.log(`SMOKE_OK ${title}`)
          app.quit()
        }).catch((error: unknown) => {
          console.error('SMOKE_FAIL', error)
          app.exit(1)
        })
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
