import assert from 'node:assert/strict'
import { existsSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import document from '../../content/stories/matilda-tutorial.json'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { advanceStory, startStory } from '../../packages/story/runner'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial, tutorialView } from '../../packages/battle/tutorial'
import { assertMatildaSave } from '../helpers/matilda-checks.mjs'

test('journey save checker rejects lost possessions, wrong checkpoint, flags and ledger', () => {
  const initial = createInitialGameSave()
  const expected = { checkpoint: 'matilda.start', deckSize: 0, rounds: null, acknowledged: null }
  assert.doesNotThrow(() => assertMatildaSave(initial, initial, expected))
  for (const mutate of [
    (s: any) => { s.player.inventory.pop() },
    (s: any) => { s.player.money++ },
    (s: any) => { s.player.deck.push(s.player.inventory[0]) },
    (s: any) => { s.progress.checkpoint_id = 'matilda.end' },
    (s: any) => { s.progress.flags.push('matilda.tutorial.completed') },
    (s: any) => { s.progress.tutorial = { battle_id: 'battle.matilda.practice', rounds: [], acknowledged: 0 } }
  ]) {
    const corrupt = structuredClone(initial)
    mutate(corrupt)
    assert.throws(() => assertMatildaSave(corrupt, initial, expected))
  }
  const pending = playTutorialRound(prepareTutorial({ ...initial,
    progress: { ...initial.progress, checkpoint_id: 'matilda.await-deck' } }, initial.player.inventory), 6, 0)
  const pendingExpected = { checkpoint: 'matilda.await-deck', deckSize: 9, rounds: 1, acknowledged: 0 }
  assert.doesNotThrow(() => assertMatildaSave(pending, initial, pendingExpected))
  for (const mutate of [
    (s: any) => { s.progress.tutorial.battle_id = 'wrong' },
    (s: any) => { s.progress.tutorial.rounds = [] },
    (s: any) => { s.progress.tutorial.acknowledged = 1 }
  ]) {
    const corrupt = structuredClone(pending)
    mutate(corrupt)
    assert.throws(() => assertMatildaSave(corrupt, initial, pendingExpected))
  }
})

test('real Matilda content, all checkpoints and two-round save round trips form one journey', () => {
  const pack = document as ContentPack
  assert.deepEqual(validateContent(pack, (path) => existsSync(fileURLToPath(new URL(`../../${path}`, import.meta.url)))),
    { valid: true, issues: [] })
  const initial = createInitialGameSave()
  let save = initial
  let frame = startStory(pack, 'story.matilda', save.progress.checkpoint_id)
  const visited: string[] = []
  const reload = () => {
    save = parseSave(JSON.parse(JSON.stringify(save)))
    const restored = startStory(pack, 'story.matilda', save.progress.checkpoint_id)
    assert.deepEqual(restored, frame)
    return restored
  }
  while (frame.step.kind === 'line') {
    assert.ok(!visited.includes(frame.step.id), 'Matilda journey must not loop')
    visited.push(frame.step.id)
    reload()
    assertMatildaSave(save, initial, { checkpoint: frame.step.id, deckSize: 0, rounds: null, acknowledged: null })
    frame = advanceStory(pack, 'story.matilda', frame)
    save = { ...save, progress: { ...save.progress, checkpoint_id: frame.step.id } }
  }
  assert.equal(frame.step.kind, 'battle')
  reload()
  save = prepareTutorial(save, initial.player.inventory)
  for (const [round, index] of [[0, 6], [1, 0]]) {
    save = parseSave(JSON.parse(JSON.stringify(playTutorialRound(save, index, 0))))
    assertMatildaSave(save, initial, { checkpoint: 'matilda.await-deck', deckSize: 9, rounds: round + 1, acknowledged: round })
    assert.equal(tutorialView(save).last?.result, 'win')
    const result = tutorialView(save)
    assert.deepEqual(tutorialView(parseSave(JSON.parse(JSON.stringify(save)))), result)
    save = acknowledgeTutorial(save)
    assertMatildaSave(save, initial, { checkpoint: round ? 'matilda.complete' : 'matilda.await-deck',
      deckSize: 9, rounds: round + 1, acknowledged: round + 1 })
  }
  frame = startStory(pack, 'story.matilda', save.progress.checkpoint_id)
  visited.push(frame.step.id)
  reload()
  frame = advanceStory(pack, 'story.matilda', frame)
  save = { ...save, progress: { ...save.progress, checkpoint_id: frame.step.id } }
  reload()
  assert.equal(frame.step.kind, 'end')
  assertMatildaSave(save, initial, { checkpoint: 'matilda.end', deckSize: 9, rounds: 2, acknowledged: 2 })
  assert.deepEqual(visited, pack.stories[0].steps.filter((step) => step.kind === 'line').map((step) => step.id))
  assert.equal(tutorialView(save).opponentHp, 1)
})
