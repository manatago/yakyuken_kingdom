import type { ContentPack, StoryStep } from './schema'
import { validateContent } from './validate'

type Section = keyof Pick<ContentPack, 'assets' | 'layouts' | 'battles' | 'stories'>

export function createContentSession(initial: ContentPack, assetExists: (path: string) => boolean) {
  const check = (document: ContentPack): void => {
    const result = validateContent(document, assetExists)
    if (!result.valid) throw new TypeError(`Invalid content: ${result.issues[0].path}: ${result.issues[0].message}`)
  }
  check(initial)
  let draft = structuredClone(initial)
  let saved = structuredClone(initial)
  let preview: ContentPack | null = null

  return {
    get draft(): ContentPack { return structuredClone(draft) },
    get saved(): ContentPack { return structuredClone(saved) },
    get preview(): ContentPack | null { return preview === null ? null : structuredClone(preview) },
    replaceItem<K extends Section>(section: K, id: string, replacement: ContentPack[K][number]): void {
      if (replacement.id !== id) throw new TypeError('Replacement ID must match target ID')
      const next = structuredClone(draft)
      const items = next[section] as { id: string }[]
      const index = items.findIndex((item) => item.id === id)
      if (index < 0) throw new RangeError(`Unknown content ID: ${id}`)
      items[index] = structuredClone(replacement)
      draft = next
    },
    replaceStep(storyId: string, stepId: string, replacement: StoryStep): void {
      if (replacement.id !== stepId) throw new TypeError('Replacement ID must match target ID')
      const next = structuredClone(draft)
      const story = next.stories.find((item) => item.id === storyId)
      if (!story) throw new RangeError(`Unknown story ID: ${storyId}`)
      const index = story.steps.findIndex((step) => step.id === stepId)
      if (index < 0) throw new RangeError(`Unknown step ID: ${stepId}`)
      story.steps[index] = structuredClone(replacement)
      draft = next
    },
    showPreview(): void {
      check(draft)
      preview = structuredClone(draft)
    },
    async save(write: (document: ContentPack) => Promise<void>): Promise<void> {
      check(draft)
      const snapshot = structuredClone(draft)
      await write(structuredClone(snapshot))
      saved = snapshot
    }
  }
}
