import { app, ipcMain } from 'electron'
import { createSaveStore } from './save-store'
import { assertWindowRequest, registerWindowHandlers } from './window-ipc'
import { startWindow } from './window'

registerWindowHandlers()
const saveStore = createSaveStore(app.getPath('userData'))
ipcMain.handle('save:read', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 0)
  return saveStore.read()
})
ipcMain.handle('save:write', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return saveStore.write(args[0])
})

startWindow('Janken Kingdom', 'save')
