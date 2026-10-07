import assert from 'node:assert/strict'
import test from 'node:test'
import document from '../../content/stories/stage3.json'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { enterGuildHome } from '../../packages/guild/home'
import { GUILD_CHECKPOINT } from '../../packages/guild/routes'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { startStage3, canStartStage3, canRetryStage3Battle, finishStage3Story, continueStage3Minigame } from '../../packages/battle/stage3'
import { beginStage3Minigame, chooseStage3Evidence, parseStage3Minigame, rollStage3Offer, STAGE3_MINIGAME_CHECKPOINT,
  validateStage3Minigame, validateStage3MinigameState } from '../../packages/battle/stage3-minigame'
import { fixedContent, prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle, returnFromFixedBattle,
  fixedView, opponents, selectOpponent } from '../../packages/battle/fixed'
import { judgeCards } from '../../packages/domain/card'
import { retryFixedBattle } from '../../packages/battle/fixed'
import { loseFixedBattleAndReturn, recoverCardsThroughTown } from '../helpers/fixed-battle-loss'

const content = document as ContentPack
const allZeroRolls = () => Array.from({ length: 9 }, () => 0)

function readySave() {
  let save = createInitialGameSave()
  save = prepareTutorial({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.await-deck' } }, save.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  save = { ...save, player: { ...save.player,
    inventory: [...save.player.inventory, ...Array.from({ length: 3 }, () => ({ hand: 'rock' as const, grade: 2 as const }))] } }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT,
    guild_return_checkpoint: 'matilda.end', flags: [...save.progress.flags, 'stage2_complete'] } })
}

function finishMinigameWithHits(save: ReturnType<typeof startStage3>) {
  for (let round = 0; round < 3; round++) {
    const offer = save.progress.stage3_minigame!.offer!
    save = chooseStage3Evidence(save, offer.target_chapter, offer.target_evidence, allZeroRolls())
  }
  return save
}

function winRematch(save: ReturnType<typeof prepareFixedBattle>) {
  const battle = fixedContent.battles.find(({ id }) => id === 'battle.stage3.rematch')!
  while (!fixedView(save).outcome) {
    const view = fixedView(save)
    const ledger = save.progress.fixed_battle!
    let selected: { index: number; roll: number } | undefined
    for (let index = 0; index < ledger.player_deck.length && !selected; index++) {
      if (view.usedPlayer.includes(index) || ledger.player_deck[index]!.hand !== 'paper') continue
      for (let rollIndex = 0; rollIndex < 1000; rollIndex++) {
        const roll = rollIndex / 1000
        const opponentIndex = selectOpponent(battle, ledger, index, roll)
        const cardId = battle.opponent_card_ids[opponentIndex]!
        const hand = cardId.startsWith('rock_') ? 'rock' : cardId.startsWith('scissors_') ? 'scissors' : 'paper'
        const grade = cardId.endsWith('_silver') ? 3 : 2
        if (judgeCards(ledger.player_deck[index]!, { hand, grade }) === 'win') { selected = { index, roll }; break }
      }
    }
    if (!selected) throw new Error('No winning selection could be found for Stage 3 rematch')
    save = playFixedRound(save, selected.index, selected.roll)
    if (fixedView(save).outcome) save = settleFixedBattle(save, 0.25)
    else save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'win')
  return returnFromFixedBattle(save)
}

test('Stage 3 content and referenced art validate; it unlocks only after Stage 2', () => {
  assert.deepEqual(validateContent(content, () => true), { valid: true, issues: [] })
  const battle = content.battles.find((entry) => entry.id === 'battle.stage3.first')!
  assert.equal(battle.hp?.forced_outcome, 'lose')
  assert.deepEqual(battle.item_reward_ids, ['scissors_attract_gold'])
  assert.equal(canStartStage3(readySave()), true)
  assert.equal(canStartStage3(createInitialGameSave()), false)
  assert.equal(startStage3(readySave()).progress.checkpoint_id, 'stage3.pre.background')
  for (const flag of ['stage3.started', 'stage3_complete']) {
    const locked = { ...readySave(), progress: { ...readySave().progress, flags: [...readySave().progress.flags, flag] } }
    assert.equal(canStartStage3(locked), false)
    assert.throws(() => startStage3(locked))
  }
  const noReserve = { ...readySave(), player: { ...readySave().player, inventory: [], deck: [] } }
  assert.equal(canStartStage3(noReserve), false)
})

