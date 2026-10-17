import { spawn, type ChildProcess } from 'node:child_process'
import { lstat } from 'node:fs/promises'
import type { EditorView } from '../preload/api'

const views = new Set<EditorView>(['story', 'battle', 'slides'])
export function editorView(value: unknown): EditorView {
  if (typeof value !== 'string' || !views.has(value as EditorView)) throw new Error('Unknown editor view')
  return value as EditorView
}

/** Only a fixed build entry and a whitelisted view may be launched, never a renderer path. */
export function createEditorLauncher(entry: string, executable = process.execPath) {
  let child: ChildProcess | undefined
  let opening = false
  return async (value: unknown) => {
    const view = editorView(value)
    if (opening || child) throw new Error('Close the existing editor before opening another view')
    opening = true
    try {
      if (!(await lstat(entry)).isFile()) throw new Error('Build the editor first')
      const env = { ...process.env }
      delete env.ELECTRON_RENDERER_URL; delete env.ELECTRON_RUN_AS_NODE
      const next = spawn(executable, [entry, `--editor-view=${view}`, '--editor-launch'], { stdio: 'ignore', env })
      child = next
      next.once('exit', () => { if (child === next) child = undefined })
      await new Promise<void>((resolve, reject) => {
        next.once('spawn', resolve)
        next.once('error', error => { if (child === next) child = undefined; reject(error) })
      })
    } finally { opening = false }
  }
}
