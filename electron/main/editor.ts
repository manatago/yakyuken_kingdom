import { app, ipcMain } from 'electron'
import { createDocumentStore } from './document-store'
import { assertWindowRequest, registerWindowHandlers } from './window-ipc'
import { startWindow } from './window'

registerWindowHandlers()
ipcMain.handle('content:read', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 0)
  return createDocumentStore(app.getPath('userData'), 'editor-content.json').read()
})
ipcMain.handle('content:write', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return createDocumentStore(app.getPath('userData'), 'editor-content.json').write(args[0])
})

startWindow('Janken Editor', 'content')