test('Stage 3 evidence options save/reload exactly and validate result history', () => {
  const offer = rollStage3Offer([0, 0, 0, 0, 0.99, 0, 0, 0, 0.99])
  assert.equal(offer.chapters.length, 4)
  assert.equal(offer.evidence.length, 4)
  assert.notEqual(offer.chapters[0], offer.target_chapter)
  assert.notEqual(offer.evidence[0], offer.target_evidence)
  let save = startStage3(readySave())
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage3.minigame.ready' } }
  // Enter the domain through the first battle ending, which creates the initial persisted offer.
  const firstBattle = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'stage3.first.battle' } })
  let defeated = firstBattle
  while (!fixedView(defeated).outcome) {
    const ledger = defeated.progress.fixed_battle!
    const view = fixedView(defeated)
    const playerIndex = ledger.player_deck.findIndex((_, index) => !view.usedPlayer.includes(index))
    defeated = playFixedRound(defeated, playerIndex, 0.5)
    if (fixedView(defeated).outcome) defeated = settleFixedBattle(defeated, 0)
    else defeated = acknowledgeFixedRound(defeated)
  }
  defeated = returnFromFixedBattle(defeated)
  defeated = { ...defeated, progress: { ...defeated.progress, checkpoint_id: 'stage3.first.end' } }
  save = finishStage3Story(defeated, 'story.stage3.first', allZeroRolls())
  assert.equal(save.progress.checkpoint_id, STAGE3_MINIGAME_CHECKPOINT)
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(save))))
  save = chooseStage3Evidence(save, save.progress.stage3_minigame!.offer!.target_chapter,
    save.progress.stage3_minigame!.offer!.target_evidence, allZeroRolls())
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(save))))
  assert.equal(save.progress.stage3_minigame?.hits, 1)
})

test('Stage 3 minigame rejects forged offers, round history and checkpoint/result combinations', () => {
  const offer = rollStage3Offer(allZeroRolls())
  const round = { offer, selected_chapter: offer.target_chapter, selected_evidence: offer.target_evidence,
    hit: true, delta: -40, gauge_after: 60 }
  assert.doesNotThrow(() => validateStage3Minigame({ gauge: 60, hits: 1, rounds: [round],
    offer: rollStage3Offer(allZeroRolls(), [round]) }))
  assert.throws(() => validateStage3Minigame({ gauge: 100, hits: 0, rounds: [], offer: undefined }))
  assert.throws(() => validateStage3Minigame({ gauge: 60, hits: 0, rounds: [round], offer: rollStage3Offer(allZeroRolls(), [round]) }))
  assert.throws(() => validateStage3Minigame({ gauge: 60, hits: 1,
    rounds: [{ ...round, selected_chapter: 'unknown' }], offer: rollStage3Offer(allZeroRolls(), [round]) }))
  assert.throws(() => validateStage3Minigame({ gauge: 60, hits: 1, rounds: [{ ...round, hit: false }], offer: undefined }))
  assert.throws(() => validateStage3Minigame({ gauge: 60, hits: 1, rounds: [{ ...round, delta: 5 }], offer: undefined }))
  assert.throws(() => validateStage3Minigame({ gauge: 61, hits: 1, rounds: [round], offer: undefined }))
  assert.throws(() => validateStage3Minigame({ gauge: 60, hits: 1, rounds: [round], offer }))
  assert.throws(() => parseStage3Minigame({ gauge: 100, hits: 0, rounds: [], offer, extra: true }))
  assert.throws(() => parseStage3Minigame({ gauge: 100, hits: 0, rounds: [], outcome: 'draw' }))
  const noLedger = readySave()
  for (const checkpoint_id of ['stage3.minigame', 'stage3.minigame.end', 'stage3.rematch.background']) {
    assert.throws(() => validateStage3MinigameState({ ...noLedger, progress: { ...noLedger.progress, checkpoint_id } }))
  }
  const alreadyStarted = startStage3(readySave())
  const ready = { ...alreadyStarted, progress: { ...alreadyStarted.progress, checkpoint_id: 'stage3.minigame.ready' } }
  const active = beginStage3Minigame(ready, allZeroRolls())
  assert.throws(() => beginStage3Minigame(active, allZeroRolls()))
})

test('Stage 3 rejects exhausted evidence pools and malformed random or serialized input', () => {
  for (const rolls of [[], [0], [...allZeroRolls(), 0], [0, 0, 0, 0, 1, 0, 0, 0, 0]]) {
    assert.throws(() => rollStage3Offer(rolls))
  }
  const pairs = [
    ['intake', 'minutes'], ['review', 'access'], ['custody', 'inventory'], ['notice', 'letter'],
    ['appeal', 'witness'], ['correction', 'signature'], ['archive', 'seal']
  ]
  const previous = pairs.map(([target_chapter, target_evidence]) => ({ offer: {
    target_chapter, target_evidence, chapters: [target_chapter], evidence: [target_evidence]
  } })) as any
  assert.throws(() => rollStage3Offer(allZeroRolls(), previous), /No unused/)
  for (const value of [null, [], { gauge: 100, hits: 0, rounds: 'bad' },
    { gauge: 100, hits: 0, rounds: [], offer: { ...rollStage3Offer(allZeroRolls()), extra: true } },
    { gauge: 100, hits: 0, rounds: [null], offer: rollStage3Offer(allZeroRolls()) }]) {
    assert.throws(() => parseStage3Minigame(value))
  }
})

