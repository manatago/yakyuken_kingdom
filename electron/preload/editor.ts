import { contextBridge, ipcRenderer } from 'electron'
import type { EditorApi } from './api'
import { windowControls } from './window-controls'

const api = {
  windowControls,
  content: {
    read: (): Promise<Record<string, unknown> | null> => ipcRenderer.invoke('content:read'),
    write: (document: unknown): Promise<void> => ipcRenderer.invoke('content:write', document)
  }
} satisfies EditorApi

contextBridge.exposeInMainWorld('janken', api)
