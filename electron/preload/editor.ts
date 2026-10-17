import { contextBridge, ipcRenderer } from 'electron'
import type { EditorApi } from './api'
import { windowControls } from './window-controls'

const api = {
  windowControls,
  content: {
    read: (): Promise<Record<string, unknown> | null> => ipcRenderer.invoke('content:read'),
    write: (document: unknown): Promise<void> => ipcRenderer.invoke('content:write', document),
    launchJump: (index: number): Promise<{ checkpoint: string }> => ipcRenderer.invoke('content:launch-jump', index),
    readStory: (sequence: string) => ipcRenderer.invoke('content:story-read', sequence),
    writeStory: (edit: unknown): Promise<void> => ipcRenderer.invoke('content:story-write', edit),
    imageCatalog: (): Promise<string[]> => ipcRenderer.invoke('content:image-catalog'),
    traceCatalog: () => ipcRenderer.invoke('content:trace-catalog'),
    readTrace: (document: string, target: string) => ipcRenderer.invoke('content:trace-read', document, target),
    writeTrace: (edit: unknown) => ipcRenderer.invoke('content:trace-write', edit)
  }
} satisfies EditorApi

contextBridge.exposeInMainWorld('janken', api)
