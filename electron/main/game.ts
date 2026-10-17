import { app, ipcMain } from 'electron'
import { createSaveStore } from './save-store'
import { assertWindowRequest, registerWindowHandlers } from './window-ipc'
import { startWindow } from './window'
import { resolve } from 'node:path'
import { createEditorLauncher } from './editor-launcher'

registerWindowHandlers()
const openEditor = createEditorLauncher(resolve(__dirname, '../../editor/main/index.js'))
ipcMain.handle('launcher:open-editor', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return openEditor(args[0])
})
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
