import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle,
  retryFixedBattle, returnFromFixedBattle, fixedView, opponentProbabilities, replayFixedBattle, fixedContent,
  opponents, selectOpponent, fixedBattleItemsDisabled, fixedBattleTitle } from '../../packages/battle/fixed'
import { validateContent } from '../../packages/content/validate'
import { equipItem } from '../../packages/domain/equipment'
import { advanceStory, startStory } from '../../packages/story/runner'
import { judgeCards } from '../../packages/domain/card'

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

function readyForSubevent2Battle(equipment: readonly ('greed_ring' | 'gold_charm')[] = [], items: readonly ('substitute_card')[] = []): SaveData {
  const source = ready()
  return prepareFixedBattle({ ...source, player: { ...source.player, items, equipment }, progress: {
    ...source.progress, checkpoint_id: 'subevent2.battle.start', flags: [...source.progress.flags, 'subevent2.started']
  } })
}

function fixedRoundChoice(save: SaveData, result: 'win' | 'lose') {
  const battle = fixedContent.battles.find((entry) => entry.id === 'battle.subevent2.sister-head')!
  const ledger = save.progress.fixed_battle!
  const view = fixedView(save)
  for (let playerIndex = 0; playerIndex < ledger.player_deck.length; playerIndex++) {
    if (view.usedPlayer.includes(playerIndex)) continue
    for (let step = 0; step < 1000; step++) {
      const roll = step / 1000
      const opponentIndex = selectOpponent(battle as typeof battle & { hp: NonNullable<typeof battle.hp> }, ledger, playerIndex, roll)
      if (judgeCards(ledger.player_deck[playerIndex]!, opponents(battle)[opponentIndex]!) === result) return { playerIndex, roll }
    }
  }
  throw new Error(`Could not find a ${result} result in the fixed battle`)
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

test('forced-result item availability follows the battle checkpoint rather than an older settled ledger', () => {
  const previousBattle = prepareFixedBattle(ready())
  assert.equal(previousBattle.progress.fixed_battle?.battle_id, 'battle.matilda.normal')
  assert.equal(fixedBattleItemsDisabled(previousBattle, 'battle.stage2.first'), true)
  assert.equal(fixedBattleItemsDisabled(previousBattle, 'battle.stage2.rematch'), false)
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

test('fixed battle consumes each chosen battle item only once at settlement', () => {
  const source = ready()
  const withItems = { ...source, player: { ...source.player, items: ['iron_shield', 'rock_attract_white'] as const } }
  let save = prepareFixedBattle(withItems)
  assert.deepEqual(save.progress.fixed_battle?.items_before, ['iron_shield', 'rock_attract_white'])
  save = playFixedRound(save, 6, 0, 'iron_shield')
  assert.deepEqual(save.progress.fixed_battle?.round_item_ids, ['iron_shield'])
  assert.deepEqual(save.player.items, ['iron_shield', 'rock_attract_white'])
  save = acknowledgeFixedRound(save)
  save = playFixedRound(save, 7, 0)
  save = acknowledgeFixedRound(save)
  save = playFixedRound(save, 8, 0)
  assert.equal(fixedView(save).outcome, 'win')
  const settled = settleFixedBattle(save, 0)
  assert.deepEqual(settled.player.items, ['rock_attract_white'])
  assert.deepEqual(settled.progress.fixed_battle?.round_item_ids, ['iron_shield', null, null])
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
})

test('fixed battle rejects unowned, unavailable, and overused battle items', () => {
  const source = prepareFixedBattle(ready())
  assert.throws(() => playFixedRound(source, 6, 0, 'iron_shield'))
  const initial = ready()
  const started = prepareFixedBattle({ ...initial, player: { ...initial.player, items: ['iron_shield'] } })
  assert.throws(() => playFixedRound(started, 6, 0, 'rank_up_talisman'))
  const first = playFixedRound(started, 6, 0, 'iron_shield')
  const next = acknowledgeFixedRound(first)
  assert.throws(() => playFixedRound(next, 7, 0, 'iron_shield'))
})

test('Iron Shield prevents exactly one HP loss in a fixed battle', () => {
  const source = ready()
  const initial = prepareFixedBattle({ ...source, player: { ...source.player, items: ['iron_shield'] } })
  const protectedLoss = playFixedRound(initial, 3, 0, 'iron_shield')
  assert.equal(fixedView(protectedLoss).last?.result, 'lose')
  assert.equal(fixedView(protectedLoss).playerHp, 3)
  const next = acknowledgeFixedRound(protectedLoss)
  const ordinaryLoss = playFixedRound(next, 4, 0)
  assert.equal(fixedView(ordinaryLoss).playerHp, 2)
})

test('fixed-battle probability items affect opponent selection and are saved with that round', () => {
  const source = ready()
  const initial = prepareFixedBattle({ ...source, player: { ...source.player, items: ['rock_attract_white'] } })
  const first = acknowledgeFixedRound(playFixedRound(initial, 6, 0))
  const without = playFixedRound(first, 4, .64)
  const withItem = playFixedRound(first, 4, .64, 'rock_attract_white')
  assert.equal(fixedView(without).last?.opponent.hand, 'paper')
  assert.equal(fixedView(withItem).last?.opponent.hand, 'scissors')
  assert.deepEqual(withItem.progress.fixed_battle?.round_item_ids, [null, 'rock_attract_white'])
})

test('Greed Ring captures and consumes one extra opponent card for each fixed-battle win', () => {
  let save = readyForSubevent2Battle(['greed_ring'])
  assert.equal(save.progress.fixed_battle?.capture_bonus_enabled, true)
  while (!fixedView(save).outcome) {
    const choice = fixedRoundChoice(save, 'win')
    save = playFixedRound(save, choice.playerIndex, choice.roll, undefined, 0.37)
    const view = fixedView(save)
    assert.equal(view.usedOpponent.length, save.progress.fixed_battle!.rounds.length * 2)
    assert.notEqual(save.progress.fixed_battle?.rounds.at(-1)?.bonus_capture_index,
      save.progress.fixed_battle?.rounds.at(-1)?.opponent_index)
    if (!view.outcome) save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'win')
  assert.ok(save.progress.fixed_battle?.rounds.every((round) => round.bonus_capture_index !== undefined))
  const settled = settleFixedBattle(save, 0)
  assert.equal(settled.player.inventory.length, 15)
  assert.equal(settled.player.equipment?.[0], 'greed_ring')
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(settled))))
  const forged = structuredClone(settled)
  delete forged.progress.fixed_battle!.rounds[0]!.bonus_capture_index
  assert.throws(() => parseSave(forged))
})

