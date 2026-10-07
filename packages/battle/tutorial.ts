import content from '../../content/stories/matilda-tutorial.json'
import type { BattleContent } from '../content/schema'
import { getCardDefinition } from '../domain/card-catalog'
import { judgeCards, type Card, type BattleResult } from '../domain/card'
import { validateDeck } from '../domain/deck'
import type { SaveData } from '../domain/save'
import { isFixedCheckpoint } from './fixed'
import { STAGE2_MINIGAME_CHECKPOINT, STAGE2_MINIGAME_END_CHECKPOINT } from './stage2-minigame'
import stage2Content from '../../content/stories/stage2.json'
import subevent2Content from '../../content/stories/subevent2.json'
import subevent3Content from '../../content/stories/subevent3.json'
import subevent4Content from '../../content/stories/subevent4.json'
import stage3Content from '../../content/stories/stage3.json'
import { STAGE3_MINIGAME_CHECKPOINT, STAGE3_MINIGAME_END_CHECKPOINT } from './stage3-minigame'
import stage4Content from '../../content/stories/stage4.json'
import { STAGE4_MINIGAME_CHECKPOINT, STAGE4_MINIGAME_END_CHECKPOINT } from './stage4-minigame'
import stage5Content from '../../content/stories/stage5.json'
import { STAGE5_MINIGAME_CHECKPOINT, STAGE5_MINIGAME_END_CHECKPOINT } from './stage5-minigame'
import stage6Content from '../../content/stories/stage6.json'
import stage7Content from '../../content/stories/stage7.json'

export const tutorialBattle = content.battles[0] as BattleContent
export const TUTORIAL_CHECKPOINT = 'matilda.await-deck'
export const TUTORIAL_COMPLETE = 'matilda.tutorial.completed'
export interface TutorialRound { readonly player_index: number; readonly opponent_index: number }
export interface TutorialLedger {
  readonly battle_id: string
  readonly rounds: readonly TutorialRound[]
  readonly acknowledged: number
  readonly player_deck?: readonly Card[]
}

const opponentDeck: readonly Card[] = tutorialBattle.opponent_card_ids.map((id) => {
  const definition = getCardDefinition(id)
  if (!definition) throw new Error('Unknown tutorial card')
  return { hand: definition.hand, grade: definition.grade }
})

function assertTutorialDeck(deck: readonly Card[], inventory?: readonly Card[]) {
  if (deck.length !== tutorialBattle.player_deck_size || deck.some((card) => card.grade !== 1) ||
      inventory && !validateDeck(inventory, deck, tutorialBattle.player_deck_size).valid) {
    throw new Error('Nine owned Normal cards required')
  }
}

function assertReady(save: SaveData) {
  assertTutorialDeck(save.player.deck, save.player.inventory)
}

// Derive all mutable battle facts from the persisted ledger; never reroll on load.
export function tutorialView(save: SaveData) {
  const historicalDeck = save.progress.tutorial?.player_deck ?? save.player.deck
  const usedPlayer: number[] = [], usedOpponent: number[] = []
  let playerHp = 3, opponentHp = 3
  let last: { player: Card; opponent: Card; result: BattleResult } | undefined
  for (const round of save.progress.tutorial?.rounds ?? []) {
    const player = historicalDeck[round.player_index], opponent = opponentDeck[round.opponent_index]
    if (!player || !opponent || usedPlayer.includes(round.player_index) || usedOpponent.includes(round.opponent_index)) {
      throw new Error('Invalid or reused tutorial card')
    }
    const result = judgeCards(player, opponent)
    if (result !== 'draw') { usedPlayer.push(round.player_index); usedOpponent.push(round.opponent_index) }
    if (result === 'win') opponentHp--
    if (result === 'lose') playerHp--
    last = { player, opponent, result }
  }
  return { playerHp, opponentHp, usedPlayer, usedOpponent, last }
}

