import assert from 'node:assert/strict'
import test from 'node:test'
import { acknowledgeFixedRound, fixedView, playFixedRound, prepareFixedBattle, returnFromFixedBattle,
  selectOpponent, settleFixedBattle, fixedContent, opponents } from '../../packages/battle/fixed'
import { startStage2 } from '../../packages/battle/stage2'
import { continueToStage2Rematch } from '../../packages/battle/stage2-minigame'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { acknowledgeTutorial, playTutorialRound, prepareTutorial } from '../../packages/battle/tutorial'
import { SUBEVENT_COMPLETION_FLAGS } from '../../packages/domain/progression'
import { enterGuildHome } from '../../packages/guild/home'
import { judgeCards } from '../../packages/domain/card'

function readyForStage2FirstBattle() {
  let save = createInitialGameSave()
  save = prepareTutorial({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.await-deck' } }, save.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  save = { ...save, player: { ...save.player, inventory: [...save.player.inventory,
    ...Array.from({ length: 3 }, () => ({ hand: 'rock' as const, grade: 2 as const }))] } }
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.await' } })
  for (const index of [6, 7, 8]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  save = settleFixedBattle(save, 0)
  save = enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end' } }))
  save = startStage2({ ...save, progress: { ...save.progress, flags: [...save.progress.flags,
    SUBEVENT_COMPLETION_FLAGS.subevent2] } })
  return { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.first.await' } }
}

test('Stage 2 first fixed battle scripts a loss, disables items, and applies card loss once', () => {
  let save = prepareFixedBattle(readyForStage2FirstBattle())
  const before = save.player.inventory.length
  const beforeDeck = save.player.deck.length
  const battle = fixedContent.battles.find(({ id }) => id === 'battle.stage2.first')!
  for (let round = 0; round < 3; round++) {
    const view = fixedView(save)
    const ledger = save.progress.fixed_battle!
    const playerIndex = ledger.player_deck.findIndex((_, index) => !view.usedPlayer.includes(index))
    const opponentIndex = selectOpponent(battle, ledger, playerIndex, 0.5)
    save = playFixedRound(save, playerIndex, 0.5)
    assert.equal(save.progress.fixed_battle!.rounds.at(-1)?.opponent_index, opponentIndex)
    assert.equal(fixedView(save).roundResults.at(-1)?.result, 'lose')
    if (round < 2) save = acknowledgeFixedRound(save)
    else save = settleFixedBattle(save, 0.5)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  assert.equal(save.player.inventory.length, before - 3)
  assert.equal(save.progress.fixed_battle?.settled, true)
  assert.equal(save.player.deck.length, beforeDeck - 3)
  assert.deepEqual(save.player.items, [])
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(save))))
  assert.throws(() => settleFixedBattle(save, 0.5))
  save = returnFromFixedBattle(save)
  assert.equal(save.progress.checkpoint_id, 'stage2.first.result')
})

test('Stage 2 rematch grants the Godot item and grade-5 rock card on victory only', () => {
  const battle = fixedContent.battles.find(({ id }) => id === 'battle.stage2.rematch')!
  assert.deepEqual(battle.item_reward_ids, ['rock_attract_gold'])
  assert.deepEqual(battle.card_reward, { hand: 'rock', grade: 5 })
  const source = readyForStage2FirstBattle()
  const minigameEnd = { ...source, progress: { ...source.progress, checkpoint_id: 'stage2.minigame.end',
    flags: [...source.progress.flags, 'stage2_first_battle_done', 'stage2_first_battle_completed'],
    stage2_minigame: { scene_order: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], current_scene: 3,
      gauge: 0, picks: ['ask_pisuke', 'ask_pisuke', 'ask_pisuke'], outcome: 'win' as const } } }
  let save = prepareFixedBattle(continueToStage2Rematch(minigameEnd))
  while (!fixedView(save).outcome) {
    const view = fixedView(save), ledger = save.progress.fixed_battle!
    let choice: { playerIndex: number; roll: number } | undefined
    for (let playerIndex = 0; playerIndex < ledger.player_deck.length && !choice; playerIndex++) {
      if (view.usedPlayer.includes(playerIndex)) continue
      for (let step = 0; step < 1000; step++) {
        const roll = step / 1000, opponentIndex = selectOpponent(battle, ledger, playerIndex, roll)
        if (judgeCards(ledger.player_deck[playerIndex]!, opponents(battle)[opponentIndex]!) === 'win') {
          choice = { playerIndex, roll }; break
        }
      }
    }
    assert.ok(choice, 'a winning card remains for every required round')
    save = playFixedRound(save, choice.playerIndex, choice.roll)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  const settled = settleFixedBattle(save, 0.5)
  assert.ok(settled.player.inventory.some((card) => card.hand === 'rock' && card.grade === 5))
  assert.ok(settled.player.items?.includes('rock_attract_gold'))
  assert.deepEqual(settled.progress.fixed_battle?.card_reward, { hand: 'rock', grade: 5 })
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(settled))))
})

test('Stage 2 rematch is the Godot three-outfit round limit, including an all-draw result', () => {
  const battle = fixedContent.battles.find(({ id }) => id === 'battle.stage2.rematch')!
  assert.equal(battle.round_limit, 3)
  const source = readyForStage2FirstBattle()
  const save = { ...source, progress: { ...source.progress, checkpoint_id: 'stage2.battle2.start',
    flags: [...source.progress.flags, 'stage2_first_battle_done', 'stage2_first_battle_completed', 'stage2_minigame_completed'],
    stage2_minigame: { scene_order: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], current_scene: 3,
      gauge: 0, picks: ['ask_pisuke', 'ask_pisuke', 'ask_pisuke'], outcome: 'win' as const } } }
  let ongoing = prepareFixedBattle(save)
  const ledger = ongoing.progress.fixed_battle!
  const playerIndex = ledger.player_deck.findIndex((card) => card.hand === 'paper' && card.grade === 1)
  assert.notEqual(playerIndex, -1)
  const opponentDeck = opponents(battle)
  let tiedRoll: number | undefined
  for (let step = 0; step < 1000 && tiedRoll === undefined; step++) {
    const roll = step / 1000
    const opponentIndex = selectOpponent(battle, ledger, playerIndex, roll)
    if (opponentDeck[opponentIndex]?.hand === 'paper' && opponentDeck[opponentIndex]?.grade === 1) tiedRoll = roll
  }
  assert.notEqual(tiedRoll, undefined)
  for (let round = 0; round < 3; round++) {
    ongoing = playFixedRound(ongoing, playerIndex, tiedRoll!)
    if (round < 2) ongoing = acknowledgeFixedRound(ongoing)
  }
  assert.equal(fixedView(ongoing).outcome, 'draw')
  assert.equal(ongoing.progress.fixed_battle?.rounds.length, 3)
})
