import { app, ipcMain } from 'electron'
import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { createContentStore } from './content-store'
import { assertWindowRequest, registerWindowHandlers } from './window-ipc'
import { startWindow } from './window'

registerWindowHandlers()
const contentStore = createContentStore(app.getPath('userData'), (path) => existsSync(join(app.getAppPath(), path)))
ipcMain.handle('content:read', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 0)
  return contentStore.read()
})
ipcMain.handle('content:write', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return contentStore.write(args[0])
})

startWindow('Janken Editor', 'content')
