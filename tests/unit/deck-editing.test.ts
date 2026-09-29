import assert from 'node:assert/strict'
import test from 'node:test'
import { addDeckCard, removeDeckCard, savePreparedDeck } from '../../packages/domain/deck-editing'
import { createNewSave, parseSave } from '../../packages/domain/save'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial, tutorialView } from '../../packages/battle/tutorial'
import type { Card } from '../../packages/domain/card'

const cards: Card[] = Array.from({ length: 9 }, (_, i) => ({ hand: 'rock', grade: (i % 5 + 1) as Card['grade'] }))

test('draft editing enforces owned copies and capacity without mutating inputs', () => {
  const draft = addDeckCard(cards, [], cards[0])
  assert.deepEqual(draft, [cards[0]])
  assert.deepEqual(removeDeckCard(draft, 0), [])
  assert.deepEqual(draft, [cards[0]])
  assert.throws(() => removeDeckCard(draft, -1))
  assert.throws(() => removeDeckCard(draft, 1))
  assert.throws(() => addDeckCard([cards[0]], draft, cards[0]))
  assert.throws(() => addDeckCard(cards, cards, cards[0]))
  assert.throws(() => addDeckCard(cards, [], { hand: 'paper', grade: 1 }))
})

test('save accepts only nine owned cards and preserves legacy saves on read', () => {
  const original = createNewSave('matilda.start', { inventory: cards, deck: [], money: 17 })
  const bytes = JSON.stringify(original)
  assert.equal(JSON.stringify(parseSave(JSON.parse(bytes))), bytes)
  const saved = savePreparedDeck(original, cards)
  assert.deepEqual(saved.player.prepared_deck, cards)
  assert.deepEqual(saved.player.deck, [])
  assert.deepEqual(saved.progress, original.progress)
  assert.equal(JSON.stringify(original), bytes)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(saved))), saved)
  for (const invalid of [[], cards.slice(1), [...cards, cards[0]], Array(9).fill(cards[0])]) {
    assert.throws(() => savePreparedDeck(original, invalid))
    assert.throws(() => parseSave({ ...original, player: { ...original.player, prepared_deck: invalid } }))
  }
  assert.throws(() => parseSave({ ...original, player: { ...original.player, prepared_deck: [{ hand: 'bad', grade: 6 }] } }))
})

test('editing a future lineup never changes completed battle cards or outcomes', () => {
  let completed = createInitialGameSave()
  completed = prepareTutorial({ ...completed, progress: { ...completed.progress, checkpoint_id: 'matilda.await-deck' } }, completed.player.inventory)
  completed = acknowledgeTutorial(playTutorialRound(completed, 6, 0))
  completed = acknowledgeTutorial(playTutorialRound(completed, 0, 0))
  const source = { ...completed, player: { ...completed.player, inventory: [...completed.player.inventory, ...cards] } }
  const before = JSON.stringify(source)
  const view = tutorialView(source)
  const saved = savePreparedDeck(source, cards)
  assert.deepEqual(saved.player.deck, source.player.deck)
  assert.deepEqual(saved.progress, source.progress)
  assert.deepEqual(tutorialView(saved), view)
  assert.deepEqual(tutorialView(parseSave(JSON.parse(JSON.stringify(saved)))), view)
  assert.equal(JSON.stringify(source), before)
})
