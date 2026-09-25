import { contextBridge, ipcRenderer } from 'electron'
import type { GameApi } from './api'
import { windowControls } from './window-controls'

const api = {
  windowControls,
  save: {
    read: (): Promise<Record<string, unknown> | null> => ipcRenderer.invoke('save:read'),
    write: (document: unknown): Promise<void> => ipcRenderer.invoke('save:write', document)
  }
} satisfies GameApi

contextBridge.exposeInMainWorld('janken', api)
