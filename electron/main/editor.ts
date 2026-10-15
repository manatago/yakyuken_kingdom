import { ipcMain } from 'electron'
import { resolve } from 'node:path'
import { createProjectLayoutStore } from './project-layout-store'
import { assertWindowRequest, registerWindowHandlers } from './window-ipc'
import { startWindow } from './window'

registerWindowHandlers()
const rootArgument = process.argv.find((argument) => argument.startsWith('--content-root='))
const contentStore = createProjectLayoutStore(rootArgument?.slice('--content-root='.length) ?? resolve(__dirname, '../../..'))
ipcMain.handle('content:read', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 0)
  return contentStore.read()
})
ipcMain.handle('content:write', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return contentStore.write(args[0])
})

startWindow('Janken Editor', 'content')
