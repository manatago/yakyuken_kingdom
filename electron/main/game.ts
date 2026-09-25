import { app, ipcMain } from 'electron'
import { createDocumentStore } from './document-store'
import { assertWindowRequest, registerWindowHandlers } from './window-ipc'
import { startWindow } from './window'

registerWindowHandlers()
ipcMain.handle('save:read', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 0)
  return createDocumentStore(app.getPath('userData'), 'janken-save.json').read()
})
ipcMain.handle('save:write', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return createDocumentStore(app.getPath('userData'), 'janken-save.json').write(args[0])
})

startWindow('Janken Kingdom', 'save')
