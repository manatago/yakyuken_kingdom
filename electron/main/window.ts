import { app, BrowserWindow } from 'electron'
import { join } from 'node:path'
import { authorizeWindow } from './window-ipc'

export function startWindow(title: string, capability: string): void {
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
    authorizeWindow(window)
    window.webContents.setWindowOpenHandler(() => ({ action: 'deny' }))
    window.webContents.on('will-navigate', (event) => event.preventDefault())

    if (process.argv.includes('--smoke-test')) {
      window.webContents.once('did-finish-load', () => {
        void window.webContents.executeJavaScript(`
          new Promise((resolve, reject) => {
            const deadline = Date.now() + 5000
            const waitForHeading = () => {
              const heading = document.querySelector('main h1')?.textContent?.trim()
              if (heading) return resolve({
                heading,
                bridgeKeys: Object.keys(globalThis.janken ?? {}).sort(),
                windowKeys: Object.keys(globalThis.janken?.windowControls ?? {}).sort(),
                hasNodeRequire: typeof globalThis.require !== 'undefined'
              })
              if (Date.now() >= deadline) return reject(new Error('Rendered heading not found'))
              setTimeout(waitForHeading, 50)
            }
            waitForHeading()
          })
        `).then(async (result: {
          heading: string
          bridgeKeys: string[]
          windowKeys: string[]
          hasNodeRequire: boolean
        }) => {
          const expectedKeys = [capability, 'windowControls'].sort().join(',')
          if (result.heading !== title || result.bridgeKeys.join(',') !== expectedKeys ||
              result.windowKeys.join(',') !== 'close,minimize,toggleMaximize' || result.hasNodeRequire) {
            throw new Error(`Unexpected screen or bridge for ${title}: ${JSON.stringify(result)}`)
          }
          const rejectsInvalidWrite: boolean = await window.webContents.executeJavaScript(
            `globalThis.janken[${JSON.stringify(capability)}].write(null).then(() => false, () => true)`
          )
          if (!rejectsInvalidWrite) throw new Error(`Invalid IPC payload was accepted for ${title}`)
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
