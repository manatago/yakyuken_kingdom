import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalTutorial, stepOriginalTutorial, continueOriginalTutorial,
  prepareOriginalTutorial, chooseOriginalTutorialCard, restoreOriginalTutorial } from '../../packages/story/original-tutorial'

test('original tutorial retains all dialogue and round branches through JSON save/resume', () => {
  for (const first of [0, 3, 6]) {
    for (const second of [1, 4, 7]) {
    let state = createOriginalTutorial()
    const lines: string[] = []
    let steps = 0
    while (state.phase !== 'reward') {
      assert.ok(++steps < 200)
      assert.deepEqual(restoreOriginalTutorial(JSON.parse(JSON.stringify(state))), state)
      if (state.phase === 'dialogue') { lines.push(state.text); state = continueOriginalTutorial(state) }
      else if (state.phase === 'deck') state = prepareOriginalTutorial(state, state.battle.playerDeck)
      else if (state.phase === 'selection') state = chooseOriginalTutorialCard(state, state.battle.rounds.length ? second : first)
      else if (state.phase === 'result') state = continueOriginalTutorial(state)
      else state = stepOriginalTutorial(state, 0.5)
    }
    assert.equal(state.battle.rounds.length, 2)
    assert.ok(lines.includes('右上の丸い印が、そのカードのグレードを表してる。'))
    assert.ok(lines.includes('ルールは理解したか？本番はもっと厳しいからな。'))
    assert.equal(state.battle.rounds[0].result, first === 0 ? 'draw' : first === 3 ? 'lose' : 'win')
    assert.equal(state.battle.rounds[1].result, second === 1 ? 'win' : second === 4 ? 'draw' : 'lose')
    assert.equal(state.gold, 20)
    }
  }
})

test('new tutorial progress does not share mutable action objects with the saved snapshot', () => {
  let saved = createOriginalTutorial()
  const checked = new Set<string>()
  for (let i = 0; i < 100 && checked.size < 3; i++) {
    const before = structuredClone(saved)
    const transition = () => saved.phase === 'dialogue' ? continueOriginalTutorial(saved)
      : saved.phase === 'deck' ? prepareOriginalTutorial(saved, saved.battle.playerDeck)
      : saved.phase === 'selection' ? chooseOriginalTutorialCard(saved, 6)
      : stepOriginalTutorial(saved, 0.5)
    const next = transition()
    if (['dialogue', 'deck', 'selection'].includes(saved.phase)) {
      const first = next.actions[0]
      if (first.type === 'step') first.roll = 0.1
      const deck = next.actions.find(action => action.type === 'deck')
      if (deck?.type === 'deck') (deck.cards[0] as { hand: string }).hand = 'paper'
      assert.deepEqual(saved, before)
      checked.add(saved.phase)
    }
    saved = transition()
  }
  assert.equal(checked.size, 3)
})

test('invalid saved tutorial cursors, phases and round history cannot resume', () => {
  const initial = createOriginalTutorial()
  assert.throws(() => restoreOriginalTutorial({ ...initial, phase: 'complete' }))
  assert.throws(() => restoreOriginalTutorial({ ...initial, playback: { ...initial.playback, cursor: -1 } }))
  assert.throws(() => restoreOriginalTutorial({ ...initial, battle: { ...initial.battle, playerHp: 99 } }))
  assert.throws(() => continueOriginalTutorial(initial))
})
