export interface WindowControls {
  minimize(): Promise<void>
  toggleMaximize(): Promise<void>
  close(): Promise<void>
}

export interface DocumentApi {
  read(): Promise<Record<string, unknown> | null>
  write(document: unknown): Promise<void>
}

export interface GameApi {
  windowControls: WindowControls
  save: DocumentApi
}

export interface EditorApi {
  windowControls: WindowControls
  content: DocumentApi
}
