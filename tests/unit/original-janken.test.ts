import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalJanken, createOriginalNormalJanken, createOriginalBattleCards, selectOriginalCard, resolveOriginalJanken, originalAutoDeckIndices } from '../../packages/battle/original-janken'

test('original Jin tendency adds weight before normalization, while fixed hands bypass it', () => {
  const player = [{ hand: 'paper' as const, grade: 1 as const }]
  const opponent = [{ hand: 'scissors' as const, grade: 1 as const },
    { hand: 'scissors' as const, grade: 1 as const }, { hand: 'rock' as const, grade: 1 as const }]
  const selected = selectOriginalCard(createOriginalBattleCards(player, opponent, 1, 1), 0)
  // Rock: (1/3)/(1 + 2) = 1/9; without tendency .2 chooses Rock.
  assert.equal(resolveOriginalJanken(selected, { tendency: { scissors: 2 } }, .2).rounds[0].opponent.hand, 'scissors')
  assert.equal(resolveOriginalJanken(selected, { tendency: { scissors: 2 } }, .1).rounds[0].opponent.hand, 'rock')
  assert.equal(resolveOriginalJanken(selected, { tendency: { scissors: 2 }, fixed: 'rock' }, .9).rounds[0].opponent.hand, 'rock')
  assert.deepEqual(selected.opponentUsed, [false, false, false])
})

test('original negative tendency clamps before normalization and ignores tendency for an empty deck', () => {
  const selected = selectOriginalCard(createOriginalJanken(), 0)
  assert.equal(resolveOriginalJanken(selected, { tendency: { rock: -2 } }, .1).rounds[0].opponent.hand, 'scissors')
  selected.opponentUsed.fill(true)
  assert.equal(resolveOriginalJanken(selected, { tendency: { scissors: 2 } }, .2).rounds[0].opponent.hand, 'rock')
})

test('normal battle accepts owned higher-grade cards without relaxing the Normal-only tutorial', () => {
  const deck = createOriginalJanken().playerDeck.map(card => ({ ...card, grade: 5 as const }))
  assert.throws(() => createOriginalJanken(deck))
  const battle = createOriginalNormalJanken(deck)
  deck[0] = { hand: 'paper', grade: 5 }
  assert.equal(battle.playerDeck[0].hand, 'rock')
  const result = resolveOriginalJanken(selectOriginalCard(battle, 0), { fixed: 'rock' }, 0)
  assert.equal(result.rounds[0].result, 'win')
  assert.equal(result.opponentHp, 2)
  assert.throws(() => createOriginalNormalJanken([]))
})

test('Godot applies Bronze probability correction twice when choosing the opponent hand', () => {
  const deck = createOriginalJanken().playerDeck.map(card => ({ ...card, grade: 2 as const }))
  const battle = createOriginalNormalJanken(deck)
  // Rock loses to Scissors on rolls in (0.28333..., 0.71666...].
  // One correction would choose Rock at .30; the original two corrections choose Scissors.
  const result = resolveOriginalJanken(selectOriginalCard(battle, 0), {}, .30)
  assert.equal(result.rounds[0].opponent.hand, 'scissors')
  assert.equal(result.rounds[0].result, 'win')
})

test('normal battle uses the original correction for all five grades while fixed hands bypass it', () => {
  const cases = [
    { grade: 1 as const, roll: .30, hand: 'rock' },
    { grade: 2 as const, roll: .30, hand: 'scissors' },
    { grade: 3 as const, roll: .25, hand: 'scissors' },
    { grade: 4 as const, roll: .80, hand: 'scissors' },
    { grade: 5 as const, roll: .85, hand: 'scissors' }
  ]
  for (const example of cases) {
    const deck = createOriginalJanken().playerDeck.map(card => ({ ...card, grade: example.grade }))
    const selected = selectOriginalCard(createOriginalNormalJanken(deck), 0)
    assert.equal(resolveOriginalJanken(selected, {}, example.roll).rounds[0].opponent.hand, example.hand)
    assert.equal(resolveOriginalJanken(selected, { fixed: 'paper' }, example.roll).rounds[0].opponent.hand, 'paper')
  }
})

test('Godot Auto builds a balanced round-robin deck rather than retaining grouped inventory order', () => {
  const battle = createOriginalJanken()
  assert.deepEqual(originalAutoDeckIndices(battle.playerDeck), [0, 3, 6, 1, 4, 7, 2, 5, 8])
})

test('Godot Matilda first round uses Rock; win_rate does not force the second result', () => {
  const initial = createOriginalJanken()
  const selected = selectOriginalCard(initial, 6)
  const first = resolveOriginalJanken(selected, { fixed: 'rock' }, 0.99)
  assert.equal(first.rounds[0].result, 'win')
  assert.equal(first.opponentHp, 2)
  assert.deepEqual(initial.playerUsed, Array(9).fill(false))
  const second = resolveOriginalJanken(selectOriginalCard(first, 3), { win_rate: 0.8 }, 0)
  assert.equal(second.rounds[1].opponent.hand, 'rock')
  assert.equal(second.rounds[1].result, 'lose')
  assert.equal(second.playerHp, 2)
})

test('Godot draw refunds the last used matching copy, not necessarily the selected index', () => {
  let battle = createOriginalJanken()
  battle = resolveOriginalJanken(selectOriginalCard(battle, 2), { fixed: 'scissors' }, 0)
  battle = resolveOriginalJanken(selectOriginalCard(battle, 0), { fixed: 'rock' }, 0)
  assert.equal(battle.rounds[1].result, 'draw')
  assert.equal(battle.playerUsed[0], true)
  assert.equal(battle.playerUsed[2], false)
  assert.equal(battle.opponentUsed[0], false)
  const restored = JSON.parse(JSON.stringify(battle))
  assert.deepEqual(resolveOriginalJanken(selectOriginalCard(restored, 2), {}, 0.9),
    resolveOriginalJanken(selectOriginalCard(battle, 2), {}, 0.9))
})

test('selection is persisted before janken and invalid or reused cards cannot be consumed', () => {
  const battle = createOriginalJanken()
  assert.throws(() => selectOriginalCard(battle, -1))
  assert.throws(() => resolveOriginalJanken(battle, {}, 0))
  const selected = selectOriginalCard(battle, 6)
  assert.equal(selected.playerUsed[6], true)
  assert.throws(() => selectOriginalCard(selected, 7))
  const won = resolveOriginalJanken(selected, { fixed: 'rock' }, 0)
  assert.throws(() => selectOriginalCard(won, 6))
  assert.throws(() => resolveOriginalJanken(selectOriginalCard(won, 7), {}, NaN))
})
