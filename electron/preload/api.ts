import type { SaveData } from '../../packages/domain/save'
import type { StoryEditRecord } from '../main/story-command-store'
import type { TraceCatalogEntry, TraceEditRecord } from '../main/trace-command-store'

export interface WindowControls {
  minimize(): Promise<void>
  toggleMaximize(): Promise<void>
  close(): Promise<void>
}

export interface DocumentApi {
  read(): Promise<Record<string, unknown> | null>
  write(document: unknown): Promise<void>
  launchJump?(index: number): Promise<{ checkpoint: string }>
  readStory?(sequence: string): Promise<StoryEditRecord>
  writeStory?(edit: unknown): Promise<void>
  imageCatalog?(): Promise<string[]>
  traceCatalog?(): Promise<TraceCatalogEntry[]>
  readTrace?(document: string, target: string): Promise<TraceEditRecord>
  writeTrace?(edit: unknown): Promise<{ affected: number }>
}

export interface SaveApi {
  read(): Promise<SaveData | null>
  write(document: SaveData): Promise<void>
}

export interface GameApi {
  windowControls: WindowControls
  save: SaveApi
  launcher?: { openEditor(view: EditorView): Promise<void> }
}

export type EditorView = 'story' | 'battle' | 'slides'

export interface EditorApi {
  windowControls: WindowControls
  content: DocumentApi
}
