import type { SaveData } from '../../packages/domain/save'

export interface WindowControls {
  minimize(): Promise<void>
  toggleMaximize(): Promise<void>
  close(): Promise<void>
}

export interface DocumentApi {
  read(): Promise<Record<string, unknown> | null>
  write(document: unknown): Promise<void>
}

export interface SaveApi {
  read(): Promise<SaveData | null>
  write(document: SaveData): Promise<void>
}

export interface GameApi {
  windowControls: WindowControls
  save: SaveApi
}

export interface EditorApi {
  windowControls: WindowControls
  content: DocumentApi
}
