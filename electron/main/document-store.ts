import { randomUUID } from 'node:crypto'
import { mkdir, readFile, rename, unlink, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { setTimeout as delay } from 'node:timers/promises'
import { parseDocument, serializeDocument } from './json-document'

type StoreIo = {
  platform?: NodeJS.Platform
  renameFile?: typeof rename
  readDocument?: (path: string) => Promise<string>
  pause?: (milliseconds: number) => Promise<void>
}

export function createDocumentStore(directory: string, filename: string, io: StoreIo = {}) {
  const target = join(directory, filename)
  let pending: Promise<void> = Promise.resolve()
  const readDocument = io.readDocument ?? ((path: string) => readFile(path, 'utf8'))
  const pause = io.pause ?? delay
  function enqueue<T>(operation: () => Promise<T>): Promise<T> {
    const result = pending.then(operation)
    pending = result.then(() => {}, () => {})
    return result
  }

  async function replace(temporary: string) {
    for (let attempt = 0; ; attempt++) {
      try { await (io.renameFile ?? rename)(temporary, target); return }
      catch (error) {
        const code = (error as NodeJS.ErrnoException).code
        // Windows can temporarily deny atomic replacement; never delete the old target.
        if ((io.platform ?? process.platform) !== 'win32' ||
          !['EPERM', 'EACCES', 'EBUSY'].includes(code ?? '') || attempt >= 6) throw error
        await pause(25 * 2 ** attempt)
      }
    }
  }

  return {
    async read(): Promise<Record<string, unknown> | null> {
      return enqueue(async () => {
        try { return parseDocument(await readDocument(target)) }
        catch (error) {
          if ((error as NodeJS.ErrnoException).code === 'ENOENT') return null
          throw error
        }
      })
    },
    async write(value: unknown): Promise<void> {
      const serialized = serializeDocument(value)
      return enqueue(async () => {
        await mkdir(directory, { recursive: true })
        const temporary = join(directory, `.${filename}.${randomUUID()}.tmp`)
        try {
          await writeFile(temporary, serialized, { encoding: 'utf8', flag: 'wx', mode: 0o600 })
          await replace(temporary)
        } finally {
          await unlink(temporary).catch((error: NodeJS.ErrnoException) => {
            if (error.code !== 'ENOENT') throw error
          })
        }
      })
    }
  }
}
