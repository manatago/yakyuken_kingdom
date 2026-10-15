import { randomUUID } from 'node:crypto'
import { existsSync } from 'node:fs'
import { lstat, mkdir, readFile, realpath, rename, rmdir, unlink, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import type { ContentPack, LayoutContent } from '../../packages/content/schema'
import { MATILDA_LAYOUT_IDS } from '../../packages/content/layout'
import { validateContent } from '../../packages/content/validate'
import { parseDocument, serializeDocument } from './json-document'

// The renderer supplies one layout record, never a path or a whole document.
export function createProjectLayoutStore(projectRoot: string, assetExists?: (path: string) => boolean) {
  let pending: Promise<void> = Promise.resolve()
  async function paths() {
    const root = await realpath(projectRoot)
    const directory = join(root, 'content', 'stories')
    if (await realpath(directory) !== directory) throw new Error('Linked content path is not allowed')
    const target = join(directory, 'matilda-tutorial.json')
    if (!(await lstat(target)).isFile()) throw new Error('Content path must be a regular file, not a link')
    return { root, directory, target, backup: target + '.bak' }
  }
  function check(document: unknown, root: string): ContentPack {
    const result = validateContent(document, assetExists ?? ((path) => existsSync(join(root, path))))
    if (!result.valid) throw new Error(`Invalid content: ${result.issues[0].path}`)
    return document as ContentPack
  }
  function layout(value: unknown): LayoutContent {
    const result = validateContent({ assets: [], layouts: [value], battles: [], stories: [] }, () => true)
    if (!result.valid) throw new Error('Invalid layout')
    const record = value as LayoutContent
    if (!MATILDA_LAYOUT_IDS.includes(record.id) || record.id.startsWith('layout.cards.') && record.flipped) {
      throw new Error('Unknown or unsupported layout')
    }
    return record
  }
  const equal = (a: LayoutContent, b: LayoutContent) =>
    a.id === b.id && a.x === b.x && a.y === b.y && a.scale === b.scale && a.flipped === b.flipped

  return {
    async read(): Promise<ContentPack> {
      const p = await paths()
      return check(parseDocument(await readFile(p.target, 'utf8')), p.root)
    },
    async write(value: unknown): Promise<void> {
      const payload = parseDocument(serializeDocument(value))
      if (Object.keys(payload).length !== 2 || !Object.hasOwn(payload, 'expected') || !Object.hasOwn(payload, 'layout')) {
        throw new Error('Expected one layout and its previous value')
      }
      const expected = layout(payload.expected), replacement = layout(payload.layout)
      if (expected.id !== replacement.id) throw new Error('Layout ID must not change')
      const operation = pending.then(async () => {
        const p = await paths()
        const lock = join(p.directory, '.matilda-layout.lock')
        // Atomic mkdir also excludes writers in other editor processes.
        await mkdir(lock, { mode: 0o700 }).catch((error: NodeJS.ErrnoException) => {
          if (error.code === 'EEXIST') throw new Error('Layout save is locked; another editor may be saving')
          throw error
        })
        try {
          await paths()
          const original = await readFile(p.target, 'utf8')
          const document = check(parseDocument(original), p.root)
          const index = document.layouts.findIndex((entry) => entry.id === expected.id)
          if (index < 0 || !equal(document.layouts[index], expected)) throw new Error('Layout changed; reload before saving')
          document.layouts[index] = replacement
          check(document, p.root)
          const serialized = JSON.stringify(document, null, 2) + '\n'
          serializeDocument(document)
          const temporary = join(p.directory, `.matilda-layout.${randomUUID()}.tmp`)
          const backupTemporary = temporary + '.bak'
          try {
            await lstat(p.backup).then((stat) => {
              if (!stat.isFile()) throw new Error('Backup path must be a regular file')
            }).catch((error: NodeJS.ErrnoException) => { if (error.code !== 'ENOENT') throw error })
            await writeFile(temporary, serialized, { flag: 'wx', mode: 0o600 })
            await writeFile(backupTemporary, original, { flag: 'wx', mode: 0o600 })
            await paths()
            if (await readFile(p.target, 'utf8') !== original) throw new Error('Content changed; reload before saving')
            await rename(backupTemporary, p.backup)
            await rename(temporary, p.target)
          } finally {
            for (const path of [temporary, backupTemporary]) {
              await unlink(path).catch((error: NodeJS.ErrnoException) => { if (error.code !== 'ENOENT') throw error })
            }
          }
        } finally {
          await rmdir(lock)
        }
      })
      pending = operation.catch(() => {})
      return operation
    }
  }
}
