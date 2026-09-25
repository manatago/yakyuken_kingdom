import { randomUUID } from 'node:crypto'
import { mkdir, readFile, rename, unlink, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { parseDocument, serializeDocument } from './json-document'

export function createDocumentStore(directory: string, filename: string) {
  const target = join(directory, filename)

  return {
    async read(): Promise<Record<string, unknown> | null> {
      try {
        return parseDocument(await readFile(target, 'utf8'))
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code === 'ENOENT') return null
        throw error
      }
    },
    async write(value: unknown): Promise<void> {
      const serialized = serializeDocument(value)
      await mkdir(directory, { recursive: true })
      const temporary = join(directory, `.${filename}.${randomUUID()}.tmp`)
      try {
        await writeFile(temporary, serialized, { encoding: 'utf8', flag: 'wx', mode: 0o600 })
        await rename(temporary, target)
      } finally {
        await unlink(temporary).catch((error: NodeJS.ErrnoException) => {
          if (error.code !== 'ENOENT') throw error
        })
      }
    }
  }
}
