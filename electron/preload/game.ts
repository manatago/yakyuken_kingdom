import { contextBridge, ipcRenderer } from 'electron'
import type { GameApi, EditorView } from './api'
import type { SaveData } from '../../packages/domain/save'
import { windowControls } from './window-controls'

const api = {
  windowControls,
  launcher: { openEditor: (view: EditorView): Promise<void> => ipcRenderer.invoke('launcher:open-editor', view) },
  save: {
    read: (): Promise<SaveData | null> => ipcRenderer.invoke('save:read'),
    write: (document: SaveData): Promise<void> => ipcRenderer.invoke('save:write', document)
  }
} satisfies GameApi

contextBridge.exposeInMainWorld('janken', api)
