import document from '../../content/stories/prologue.json'
import type { ContentPack } from '../content/schema'
import { parseSave, type SaveData } from '../domain/save'

export const PROLOGUE_STORY_ID = 'story.prologue'
export const PROLOGUE_COMPLETE = 'prologue.completed'
export const prologueContent = document as unknown as ContentPack
const story = prologueContent.stories.find((entry) => entry.id === PROLOGUE_STORY_ID)!

export function isPrologueCheckpoint(checkpointId: string): boolean {
  return story.steps.some((step) => step.id === checkpointId)
}

export function finishPrologue(save: SaveData): SaveData {
  if (!isPrologueCheckpoint(save.progress.checkpoint_id) ||
      !story.steps.some((step) => step.id === save.progress.checkpoint_id && step.kind === 'end')) {
    throw new Error('Prologue is not complete')
  }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.start',
    flags: [...save.progress.flags, PROLOGUE_COMPLETE] } })
}
