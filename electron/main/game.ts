import { app, ipcMain } from 'electron'
import { createSaveStore } from './save-store'
import { assertWindowRequest, registerWindowHandlers } from './window-ipc'
import { startWindow } from './window'

registerWindowHandlers()
ipcMain.handle('save:read', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 0)
  return createSaveStore(app.getPath('userData')).read()
})
ipcMain.handle('save:write', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return createSaveStore(app.getPath('userData')).write(args[0])
})

startWindow('Janken Kingdom', 'save')
