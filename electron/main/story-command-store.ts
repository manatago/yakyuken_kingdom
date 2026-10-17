import { createHash, randomUUID } from 'node:crypto'
import { lstat, mkdir, readFile, realpath, rename, rmdir, unlink, writeFile } from 'node:fs/promises'
import { join, sep } from 'node:path'
import type { OriginalCommand, OriginalStoryDocument } from '../../packages/story/original'
import { serializeDocument } from './json-document'

export interface StoryEditRecord { sequence: OriginalStoryDocument['sequences'][number]; revision: string }
const digest = (text: string) => createHash('sha256').update(text).digest('hex')
const MAX_STORY_BYTES = 8 * 1024 * 1024

function sameShape(previous: unknown, next: unknown): boolean {
  if (previous === null) return next === null
  if (Array.isArray(previous)) return Array.isArray(next) && previous.length === next.length && previous.every((value, i) => sameShape(value, next[i]))
  if (typeof previous === 'object') return !!next && typeof next === 'object' && !Array.isArray(next) &&
    Object.keys(previous).sort().join(',') === Object.keys(next).sort().join(',') &&
    Object.entries(previous).every(([key, value]) => sameShape(value, (next as Record<string, unknown>)[key]))
  return typeof previous === typeof next && (typeof next !== 'number' || Number.isFinite(next))
}

/** Fixed original JSON only, one command at a time; renderer cannot choose a filesystem path. */
export function createStoryCommandStore(projectRoot: string) {
  let pending = Promise.resolve()
  async function paths() {
    const root = await realpath(projectRoot), directory = join(root, 'content', 'stories')
    if (await realpath(directory) !== directory) throw new Error('Linked story directory')
    const target = join(directory, 'godot-original.json')
    if (!(await lstat(target)).isFile()) throw new Error('Story must be a regular file')
    return { root, directory, target }
  }
  async function load() {
    const p = await paths()
    if ((await lstat(p.target)).size > MAX_STORY_BYTES) throw new Error('Original story is too large')
    const text = await readFile(p.target, 'utf8')
    const document = JSON.parse(text) as OriginalStoryDocument
    if (document.format !== 'godot-story-commands' || document.version !== 1 || !Array.isArray(document.sequences)) throw new Error('Invalid story')
    for (const sequence of document.sequences) serializeDocument(sequence)
    if (new Set(document.sequences.map(sequence => sequence.id)).size !== document.sequences.length) throw new Error('Duplicate sequence')
    return { ...p, text, document }
  }
  function sequence(document: OriginalStoryDocument, id: unknown) {
    if (typeof id !== 'string') throw new Error('Invalid sequence ID')
    const found = document.sequences.find(sequence => sequence.id === id)
    if (!found) throw new Error('Unknown sequence')
    return found
  }
  async function checkAssets(value: unknown, root: string, key = ''): Promise<void> {
    if (typeof value === 'string' && ['path', 'portrait_id'].includes(key) && value !== '') {
      if (!value.startsWith('res://assets/') || value.includes('..') || /[,\r\n\\*?\[\]]/.test(value) ||
          !/\.(?:png|jpe?g|webp)$/i.test(value)) throw new Error('Invalid asset reference')
      const assets = await realpath(join(root, 'godot', 'assets'))
      if (assets !== join(root, 'godot', 'assets')) throw new Error('Linked assets directory')
      const resolved = await realpath(join(root, 'godot', value.slice(6)))
      if (!resolved.startsWith(assets + sep) || !(await lstat(resolved)).isFile()) throw new Error('Asset outside project')
    } else if (value && typeof value === 'object') {
      for (const [childKey, child] of Object.entries(value)) await checkAssets(child, root, childKey)
    }
  }
  return {
    async read(id: unknown): Promise<StoryEditRecord> {
      const p = await load()
      return { sequence: sequence(p.document, id), revision: digest(p.text) }
    },
    async write(value: unknown): Promise<void> {
      serializeDocument(value)
      const payload = value as { sequence: string; index: number; revision: string; parameters: OriginalCommand['parameters'] }
      if (Object.keys(payload).sort().join(',') !== 'index,parameters,revision,sequence' || !Number.isSafeInteger(payload.index) || payload.index < 0) throw new Error('Invalid command edit')
      const operation = pending.then(async () => {
        const p = await load(), lock = join(p.directory, '.original-story-editor.lock')
        await mkdir(lock)
        try {
          const current = await load()
          if (digest(current.text) !== payload.revision) throw new Error('Story changed; reload before saving')
          const command = sequence(current.document, payload.sequence).commands[payload.index]
          if (!command || !sameShape(command.parameters, payload.parameters)) throw new Error('Invalid command parameters')
          // Labels and executable routing references remain immutable in this editor operation.
          for (const key of ['label_name', 'chapter_path', 'edit_source_id']) {
            if (command.parameters[key] !== payload.parameters[key]) throw new Error('Cannot alter original routing/source reference')
          }
          await checkAssets(payload.parameters, current.root)
          command.parameters = payload.parameters
          const serialized = JSON.stringify(current.document, null, 2) + '\n'
          if (Buffer.byteLength(serialized, 'utf8') > MAX_STORY_BYTES) throw new Error('Original story is too large')
          const temporary = join(p.directory, `.original-story-editor.${randomUUID()}.tmp`), backup = p.target + '.bak'
          const backupTemporary = temporary + '.bak'
          try {
            await lstat(backup).then(stat => { if (!stat.isFile()) throw new Error('Linked backup') })
              .catch((error: NodeJS.ErrnoException) => { if (error.code !== 'ENOENT') throw error })
            await writeFile(temporary, serialized, { flag: 'wx', mode: 0o600 })
            await paths()
            if (await readFile(p.target, 'utf8') !== current.text) throw new Error('Story changed while saving')
            await writeFile(backupTemporary, current.text, { flag: 'wx', mode: 0o600 })
            await rename(backupTemporary, backup)
            await rename(temporary, p.target)
          } finally {
            for (const path of [temporary, backupTemporary]) {
              await unlink(path).catch((error: NodeJS.ErrnoException) => { if (error.code !== 'ENOENT') throw error })
            }
          }
        } finally { await rmdir(lock) }
      })
      pending = operation.catch(() => {})
      return operation
    }
  }
}
