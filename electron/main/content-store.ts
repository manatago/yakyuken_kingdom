import { randomUUID } from 'node:crypto'
import { copyFile, mkdir, readFile, rename, unlink, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'
import { parseDocument, serializeDocument } from './json-document'

export function createContentStore(directory: string, assetExists: (path: string) => boolean) {
  const target = join(directory, 'editor-content.json')
  const backup = `${target}.bak`
  let pending: Promise<void> = Promise.resolve()

  const check = (document: unknown): ContentPack => {
    const result = validateContent(document, assetExists)
    if (!result.valid) throw new TypeError(`Invalid content: ${result.issues[0].path}: ${result.issues[0].message}`)
    return document as ContentPack
  }

  return {
    async read(): Promise<ContentPack | null> {
      try {
        return check(parseDocument(await readFile(target, 'utf8')))
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code === 'ENOENT') return null
        throw error
      }
    },
    async write(value: unknown): Promise<void> {
      const serialized = serializeDocument(value)
      check(parseDocument(serialized))
      const operation = pending.then(async () => {
        await mkdir(directory, { recursive: true })
        const temporary = join(directory, `.editor-content.${randomUUID()}.tmp`)
        const backupTemporary = join(directory, `.editor-content.${randomUUID()}.bak.tmp`)
        try {
          await writeFile(temporary, serialized, { encoding: 'utf8', flag: 'wx', mode: 0o600 })
          try {
            await copyFile(target, backupTemporary)
            await rename(backupTemporary, backup)
          } catch (error) {
            if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error
          }
          await rename(temporary, target)
        } finally {
          for (const path of [temporary, backupTemporary]) {
            await unlink(path).catch((error: NodeJS.ErrnoException) => {
              if (error.code !== 'ENOENT') throw error
            })
          }
        }
      })
      pending = operation.catch(() => {})
      return operation
    }
  }
}
