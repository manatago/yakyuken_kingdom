import { app, ipcMain, net, protocol } from 'electron'
import { resolve } from 'node:path'
import { pathToFileURL } from 'node:url'
import { mkdirSync } from 'node:fs'
import { createProjectLayoutStore } from './project-layout-store'
import { assertWindowRequest, registerWindowHandlers } from './window-ipc'
import { startWindow } from './window'
import { createDeveloperPlay } from './developer-play'
import { createStoryCommandStore } from './story-command-store'
import { createProjectImages } from './project-images'
import { createTraceCommandStore } from './trace-command-store'

protocol.registerSchemesAsPrivileged([{ scheme: 'janken-project-image', privileges: { standard: true, secure: true, supportFetchAPI: true, corsEnabled: true } }])
if (!app.commandLine.hasSwitch('user-data-dir')) {
  const editorData = resolve(app.getPath('appData'), 'Janken Kingdom Editor')
  mkdirSync(editorData, { recursive: true })
  app.setPath('userData', editorData)
}

registerWindowHandlers()
const rootArgument = process.argv.find((argument) => argument.startsWith('--content-root='))
const projectRoot = rootArgument?.slice('--content-root='.length) ?? resolve(__dirname, '../../..')
const contentStore = createProjectLayoutStore(projectRoot)
const storyStore = createStoryCommandStore(projectRoot)
const images = createProjectImages(projectRoot)
const traceStore = createTraceCommandStore(projectRoot)
ipcMain.handle('content:trace-catalog', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 0)
  return traceStore.catalog()
})
ipcMain.handle('content:trace-read', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 2)
  return traceStore.read(args[0], args[1])
})
ipcMain.handle('content:trace-write', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return traceStore.write(args[0])
})
void app.whenReady().then(() => protocol.handle('janken-project-image', async request => {
  try {
    const url = new URL(request.url)
    if (request.method !== 'GET' || url.hostname !== 'project' || url.pathname !== '/' || url.searchParams.size !== 1) return new Response(null, { status: 400 })
    const response = await net.fetch(pathToFileURL(await images.resolve(url.searchParams.get('path'))).href)
    const headers = new Headers(response.headers)
    headers.set('Access-Control-Allow-Origin', '*')
    headers.set('Cache-Control', 'no-store')
    return new Response(response.body, { status: response.status, headers })
  } catch { return new Response(null, { status: 404 }) }
}))
ipcMain.handle('content:image-catalog', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 0)
  return images.catalog()
})
ipcMain.handle('content:story-read', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return storyStore.read(args[0])
})
ipcMain.handle('content:story-write', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return storyStore.write(args[0])
})
const developerPlay = createDeveloperPlay(resolve(projectRoot, 'dist/game/main/index.js'))
ipcMain.handle('content:launch-jump', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return developerPlay.launch(args[0])
})
ipcMain.handle('content:read', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 0)
  return contentStore.read()
})
ipcMain.handle('content:write', (event, ...args: unknown[]) => {
  assertWindowRequest(event, args, 1)
  return contentStore.write(args[0])
})

startWindow('Janken Editor', 'content')
