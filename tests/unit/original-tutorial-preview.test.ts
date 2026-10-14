import assert from 'node:assert/strict'
import test from 'node:test'
import { originalTutorialDeckPreview, originalTutorialShowdownPreview } from '../../packages/story/original-tutorial-preview'
import { restoreOriginalTutorial } from '../../packages/story/original-tutorial'

test('editor deck preview is a restorable canonical tutorial boundary and has independent data', () => {
  const first = originalTutorialDeckPreview()
  assert.equal(first.progress.original_tutorial.phase, 'deck')
  assert.equal(first.progress.checkpoint_id, 'original:prologue:198')
  assert.deepEqual(restoreOriginalTutorial(first.progress.original_tutorial), first.progress.original_tutorial)
  first.player.inventory.pop()
  assert.equal(originalTutorialDeckPreview().player.inventory.length, 9)
})

test('editor showdown preview reaches a real restorable original result without a rewritten battle', () => {
  const save = originalTutorialShowdownPreview()
  assert.equal(save.progress.original_tutorial.phase, 'result')
  assert.equal(save.progress.original_tutorial.battle.rounds.length, 1)
  assert.deepEqual(restoreOriginalTutorial(save.progress.original_tutorial), save.progress.original_tutorial)
  assert.equal(originalTutorialDeckPreview().progress.original_tutorial.phase, 'deck')
})
