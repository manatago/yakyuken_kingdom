import assert from 'node:assert/strict'
import test from 'node:test'
import { acknowledgeFixedRound, fixedContent, fixedView, opponents, playFixedRound, prepareFixedBattle,
  retryFixedBattle, returnFromFixedBattle, selectOpponent, settleFixedBattle } from '../../packages/battle/fixed'
import { SUBEVENT_COMPLETION_FLAGS } from '../../packages/domain/progression'
import { enterGuildHome } from '../../packages/guild/home'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { acknowledgeTutorial, playTutorialRound, prepareTutorial } from '../../packages/battle/tutorial'
import { canRetryStage2Battle, startStage2, finishStage2Story } from '../../packages/battle/stage2'
import { chooseStage2Expression, continueToStage2Rematch, STAGE2_MINIGAME_SCENES } from '../../packages/battle/stage2-minigame'
import { judgeCards } from '../../packages/domain/card'

function completeTutorial(): SaveData {
  let save = createInitialGameSave()
  save = prepareTutorial({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.await-deck' } }, save.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.await' } })
  for (const index of [6, 7, 8]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  save = settleFixedBattle(save, 0)
  return enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end' } }))
}

function reload(save: SaveData): SaveData {
  return parseSave(JSON.parse(JSON.stringify(save)))
}

function playUntilOutcome(save: SaveData, outcome: 'win' | 'lose'): SaveData {
  for (let count = 0; count < 9 && !fixedView(save).outcome; count++) {
    const ledger = save.progress.fixed_battle!
    const view = fixedView(save)
    const battle = fixedContent.battles.find(({ id }) => id === ledger.battle_id)!
    const opponentDeck = opponents(battle)
    let chosen: { playerIndex: number; roll: number } | undefined
    for (let playerIndex = 0; playerIndex < ledger.player_deck.length && !chosen; playerIndex++) {
      if (view.usedPlayer.includes(playerIndex)) continue
      for (let step = 0; step < 1000; step++) {
        const roll = step / 1000
        const opponent = opponentDeck[selectOpponent(battle, ledger, playerIndex, roll)]!
        if ((judgeCards(ledger.player_deck[playerIndex]!, opponent) === 'win') === (outcome === 'win')) {
          chosen = { playerIndex, roll }
          break
        }
      }
    }
    assert.ok(chosen, `could not find a ${outcome} choice for round ${count + 1}`)
    save = playFixedRound(save, chosen.playerIndex, chosen.roll)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, outcome)
  return settleFixedBattle(save, 0.5)
}

test('Stage 2 runs from guild unlock through scripted loss, minigame, rematch, and saved return', () => {
  const tutorial = completeTutorial()
  const withProgressionCards = { ...tutorial, player: { ...tutorial.player,
    inventory: [...tutorial.player.inventory, ...Array.from({ length: 6 }, (_, index) => ({
      hand: (['rock', 'scissors', 'paper'] as const)[index % 3]!, grade: 2 as const
    }))] }, progress: { ...tutorial.progress,
    flags: [...tutorial.progress.flags, SUBEVENT_COMPLETION_FLAGS.subevent2] } }
  let save = reload(startStage2(withProgressionCards))
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.pre.end' } }
  save = reload(finishStage2Story(save, 'story.stage2.pre'))
  assert.equal(save.progress.checkpoint_id, 'stage2.meet.background')

  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.first.await' } }
  save = reload(prepareFixedBattle(save))
  save = reload(playUntilOutcome(save, 'lose'))
  assert.equal(save.player.inventory.length, 12)
  assert.equal(save.player.deck.length, 6)
  save = reload(returnFromFixedBattle(save))
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.first.end' } }
  save = reload(finishStage2Story(save, 'story.stage2.meet'))
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.recover.end' },
    player: { ...save.player, prepared_deck: save.player.inventory.slice(0, 9) } }
  const sceneOrder = [...STAGE2_MINIGAME_SCENES.keys()]
  save = reload(finishStage2Story(save, 'story.stage2.recover', sceneOrder))
  for (const scene of sceneOrder.slice(0, 3)) save = reload(chooseStage2Expression(save, STAGE2_MINIGAME_SCENES[scene]!))
  save = reload(continueToStage2Rematch(save))
  save = reload(prepareFixedBattle(save))
  assert.equal(save.progress.fixed_battle_history?.length, 2)
  assert.deepEqual(save.progress.fixed_battle_history?.map((ledger) => ledger.battle_id),
    ['battle.matilda.normal', 'battle.stage2.first'])
  save = reload(playUntilOutcome(save, 'win'))
  save = reload(returnFromFixedBattle(save))
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.battle2.end' } }
  save = reload(finishStage2Story(save, 'story.stage2.rematch'))
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.post.end' } }
  save = reload(finishStage2Story(save, 'story.stage2.post'))
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.close.end' } }
  save = reload(finishStage2Story(save, 'story.stage2.close'))
  assert.equal(save.progress.checkpoint_id, 'guild.home')
  assert.ok(save.progress.flags.includes('stage2_complete'))
  assert.deepEqual(save.progress.fixed_battle_history?.map((ledger) => ledger.battle_id),
    ['battle.matilda.normal', 'battle.stage2.first'])
  assert.equal(save.progress.fixed_battle?.battle_id, 'battle.stage2.rematch')
})

test('Stage 2 rematch loss returns to Guild and can be retried after rebuilding a nine-card deck', () => {
  const tutorial = completeTutorial()
  const withCards = { ...tutorial, player: { ...tutorial.player, inventory: [...tutorial.player.inventory,
    ...Array.from({ length: 6 }, (_, index) => ({ hand: (['rock', 'scissors', 'paper'] as const)[index % 3]!, grade: 2 as const }))] },
    progress: { ...tutorial.progress, flags: [...tutorial.progress.flags, SUBEVENT_COMPLETION_FLAGS.subevent2] } }
  let save = startStage2(withCards)
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.first.await' } }
  save = prepareFixedBattle(save)
  save = playUntilOutcome(save, 'lose')
  save = returnFromFixedBattle(save)
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.first.end' } }
  save = finishStage2Story(save, 'story.stage2.meet')
  const sceneOrder = [...STAGE2_MINIGAME_SCENES.keys()]
  save = finishStage2Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage2.recover.end' },
    player: { ...save.player, prepared_deck: save.player.inventory.slice(0, 9) } }, 'story.stage2.recover', sceneOrder)
  for (const scene of sceneOrder.slice(0, 3)) save = chooseStage2Expression(save, STAGE2_MINIGAME_SCENES[scene]!)
  save = continueToStage2Rematch(save)
  save = prepareFixedBattle({ ...save, player: { ...save.player, deck: save.player.inventory.slice(0, 9) } })
  save = playUntilOutcome(save, 'lose')
  save = returnFromFixedBattle(save)
  assert.equal(save.progress.checkpoint_id, 'guild.home')
  assert.equal(save.progress.guild_return_checkpoint, 'stage2.battle2.loss.end')
  assert.equal(canRetryStage2Battle(save), true)

  save = parseSave({ ...save, player: { ...save.player, prepared_deck: save.player.inventory.slice(0, 9) } })
  const retry = retryFixedBattle(save)
  assert.equal(retry.progress.checkpoint_id, 'stage2.battle2.start')
  assert.equal(retry.progress.fixed_battle?.battle_id, 'battle.stage2.rematch')
  assert.deepEqual(retry.progress.fixed_battle?.rounds, [])
  assert.ok(retry.progress.flags.includes('stage2.started'))
  assert.ok(retry.progress.flags.includes('stage2_minigame_completed'))
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(retry))), retry)
})