export function validateTutorialState(save: SaveData) {
  const ledger = save.progress.tutorial
  const completed = save.progress.flags.includes(TUTORIAL_COMPLETE)
  const completionCheckpoint = ['matilda.complete', 'matilda.end', STAGE2_MINIGAME_CHECKPOINT,
    STAGE2_MINIGAME_END_CHECKPOINT].includes(save.progress.checkpoint_id) || isFixedCheckpoint(save.progress.checkpoint_id) ||
    stage2Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id)) ||
    subevent2Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id)) ||
    subevent3Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id)) ||
    subevent4Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id)) ||
    stage3Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id)) ||
    stage4Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id)) ||
    stage5Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id)) ||
    stage6Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id)) ||
    stage7Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id)) ||
    [STAGE3_MINIGAME_CHECKPOINT, STAGE3_MINIGAME_END_CHECKPOINT, STAGE4_MINIGAME_CHECKPOINT,
      STAGE4_MINIGAME_END_CHECKPOINT, STAGE5_MINIGAME_CHECKPOINT, STAGE5_MINIGAME_END_CHECKPOINT,
      'subevent3.minigame', 'subevent3.minigame.end'].includes(save.progress.checkpoint_id)
  if (!ledger) {
    if (completed || completionCheckpoint) throw new Error('Missing tutorial completion ledger')
    return
  }
  if (ledger.player_deck) assertTutorialDeck(ledger.player_deck)
  else assertReady(save)
  if (ledger.battle_id !== tutorialBattle.id || ledger.rounds.length > tutorialBattle.phases.length ||
      !Number.isSafeInteger(ledger.acknowledged) || ledger.acknowledged < 0 ||
      ledger.acknowledged > ledger.rounds.length || ledger.rounds.length - ledger.acknowledged > 1) {
    throw new Error('Invalid tutorial progress')
  }
  ledger.rounds.forEach((round, index) => {
    if (!Number.isSafeInteger(round.player_index) || !Number.isSafeInteger(round.opponent_index)) {
      throw new Error('Invalid tutorial indices')
    }
    const fixed = tutorialBattle.phases[index].rules.find((rule) => rule.kind === 'fixed_opponent_hand')
    if (fixed?.kind === 'fixed_opponent_hand' && opponentDeck[round.opponent_index]?.hand !== fixed.hand) {
      throw new Error('Fixed tutorial hand mismatch')
    }
  })
  tutorialView(save)
  const done = ledger.acknowledged === tutorialBattle.phases.length
  if (done !== completed || done !== completionCheckpoint ||
      !done && save.progress.checkpoint_id !== TUTORIAL_CHECKPOINT) throw new Error('Tutorial checkpoint mismatch')
}

export function prepareTutorial(save: SaveData, deck: readonly Card[]): SaveData {
  if (save.progress.checkpoint_id !== TUTORIAL_CHECKPOINT || save.progress.tutorial) throw new Error('Not preparing tutorial')
  const ready: SaveData = { ...save, player: { ...save.player, deck: [...deck] }, progress: {
    ...save.progress, tutorial: { battle_id: tutorialBattle.id, rounds: [], acknowledged: 0,
      player_deck: deck.map((card) => ({ ...card })) }
  } }
  assertReady(ready)
  return ready
}

export function playTutorialRound(save: SaveData, playerIndex: number, roll: number): SaveData {
  validateTutorialState(save)
  const ledger = save.progress.tutorial
  if (!ledger || ledger.rounds.length !== ledger.acknowledged || ledger.rounds.length === tutorialBattle.phases.length) {
    throw new Error('Not selecting tutorial card')
  }
  const view = tutorialView(save), player = save.player.deck[playerIndex]
  if (!Number.isSafeInteger(playerIndex) || !player || view.usedPlayer.includes(playerIndex) ||
      !Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid selection or roll')
  const rules = tutorialBattle.phases[ledger.rounds.length].rules
  const fixed = rules.find((rule) => rule.kind === 'fixed_opponent_hand')
  const rate = rules.find((rule) => rule.kind === 'player_win_rate')
  const target: BattleResult = rate?.kind === 'player_win_rate'
    ? roll < rate.value ? 'win' : roll < rate.value + (1 - rate.value) / 2 ? 'lose' : 'draw'
    : 'draw'
  const opponentIndex = opponentDeck.findIndex((card, index) => !view.usedOpponent.includes(index) &&
    (fixed?.kind === 'fixed_opponent_hand' ? card.hand === fixed.hand : judgeCards(player, card) === target))
  if (opponentIndex < 0) throw new Error('No available opponent card')
  return { ...save, progress: { ...save.progress, tutorial: { ...ledger,
    rounds: [...ledger.rounds, { player_index: playerIndex, opponent_index: opponentIndex }]
  } } }
}

export function acknowledgeTutorial(save: SaveData): SaveData {
  validateTutorialState(save)
  const ledger = save.progress.tutorial
  if (!ledger || ledger.rounds.length !== ledger.acknowledged + 1) throw new Error('No pending result')
  const done = ledger.rounds.length === tutorialBattle.phases.length
  return { ...save, progress: { ...save.progress,
    tutorial: { ...ledger, acknowledged: ledger.rounds.length },
    checkpoint_id: done ? 'matilda.complete' : TUTORIAL_CHECKPOINT,
    flags: done ? [...save.progress.flags, TUTORIAL_COMPLETE] : save.progress.flags
  } }
}
