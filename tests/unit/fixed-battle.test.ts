import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle,
  retryFixedBattle, returnFromFixedBattle, fixedView, opponentProbabilities, replayFixedBattle, fixedContent } from '../../packages/battle/fixed'
import { validateContent } from '../../packages/content/validate'

function ready(): SaveData {
  const initial = createInitialGameSave()
  let save = prepareTutorial({ ...initial, progress: { ...initial.progress, checkpoint_id: 'matilda.await-deck' } }, initial.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  return { ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.await' } }
}

function winning(): SaveData {
  let save = prepareFixedBattle(ready())
  for (const index of [6, 7, 8]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  return save
}

test('HP battle snapshots prepared cards without changing tutorial, historical deck or possessions', () => {
  const source = ready()
  const prepared = [...source.player.deck].reverse()
  const input = { ...source, player: { ...source.player, prepared_deck: prepared } }
  const save = prepareFixedBattle(input)
  assert.deepEqual(save.progress.fixed_battle?.player_deck, prepared)
  assert.notEqual(save.progress.fixed_battle?.player_deck, prepared)
  assert.deepEqual(save.player, input.player)
  assert.deepEqual(save.progress.tutorial, input.progress.tutorial)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
  assert.deepEqual(fixedView(save).usedPlayer, [])
  assert.equal(fixedView(save).playerHp, 3)
  assert.throws(() => prepareFixedBattle(save))
  assert.throws(() => prepareFixedBattle({ ...source, player: { ...source.player, deck: [] } }))
})

test('draw refunds cards, first hand applies once, pending result must be acknowledged', () => {
  const initial = prepareFixedBattle(ready())
  const draw = playFixedRound(initial, 0, 0.99)
  assert.equal(fixedView(draw).last?.result, 'draw')
  assert.deepEqual(fixedView(draw).usedPlayer, [])
  assert.equal(fixedView(draw).playerHp, 3)
  assert.throws(() => playFixedRound(draw, 6, 0))
  const next = playFixedRound(acknowledgeFixedRound(draw), 0, 0.5)
  assert.equal(fixedView(next).last?.opponent.hand, 'scissors')
  assert.equal(fixedView(next).opponentHp, 2)
  assert.throws(() => playFixedRound(acknowledgeFixedRound(next), 0, 0))
  for (const roll of [-1, 1, NaN, Infinity]) assert.throws(() => playFixedRound(initial, 0, roll))
})

test('terminal win pays once, survives reload and returns to a data-defined conversation', () => {
  const pending = winning()
  assert.equal(fixedView(pending).opponentHp, 0)
  assert.equal(fixedView(pending).outcome, 'win')
  assert.throws(() => playFixedRound(pending, 0, 0))
  assert.throws(() => acknowledgeFixedRound(pending))
  const settled = settleFixedBattle(pending, 0.999)
  assert.equal(settled.player.money, pending.player.money + 30)
  assert.deepEqual(settled.player.inventory, pending.player.inventory)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
  assert.throws(() => settleFixedBattle(settled, 0))
  assert.throws(() => retryFixedBattle(settled))
  assert.equal(returnFromFixedBattle(settled).progress.checkpoint_id, 'matilda.normal.complete')
  assert.doesNotThrow(() => parseSave(returnFromFixedBattle(settled)))
})

test('loss deducts ten gold with a zero floor; retry explicitly replaces only the battle ledger', () => {
  let save = prepareFixedBattle(ready())
  for (const index of [3, 4, 5]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  const settled = settleFixedBattle(save, 0)
  assert.equal(settled.player.money, Math.max(0, save.player.money - 10))
  const retried = retryFixedBattle(parseSave(JSON.parse(JSON.stringify(settled))))
  assert.equal(retried.player.money, settled.player.money)
  assert.deepEqual(retried.progress.tutorial, save.progress.tutorial)
  assert.deepEqual(retried.progress.fixed_battle?.rounds, [])
  assert.equal(fixedView(retried).playerHp, 3)
  assert.doesNotThrow(() => parseSave(retried))
})

test('parser rejects unknown, reused, post-terminal, checkpoint and settlement corruption', () => {
  const source = winning()
  for (const mutate of [
    (s: any) => { s.progress.fixed_battle.battle_id = 'missing' },
    (s: any) => { s.progress.fixed_battle.player_deck.pop() },
    (s: any) => { s.progress.fixed_battle.rounds[1].player_index = 6 },
    (s: any) => { s.progress.fixed_battle.rounds.push({ player_index: 0, opponent_index: 3 }) },
    (s: any) => { s.progress.fixed_battle.acknowledged = -1 },
    (s: any) => { s.progress.fixed_battle.settled = true },
    (s: any) => { s.progress.checkpoint_id = 'matilda.normal.complete' },
    (s: any) => { delete s.progress.fixed_battle }
  ]) {
    const bad = structuredClone(source)
    mutate(bad)
    assert.throws(() => parseSave(bad))
  }
  const old = ready()
  assert.doesNotThrow(() => parseSave(old))
  const withoutLedger = { ...old, progress: { ...old.progress, checkpoint_id: 'matilda.normal.complete' } }
  assert.throws(() => parseSave(withoutLedger))
})

test('Godot probability grade effects are applied twice, not an invented win-rate rule', () => {
  const remaining = [{ hand: 'rock', grade: 1 }, { hand: 'scissors', grade: 1 }, { hand: 'paper', grade: 1 }] as const
  const normal = opponentProbabilities(remaining, { hand: 'rock', grade: 1 }, 2)
  assert.equal(normal.rock, 1 / 3)
  for (const [grade, boost] of [[2, 0.10], [3, 0.20]] as const) {
    const probability = opponentProbabilities(remaining, { hand: 'rock', grade }, 2)
    assert.ok(Math.abs(probability.scissors - (1 / 3 + boost)) < 1e-12)
  }
  const gold = opponentProbabilities(remaining, { hand: 'rock', grade: 4 }, 2)
  assert.ok(Math.abs(gold.paper - (1 / 3 - 0.30)) < 1e-12)
  const platinum = opponentProbabilities(remaining, { hand: 'rock', grade: 5 }, 2)
  assert.ok(platinum.scissors > normal.scissors)
  assert.ok(platinum.paper < normal.paper)
})

test('common replay supports card exhaustion independently of HP, including both-decks draw', () => {
  const original = fixedContent.battles[0]
  const hp = { ...original.hp!, player: 10, opponent: 10 }
  const ledger = { battle_id: original.id, player_deck: [{ hand: 'paper', grade: 1 }],
    rounds: [{ player_index: 0, opponent_index: 0 }], acknowledged: 0, settled: false, balance_before: 0 } as const
  const battle = { ...original, hp, player_deck_size: 1 }
  assert.equal(replayFixedBattle(battle, ledger).outcome, 'lose')
  assert.equal(replayFixedBattle({ ...battle, opponent_deck_size: 1, opponent_card_ids: ['rock_normal'] }, ledger).outcome, 'draw')
  const larger = { ...ledger, player_deck: [...ledger.player_deck, ...ledger.player_deck] }
  assert.equal(replayFixedBattle({ ...battle, opponent_deck_size: 1, opponent_card_ids: ['rock_normal'] }, larger).outcome, 'win')
})

test('HP content is validated strictly while the existing version-one save remains unchanged', () => {
  assert.deepEqual(validateContent(fixedContent, () => true), { valid: true, issues: [] })
  for (const mutate of [
    (p: any) => { p.battles[0].hp.player = 0 },
    (p: any) => { p.battles[0].hp.first_hand = 'other' },
    (p: any) => { p.battles[0].hp.grade_effect_passes = 3 },
    (p: any) => { p.battles[0].hp.lose_gold = -1 },
    (p: any) => { p.battles[0].hp.unknown = true }
  ]) {
    const bad = structuredClone(fixedContent)
    mutate(bad)
    assert.equal(validateContent(bad, () => true).valid, false)
  }
  const initial = createInitialGameSave()
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(initial))), initial)
  assert.equal(Object.hasOwn(parseSave(initial).progress, 'fixed_battle'), false)
})
