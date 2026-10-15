import { contextBridge, ipcRenderer } from 'electron'
import type { GameApi } from './api'
import type { SaveData } from '../../packages/domain/save'
import { windowControls } from './window-controls'

const api = {
  windowControls,
  save: {
    read: (): Promise<SaveData | null> => ipcRenderer.invoke('save:read'),
    write: (document: SaveData): Promise<void> => ipcRenderer.invoke('save:write', document)
  }
} satisfies GameApi

contextBridge.exposeInMainWorld('janken', api)
