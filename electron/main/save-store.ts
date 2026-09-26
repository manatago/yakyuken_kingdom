import { parseSave, type SaveData } from '../../packages/domain/save'
import { createDocumentStore } from './document-store'

export function createSaveStore(directory: string) {
  const documents = createDocumentStore(directory, 'janken-save.json')
  return {
    async read(): Promise<SaveData | null> {
      const document = await documents.read()
      return document === null ? null : parseSave(document)
    },
    async write(value: unknown): Promise<void> {
      await documents.write(parseSave(value))
    }
  }
}