test('Stage 3 validates both terminal outcomes and their matching checkpoints', () => {
  const initial = startStage3(readySave())
  let winning = { ...initial, progress: { ...initial.progress, checkpoint_id: 'stage3.minigame.ready' } }
  winning = beginStage3Minigame(winning, allZeroRolls())
  winning = finishMinigameWithHits(winning)
  assert.equal(winning.progress.stage3_minigame?.outcome, 'win')
  assert.doesNotThrow(() => validateStage3MinigameState(winning))
  assert.throws(() => validateStage3MinigameState({ ...winning, progress: { ...winning.progress,
    checkpoint_id: STAGE3_MINIGAME_CHECKPOINT } }))

  let losing = beginStage3Minigame({ ...initial, progress: { ...initial.progress,
    checkpoint_id: 'stage3.minigame.ready' } }, allZeroRolls())
  for (let index = 0; index < 6; index++) {
    const offer = losing.progress.stage3_minigame!.offer!
    const wrongChapter = offer.chapters.find((chapter) => chapter !== offer.target_chapter)!
    losing = chooseStage3Evidence(losing, wrongChapter, offer.target_evidence, allZeroRolls())
    if (losing.progress.stage3_minigame?.outcome) break
  }
  assert.equal(losing.progress.stage3_minigame?.outcome, 'lose')
  assert.doesNotThrow(() => validateStage3MinigameState(losing))
  assert.throws(() => validateStage3MinigameState({ ...losing, progress: { ...losing.progress,
    checkpoint_id: STAGE3_MINIGAME_CHECKPOINT } }))
})

test('Stage 3 first battle forces defeat, evidence review proceeds to a rematch, and a win completes Stage 3', () => {
  let save = startStage3(readySave())
  assert.throws(() => finishStage3Story(save, 'story.stage3.pre'))
  save = finishStage3Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage3.pre.end' } }, 'story.stage3.pre')
  assert.equal(save.progress.checkpoint_id, 'stage3.first.background')
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'stage3.first.battle' } })
  for (let round = 0; round < 3 && !fixedView(save).outcome; round++) {
    const ledger = save.progress.fixed_battle!
    const view = fixedView(save)
    const playerIndex = ledger.player_deck.findIndex((_, index) => !view.usedPlayer.includes(index))
    save = playFixedRound(save, playerIndex, 0.5)
    if (fixedView(save).outcome) save = settleFixedBattle(save, 0)
    else save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  save = returnFromFixedBattle(save)
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage3.first.end' } }
  save = finishStage3Story(save, 'story.stage3.first', allZeroRolls())
  save = finishMinigameWithHits(save)
  assert.equal(save.progress.stage3_minigame?.outcome, 'win')
  save = continueStage3Minigame(save)
  assert.equal(save.progress.checkpoint_id, 'stage3.rematch.background')
  save = { ...save, player: { ...save.player, deck: [...save.player.inventory] } }
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'stage3.rematch.battle' } })
  save = loseFixedBattleAndReturn(save)
  assert.equal(save.progress.checkpoint_id, GUILD_CHECKPOINT)
  assert.equal(canRetryStage3Battle(save), true)
  save = recoverCardsThroughTown(save, 3)
  const recoveredInventory = save.player.inventory
  save = parseSave({ ...save, player: { ...save.player, inventory: recoveredInventory,
    deck: recoveredInventory.slice(0, 9), prepared_deck: recoveredInventory.slice(0, 9) } })
  save = retryFixedBattle(save)
  assert.equal(save.progress.checkpoint_id, 'stage3.rematch.battle')
  save = winRematch(save)
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage3.rematch.end' } }
  save = finishStage3Story(save, 'story.stage3.rematch')
  assert.equal(save.progress.checkpoint_id, 'stage3.post.background')
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage3.post.end' } }
  const home = finishStage3Story(save, 'story.stage3.post')
  assert.equal(home.progress.checkpoint_id, GUILD_CHECKPOINT)
  assert.ok(home.progress.flags.includes('stage3_complete'))
  assert.throws(() => finishStage3Story(home, 'story.stage3.post'))
})
