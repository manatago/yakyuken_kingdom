import assert from 'node:assert/strict'
import { existsSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { validateContent } from '../../packages/content/validate'
import { createInitialGameSave, createNewGameSave, MATILDA_START_CHECKPOINT, PROLOGUE_START_CHECKPOINT } from '../../packages/domain/new-game'
import { finishPrologue, isPrologueCheckpoint, prologueContent, PROLOGUE_COMPLETE, PROLOGUE_STORY_ID } from '../../packages/story/prologue'
import { advanceStory, startStory } from '../../packages/story/runner'

test('adapted prologue content references existing images and resumes every dialogue checkpoint', () => {
  assert.deepEqual(validateContent(prologueContent, (path) => existsSync(fileURLToPath(new URL(`../../${path}`, import.meta.url)))),
    { valid: true, issues: [] })
  const initial = createNewGameSave()
  assert.equal(initial.progress.checkpoint_id, PROLOGUE_START_CHECKPOINT)
  assert.deepEqual(initial.player, createInitialGameSave().player)
  assert.equal(initial.progress.flags.length, 0)
  let frame = startStory(prologueContent, PROLOGUE_STORY_ID, initial.progress.checkpoint_id)
  const visited: string[] = []
  while (frame.step.kind === 'line') {
    assert.ok(isPrologueCheckpoint(frame.step.id))
    assert.ok(!visited.includes(frame.step.id), 'opening story must not loop')
    visited.push(frame.step.id)
    const reloaded = startStory(prologueContent, PROLOGUE_STORY_ID, frame.step.id)
    assert.deepEqual(reloaded, frame)
    frame = advanceStory(prologueContent, PROLOGUE_STORY_ID, frame)
  }
  assert.equal(frame.step.kind, 'end')
  assert.equal(visited.length, prologueContent.stories[0]!.steps.filter((step) => step.kind === 'line').length)
  const atEnd = { ...initial, progress: { ...initial.progress, checkpoint_id: frame.step.id } }
  const continued = finishPrologue(atEnd)
  assert.equal(continued.progress.checkpoint_id, MATILDA_START_CHECKPOINT)
  assert.deepEqual(continued.progress.flags, [PROLOGUE_COMPLETE])
  assert.deepEqual(continued.player, initial.player)
  assert.throws(() => finishPrologue(initial), /Prologue is not complete/)
})