test('Substitute Card protects one lost card in a transferable fixed battle', () => {
  let save = readyForSubevent2Battle([], ['substitute_card'])
  assert.equal(save.progress.fixed_battle?.capture_bonus_enabled, false)
  for (let round = 0; round < 3; round++) {
    const choice = fixedRoundChoice(save, 'lose')
    save = playFixedRound(save, choice.playerIndex, choice.roll, round === 0 ? 'substitute_card' : undefined)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  const settled = settleFixedBattle(save, 0)
  assert.equal(settled.player.inventory.length, 7)
  assert.deepEqual(settled.player.items, [])
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(settled))))
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

test('gold charm is snapshotted for fixed battle and adds 20G only on victory', () => {
  const source = ready()
  const equipped = equipItem({ ...source, player: { ...source.player, items: ['gold_charm'] } }, 'gold_charm')
  const started = prepareFixedBattle(equipped)
  assert.deepEqual(started.progress.fixed_battle?.equipment_before, ['gold_charm'])
  let win = started
  for (const index of [6, 7, 8]) {
    win = playFixedRound(win, index, 0)
    if (!fixedView(win).outcome) win = acknowledgeFixedRound(win)
  }
  const rewarded = settleFixedBattle(win, 0.999)
  assert.equal(rewarded.progress.fixed_battle?.gold_delta, 50)
  assert.equal(rewarded.player.money, win.player.money + 50)
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(rewarded))))

  let loss = prepareFixedBattle({ ...equipped, player: { ...equipped.player, inventory: equipped.player.inventory,
    deck: equipped.player.deck, money: equipped.player.money } })
  for (const index of [3, 4, 5]) {
    loss = playFixedRound(loss, index, 0)
    if (!fixedView(loss).outcome) loss = acknowledgeFixedRound(loss)
  }
  const charged = settleFixedBattle(loss, 0)
  assert.equal(charged.progress.fixed_battle?.gold_delta, 0)
  assert.equal(charged.player.money, loss.player.money)
})

test('Matilda main-battle loss preserves gold and retries from its loss story', () => {
  let save = prepareFixedBattle(ready())
  for (const index of [3, 4, 5]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  const settled = settleFixedBattle(save, 0)
  assert.equal(settled.player.money, save.player.money)
  const lossScreen = parseSave(returnFromFixedBattle(parseSave(JSON.parse(JSON.stringify(settled)))))
  assert.equal(lossScreen.progress.checkpoint_id, 'matilda.normal.loss.intro')
  assert.throws(() => parseSave({ ...lossScreen,
    player: { ...lossScreen.player, inventory: [...lossScreen.player.inventory, { hand: 'rock', grade: 1 }] } }))
  let frame = startStory(fixedContent, 'story.matilda.normal.loss', lossScreen.progress.checkpoint_id)
  while (frame.step.kind !== 'end') {
    assert.doesNotThrow(() => parseSave({ ...lossScreen,
      progress: { ...lossScreen.progress, checkpoint_id: frame.step.id } }))
    frame = advanceStory(fixedContent, 'story.matilda.normal.loss', frame)
  }
  assert.equal(frame.step.id, 'matilda.normal.loss.end')
  const storyEnd = parseSave({ ...lossScreen,
    progress: { ...lossScreen.progress, checkpoint_id: 'matilda.normal.loss.end' } })
  const retried = retryFixedBattle(storyEnd)
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
  const initial = createInitialGameSave()
  assert.equal(fixedBattleTitle(initial, 'battle.stage6.first'), 'アレクシア王女戦')
  assert.equal(fixedBattleTitle(initial, 'battle.stage6.rematch'), 'アレクシア王女戦')
  for (const mutate of [
    (p: any) => { p.battles[0].hp.player = 0 },
    (p: any) => { p.battles[0].hp.first_hand = 'other' },
    (p: any) => { p.battles[0].hp.grade_effect_passes = 3 },
    (p: any) => { p.battles[0].hp.lose_gold = -1 },
    (p: any) => { p.battles[0].lose_checkpoint_id = 'matilda.normal.await' },
    (p: any) => { p.battles[0].hp.unknown = true }
  ]) {
    const bad = structuredClone(fixedContent)
    mutate(bad)
    assert.equal(validateContent(bad, () => true).valid, false)
  }
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(initial))), initial)
  assert.equal(Object.hasOwn(parseSave(initial).progress, 'fixed_battle'), false)
})
