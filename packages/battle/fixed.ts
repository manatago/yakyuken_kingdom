import document from '../../content/stories/matilda-normal.json'
import stage2Document from '../../content/stories/stage2.json'
import subevent2Document from '../../content/stories/subevent2.json'
import subevent3Document from '../../content/stories/subevent3.json'
import subevent4Document from '../../content/stories/subevent4.json'
import stage3Document from '../../content/stories/stage3.json'
import stage4Document from '../../content/stories/stage4.json'
import stage5Document from '../../content/stories/stage5.json'
import stage6Document from '../../content/stories/stage6.json'
import stage7Document from '../../content/stories/stage7.json'
import type { ContentPack, BattleContent } from '../content/schema'
import { getCardDefinition } from '../domain/card-catalog'
import { HANDS, judgeCards, type Card, type Hand, type BattleResult } from '../domain/card'
import { applyBattlePayout } from '../domain/player-state'
import { validateDeck } from '../domain/deck'
import { getGoldBonus, getItemDefinition, type ItemId } from '../domain/item-catalog'
import { parseSave, type SaveData } from '../domain/save'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { appendBattleItem, assertBattleItemAvailable, battleItemAdjustment, consumeBattleItems, validateBattleItemUsage } from './items'
import { STAGE2_MINIGAME_CHECKPOINT, STAGE2_MINIGAME_END_CHECKPOINT } from './stage2-minigame'
import { STAGE3_MINIGAME_CHECKPOINT, STAGE3_MINIGAME_END_CHECKPOINT } from './stage3-minigame'
import { STAGE4_MINIGAME_CHECKPOINT, STAGE4_MINIGAME_END_CHECKPOINT } from './stage4-minigame'
import { STAGE5_MINIGAME_CHECKPOINT, STAGE5_MINIGAME_END_CHECKPOINT } from './stage5-minigame'

const stage2 = stage2Document as unknown as ContentPack
const subevent2 = subevent2Document as unknown as ContentPack
const subevent3 = subevent3Document as unknown as ContentPack
const subevent4 = subevent4Document as unknown as ContentPack
const stage3 = stage3Document as unknown as ContentPack
const stage4 = stage4Document as unknown as ContentPack
const stage5 = stage5Document as unknown as ContentPack
const stage6 = stage6Document as unknown as ContentPack
const stage7 = stage7Document as unknown as ContentPack
export const fixedContent: ContentPack = {
  assets: [...document.assets, ...stage2.assets, ...subevent2.assets, ...subevent3.assets, ...subevent4.assets, ...stage3.assets, ...stage4.assets, ...stage5.assets, ...stage6.assets, ...stage7.assets] as ContentPack['assets'],
  layouts: [...document.layouts, ...stage2.layouts, ...subevent2.layouts, ...subevent3.layouts, ...subevent4.layouts, ...stage3.layouts, ...stage4.layouts, ...stage5.layouts, ...stage6.layouts, ...stage7.layouts] as ContentPack['layouts'],
  battles: [...document.battles, ...stage2.battles, ...subevent2.battles, ...subevent3.battles, ...subevent4.battles, ...stage3.battles, ...stage4.battles, ...stage5.battles, ...stage6.battles, ...stage7.battles] as ContentPack['battles'],
  stories: [...document.stories, ...stage2.stories, ...subevent2.stories, ...subevent3.stories, ...subevent4.stories, ...stage3.stories, ...stage4.stories, ...stage5.stories, ...stage6.stories, ...stage7.stories] as ContentPack['stories']
}
export interface FixedLedger {
  readonly battle_id: string
  readonly player_deck: readonly Card[]
  readonly rounds: readonly { player_index: number; opponent_index: number; bonus_capture_index?: number }[]
  readonly acknowledged: number
  readonly settled: boolean
  readonly balance_before: number
  readonly inventory_before?: readonly Card[]
  readonly equipment_before?: readonly ItemId[]
  readonly items_before?: readonly ItemId[]
  readonly round_item_ids?: readonly (ItemId | null)[]
  readonly capture_bonus_enabled?: boolean
  readonly gold_delta?: number
  readonly random_battles_before?: number
  readonly item_rewards?: readonly ItemId[]
  readonly card_reward?: Card | null
}

export function isFixedCheckpoint(id: string): boolean {
  return fixedContent.stories.some((story) => story.steps.some((step) => step.id === id &&
    (step.kind === 'line' || step.kind === 'battle' || step.kind === 'end')))
}

function definition(save: SaveData): BattleContent & { hp: NonNullable<BattleContent['hp']> } {
  const battle = fixedContent.battles.find((entry) => entry.id === save.progress.fixed_battle?.battle_id)
  if (!battle?.hp) throw new Error('Unknown HP battle')
  return battle as BattleContent & { hp: NonNullable<BattleContent['hp']> }
}

export function fixedBattleTitle(save: SaveData, battleIdOverride?: string): string {
  const battleId = battleIdOverride ?? fixedBattleId(save)
  const opponent = fixedContent.battles.find((entry) => entry.id === battleId)?.opponent_id
  return opponent === 'layla' ? 'レイラの検証戦' : opponent === 'sister_head' ? 'シスター長戦'
    : opponent === 'fiona' ? 'フィオナ戦' : opponent === 'receptionist' ? '受付嬢との審査戦'
      : opponent === 'magdalena' ? 'マグダレナ戦' : opponent === 'seles' ? 'セレス戦'
        : opponent === 'princess' ? 'アレクシア王女戦' : 'マチルダ通常戦'
}

export function fixedBattleReturnsToGuild(save: SaveData): boolean {
  const battleId = fixedBattleId(save)
  return fixedContent.battles.find((entry) => entry.id === battleId)?.result_route === 'guild_home'
}

export function fixedBattleItemsDisabled(save: SaveData, battleIdOverride?: string): boolean {
  const battleId = battleIdOverride ?? fixedBattleId(save)
  return fixedContent.battles.find((entry) => entry.id === battleId)?.hp?.forced_outcome !== undefined
}

function fixedBattleId(save: SaveData): string | undefined {
  if (save.progress.fixed_battle) return save.progress.fixed_battle.battle_id
  const step = fixedContent.stories.flatMap((story) => story.steps).find((entry) => entry.id === save.progress.checkpoint_id)
  return step?.kind === 'battle' ? step.battle_id : undefined
}

export function opponents(battle: BattleContent): Card[] {
  return battle.opponent_card_ids.map((id) => {
    const card = getCardDefinition(id)
    if (!card) throw new Error('Unknown opponent card')
    return { hand: card.hand, grade: card.grade }
  })
}

// Preserve the actual Godot probability path, including its two grade-effect passes.
export function opponentProbabilities(remaining: readonly Card[], player: Card, passes: number,
  tendency: Partial<Record<Hand, number>> = {}, adjustment?: { targetHand: Hand; delta: number }): Record<Hand, number> {
  if (!remaining.length || !Number.isInteger(passes) || passes < 0 || passes > 2) throw new Error('Invalid probability input')
  const probability = Object.fromEntries(HANDS.map((hand) => [hand,
    remaining.filter((card) => card.hand === hand).length / remaining.length])) as Record<Hand, number>
  for (const hand of HANDS) probability[hand] = Math.max(0, probability[hand] + (tendency[hand] ?? 0))
  const total = HANDS.reduce((sum, hand) => sum + probability[hand], 0)
  if (total <= 0) throw new Error('Invalid opponent tendency')
  for (const hand of HANDS) probability[hand] /= total
  if (adjustment) {
    const oldValue = probability[adjustment.targetHand]
    const newValue = Math.max(0, Math.min(1, oldValue + adjustment.delta))
    const ratio = oldValue < 1 ? (1 - newValue) / (1 - oldValue) : 1
    for (const hand of HANDS) probability[hand] = hand === adjustment.targetHand ? newValue : probability[hand] * ratio
  }
  const loseHand: Record<Hand, Hand> = { rock: 'scissors', scissors: 'paper', paper: 'rock' }
  const winHand: Record<Hand, Hand> = { rock: 'paper', scissors: 'rock', paper: 'scissors' }
  const lose = loseHand[player.hand], win = winHand[player.hand], draw = player.hand
  const boost = [0, 0, .05, .10, 0, .15][player.grade]
  const reduction = player.grade >= 4 ? .15 : 0
  for (let i = 0; i < passes; i++) {
    if (boost > 0) {
      probability[lose] += boost
      const rest = probability[win] + probability[draw]
      if (rest > 0) {
        const ratio = (1 - probability[lose]) / rest
        probability[win] *= ratio; probability[draw] *= ratio
      }
    }
    if (reduction > 0) {
      probability[win] = Math.max(0, probability[win] - reduction)
      const rest = probability[lose] + probability[draw]
      if (rest > 0) {
        const ratio = (1 - probability[win]) / rest
        probability[lose] *= ratio; probability[draw] *= ratio
      }
    }
  }
  return probability
}

export function fixedView(save: SaveData) {
  const battle = definition(save), ledger = save.progress.fixed_battle!
  return replayFixedBattle(battle, ledger)
}

export function replayFixedBattle(battle: BattleContent & { hp: NonNullable<BattleContent['hp']> }, ledger: FixedLedger) {
  const opponentDeck = opponents(battle)
  const usedPlayer: number[] = [], usedOpponent: number[] = []
  const roundResults: { player: Card; opponent: Card; result: BattleResult }[] = []
  let playerHp = battle.hp.player, opponentHp = battle.hp.opponent
  let outcome: BattleResult | undefined
  let last: { player: Card; opponent: Card; result: BattleResult } | undefined
  for (const [index, round] of ledger.rounds.entries()) {
    const player = ledger.player_deck[round.player_index], opponent = opponentDeck[round.opponent_index]
    if (outcome || !Number.isSafeInteger(round.player_index) || !Number.isSafeInteger(round.opponent_index) ||
        !player || !opponent || usedPlayer.includes(round.player_index) || usedOpponent.includes(round.opponent_index)) {
      throw new Error('Invalid or reused battle card')
    }
    if (index === 0 && battle.hp.first_hand && opponent.hand !== battle.hp.first_hand) throw new Error('First hand mismatch')
    if (opponentDeck.findIndex((card, i) => !usedOpponent.includes(i) && card.hand === opponent.hand) !== round.opponent_index) {
      throw new Error('Opponent cards must be consumed in order')
    }
    const result = judgeCards(player, opponent)
    if (result !== 'draw') { usedPlayer.push(round.player_index); usedOpponent.push(round.opponent_index) }
    const bonusIndex = round.bonus_capture_index
    const bonusCandidates = result === 'win' && ledger.capture_bonus_enabled
      ? opponentDeck.map((_, candidateIndex) => candidateIndex).filter((candidateIndex) => !usedOpponent.includes(candidateIndex)) : []
    if (bonusCandidates.length > 0 && bonusIndex === undefined || bonusCandidates.length === 0 && bonusIndex !== undefined ||
        bonusIndex !== undefined && (!Number.isSafeInteger(bonusIndex) || !bonusCandidates.includes(bonusIndex))) {
      throw new Error('Invalid Greed Ring capture card')
    }
    if (bonusIndex !== undefined) usedOpponent.push(bonusIndex)
    if (result === 'win') opponentHp--
    if (result === 'lose' && getItemDefinition(ledger.round_item_ids?.[index] ?? '')?.effect !== 'protect_hp') playerHp--
    last = { player, opponent, result }
    roundResults.push(last)
    if (opponentHp <= 0) outcome = 'win'
    else if (playerHp <= 0) outcome = 'lose'
    else if (usedPlayer.length === ledger.player_deck.length && usedOpponent.length === opponentDeck.length) outcome = 'draw'
    else if (usedPlayer.length === ledger.player_deck.length) outcome = 'lose'
    else if (usedOpponent.length === opponentDeck.length) outcome = 'win'
    else if (battle.round_limit !== undefined && index + 1 >= battle.round_limit) outcome = 'draw'
  }
  return { playerHp, opponentHp, usedPlayer, usedOpponent, outcome, last, roundResults }
}

export function selectOpponent(battle: BattleContent & { hp: NonNullable<BattleContent['hp']> },
  ledger: FixedLedger, playerIndex: number, roll: number, adjustment?: { targetHand: Hand; delta: number }): number {
  rollCheck(roll)
  const view = replayFixedBattle(battle, ledger), player = ledger.player_deck[playerIndex]
  if (view.outcome || !Number.isSafeInteger(playerIndex) || !player || view.usedPlayer.includes(playerIndex)) {
    throw new Error('Invalid battle selection')
  }
  const available = opponents(battle).map((card, index) => ({ card, index }))
    .filter((entry) => !view.usedOpponent.includes(entry.index))
  if (battle.hp.forced_outcome) {
    const forced = available.find((entry) => judgeCards(player, entry.card) === battle.hp!.forced_outcome)
    if (!forced) throw new Error('No remaining card can satisfy the scripted result')
    return forced.index
  }
  let hand = battle.hp.first_hand
  if (ledger.rounds.length > 0 || !hand) {
    const probability = opponentProbabilities(available.map((entry) => entry.card), player,
      battle.hp.grade_effect_passes, battle.opponent_tendency, adjustment)
    let cumulative = 0
    hand = 'rock'
    for (const candidate of HANDS) {
      cumulative += probability[candidate]
      if (roll <= cumulative) { hand = candidate; break }
    }
  }
  return (available.find((entry) => entry.card.hand === hand) ?? available[0]).index
}

export function battleGoldDelta(battle: BattleContent & { hp: NonNullable<BattleContent['hp']> },
  outcome: BattleResult, balance: number, roll: number): number {
  rollCheck(roll)
  return outcome === 'win' ? battle.gold_reward.min + Math.floor(roll * (battle.gold_reward.max - battle.gold_reward.min + 1))
    : outcome === 'lose' ? -Math.min(balance, battle.hp.lose_gold) : 0
}

export function validateFixedState(save: SaveData, currentCheckpoint = save.progress.checkpoint_id,
  historicalInventory: readonly Card[] = save.player.inventory): void {
  const ledger = save.progress.fixed_battle, checkpoint = save.progress.checkpoint_id
  const startedFlag = ledger?.battle_id === 'battle.matilda.normal' ? 'matilda.normal.started'
    : ledger?.battle_id === 'battle.stage2.first' ? 'stage2.first-battle.started'
      : ledger?.battle_id === 'battle.stage2.rematch' ? 'stage2.rematch.started'
        : ledger?.battle_id === 'battle.subevent2.sister-head' ? 'subevent2.battle.started'
          : ledger?.battle_id === 'battle.subevent3.fiona' ? 'subevent3.battle.started'
            : ledger?.battle_id === 'battle.subevent4.receptionist' ? 'subevent4.battle.started'
              : ledger?.battle_id === 'battle.stage3.first' ? 'stage3.first-battle.started'
                : ledger?.battle_id === 'battle.stage3.rematch' ? 'stage3.rematch.started'
                  : ledger?.battle_id === 'battle.stage4.first' ? 'stage4.first-battle.started'
                    : ledger?.battle_id === 'battle.stage4.rematch' ? 'stage4.rematch.started'
                      : ledger?.battle_id === 'battle.stage5.first' ? 'stage5.first-battle.started'
                      : ledger?.battle_id === 'battle.stage5.rematch' ? 'stage5.rematch.started'
                        : ledger?.battle_id === 'battle.stage6.first' ? 'stage6.first-battle.started'
                          : ledger?.battle_id === 'battle.stage6.rematch' ? 'stage6.rematch.started' : undefined
  const started = startedFlag !== undefined && save.progress.flags.includes(startedFlag)
  if (!ledger) {
    const battleForStartedFlag: Readonly<Record<string, string>> = {
      'matilda.normal.started': 'battle.matilda.normal',
      'stage2.first-battle.started': 'battle.stage2.first',
      'stage2.rematch.started': 'battle.stage2.rematch',
      'subevent2.battle.started': 'battle.subevent2.sister-head',
      'subevent3.battle.started': 'battle.subevent3.fiona',
      'subevent4.battle.started': 'battle.subevent4.receptionist',
      'stage3.first-battle.started': 'battle.stage3.first',
      'stage3.rematch.started': 'battle.stage3.rematch',
      'stage4.first-battle.started': 'battle.stage4.first',
      'stage4.rematch.started': 'battle.stage4.rematch',
      'stage5.first-battle.started': 'battle.stage5.first',
      'stage5.rematch.started': 'battle.stage5.rematch',
      'stage6.first-battle.started': 'battle.stage6.first',
      'stage6.rematch.started': 'battle.stage6.rematch'
    }
    const unmatchedStartedBattle = Object.entries(battleForStartedFlag).some(([flag, battleId]) =>
      save.progress.flags.includes(flag) && !save.progress.fixed_battle_history?.some((entry) => entry.battle_id === battleId))
    if (unmatchedStartedBattle ||
        ['matilda.normal.complete', 'matilda.normal.end', 'stage2.first.end', 'stage2.battle2.loss.end',
          'subevent2.battle.result', 'subevent2.post.end', 'subevent2.loss.end', 'subevent3.post.end',
          'subevent3.battle.loss.end', 'subevent4.post.end', 'stage3.rematch.loss.end', 'stage3.post.end',
          'stage4.rematch.loss.end', 'stage4.post.end', 'stage5.rematch.loss.end', 'stage5.post.end',
          'stage6.rematch.loss.end', 'stage6.post.end'].includes(checkpoint)) {
      throw new Error('Missing fixed battle ledger')
    }
    if (fixedContent.stories.find((story) => story.id === 'story.matilda.normal')?.steps.some((step) => step.id === checkpoint) &&
        !save.progress.flags.includes('matilda.tutorial.completed')) throw new Error('Tutorial not complete')
    return
  }
  const battle = definition(save)
  if (ledger.capture_bonus_enabled !== undefined && ledger.capture_bonus_enabled !==
      (battle.transfer_cards && (ledger.equipment_before ?? []).includes('greed_ring'))) {
    throw new Error('Fixed battle capture bonus does not match its equipment snapshot')
  }
  const step = fixedContent.stories.flatMap((story) => story.steps).find((step) => step.kind === 'battle' && step.battle_id === battle.id)
  const requiresMatildaTutorial = battle.id === 'battle.matilda.normal'
  const stage2Checkpoint = [STAGE2_MINIGAME_CHECKPOINT, STAGE2_MINIGAME_END_CHECKPOINT].includes(checkpoint) ||
    fixedContent.stories.some((story) => story.id.startsWith('story.stage2.') && story.steps.some((entry) => entry.id === checkpoint))
  const subevent2Checkpoint = battle.id === 'battle.subevent2.sister-head' &&
    fixedContent.stories.some((story) => story.id.startsWith('story.subevent2.') && story.steps.some((entry) => entry.id === checkpoint))
  const subevent3Checkpoint = battle.id === 'battle.subevent3.fiona' &&
    fixedContent.stories.some((story) => story.id.startsWith('story.subevent3.') && story.steps.some((entry) => entry.id === checkpoint))
  const subevent4Checkpoint = battle.id === 'battle.subevent4.receptionist' &&
    fixedContent.stories.some((story) => story.id.startsWith('story.subevent4.') && story.steps.some((entry) => entry.id === checkpoint))
  const stage3Checkpoint = battle.id.startsWith('battle.stage3.') &&
    [STAGE3_MINIGAME_CHECKPOINT, STAGE3_MINIGAME_END_CHECKPOINT].includes(checkpoint) || battle.id.startsWith('battle.stage3.') &&
      fixedContent.stories.some((story) => story.id.startsWith('story.stage3.') && story.steps.some((entry) => entry.id === checkpoint))
  const stage4Checkpoint = battle.id.startsWith('battle.stage4.') &&
    ([STAGE4_MINIGAME_CHECKPOINT, STAGE4_MINIGAME_END_CHECKPOINT].includes(checkpoint) ||
      fixedContent.stories.some((story) => story.id.startsWith('story.stage4.') && story.steps.some((entry) => entry.id === checkpoint)))
  const stage5Checkpoint = battle.id.startsWith('battle.stage5.') &&
    ([STAGE5_MINIGAME_CHECKPOINT, STAGE5_MINIGAME_END_CHECKPOINT].includes(checkpoint) ||
      fixedContent.stories.some((story) => story.id.startsWith('story.stage5.') && story.steps.some((entry) => entry.id === checkpoint)))
  const stage6Checkpoint = battle.id.startsWith('battle.stage6.') &&
    fixedContent.stories.some((story) => (story.id.startsWith('story.stage6.') ||
      battle.id === 'battle.stage6.rematch' && story.id.startsWith('story.stage7.')) && story.steps.some((entry) => entry.id === checkpoint))
  const laterNarrativeCheckpoint = fixedContent.stories.some((story) =>
    story.steps.some((entry) => entry.id === checkpoint)) ||
    ['subevent3.minigame', 'subevent3.minigame.end'].includes(checkpoint)
  const historicTownLedger = ledger.settled && ['town.area', 'town.encounter', 'random.await'].includes(currentCheckpoint)
  const validCheckpoint = isFixedCheckpoint(checkpoint) || battle.id.startsWith('battle.stage2.') && stage2Checkpoint ||
    subevent2Checkpoint || subevent3Checkpoint || subevent4Checkpoint || stage3Checkpoint || stage4Checkpoint || stage5Checkpoint || stage6Checkpoint ||
    ['subevent3.minigame', 'subevent3.minigame.end'].includes(checkpoint) || ledger.settled && laterNarrativeCheckpoint || historicTownLedger
  if (!step || step.kind !== 'battle' || !started || requiresMatildaTutorial && !save.progress.flags.includes('matilda.tutorial.completed') ||
      !validCheckpoint || !validateDeck(ledger.inventory_before ?? historicalInventory, ledger.player_deck, battle.player_deck_size).valid ||
      !Number.isSafeInteger(ledger.acknowledged) || ledger.acknowledged < 0 || ledger.acknowledged > ledger.rounds.length ||
      ledger.rounds.length - ledger.acknowledged > 1 || typeof ledger.settled !== 'boolean' ||
      !Number.isSafeInteger(ledger.balance_before) || ledger.balance_before < 0 ||
      !ledger.settled && JSON.stringify(save.player.equipment ?? []) !== JSON.stringify(ledger.equipment_before ?? [])) {
    throw new Error(`Invalid fixed battle progress: ${battle.id} at ${checkpoint} (started=${started}, valid=${validCheckpoint}, settled=${ledger.settled})`)
  }
  const view = fixedView(save)
  const validItemUsage = validateBattleItemUsage(ledger, ledger.rounds.length)
  if (!ledger.settled) {
    if (checkpoint !== step.id || ledger.gold_delta !== undefined || save.player.money !== ledger.balance_before ||
        ledger.inventory_before && JSON.stringify(save.player.inventory) !== JSON.stringify(ledger.inventory_before) ||
        !validItemUsage || ledger.items_before && JSON.stringify(save.player.items ?? []) !== JSON.stringify(ledger.items_before) ||
        view.outcome && ledger.acknowledged === ledger.rounds.length) throw new Error('Unsettled checkpoint mismatch')
  } else {
    if (!view.outcome || ledger.acknowledged !== ledger.rounds.length || !Number.isSafeInteger(ledger.gold_delta)) throw new Error('Invalid settlement')
    if (battle.hp.forced_outcome && view.outcome !== battle.hp.forced_outcome) throw new Error('Scripted battle did not reach its required result')
    const delta = ledger.gold_delta!
    const goldBonus = view.outcome === 'win' ? getGoldBonus((ledger.equipment_before ?? []).map((id) => ({ id }))) : 0
    const sameStoryCheckpoint = fixedContent.stories.some((story) =>
      (battle.id === 'battle.matilda.normal' ? ['story.matilda.normal', 'story.matilda.normal.loss'].includes(story.id)
        : battle.id === 'battle.subevent2.sister-head' ? story.id.startsWith('story.subevent2.')
          : battle.id === 'battle.subevent3.fiona' ? story.id.startsWith('story.subevent3.')
            : battle.id === 'battle.subevent4.receptionist' ? story.id.startsWith('story.subevent4.')
              : battle.id.startsWith('battle.stage3.') ? story.id.startsWith('story.stage3.')
              : battle.id.startsWith('battle.stage4.') ? story.id.startsWith('story.stage4.')
                : battle.id.startsWith('battle.stage5.') ? story.id.startsWith('story.stage5.')
                  : battle.id.startsWith('battle.stage6.') ? story.id.startsWith('story.stage6.') ||
                    battle.id === 'battle.stage6.rematch' && story.id.startsWith('story.stage7.') : story.id.startsWith('story.stage2.')) &&
      story.steps.some((entry) => entry.id === currentCheckpoint))
    const guildReturnFromSameStory = currentCheckpoint === GUILD_CHECKPOINT && fixedContent.stories.some((story) =>
      (battle.id === 'battle.matilda.normal' ? story.id === 'story.matilda.normal'
        : battle.id === 'battle.subevent2.sister-head' ? story.id.startsWith('story.subevent2.')
          : battle.id === 'battle.subevent3.fiona' ? story.id.startsWith('story.subevent3.')
            : battle.id === 'battle.subevent4.receptionist' ? story.id.startsWith('story.subevent4.')
              : battle.id.startsWith('battle.stage3.') ? story.id.startsWith('story.stage3.')
              : battle.id.startsWith('battle.stage4.') ? story.id.startsWith('story.stage4.')
                : battle.id.startsWith('battle.stage5.') ? story.id.startsWith('story.stage5.')
                  : battle.id.startsWith('battle.stage6.') ? story.id.startsWith('story.stage6.') ||
                    battle.id === 'battle.stage6.rematch' && story.id.startsWith('story.stage7.') : story.id.startsWith('story.stage2.')) &&
      story.steps.some((entry) => entry.id === save.progress.guild_return_checkpoint))
    const mostRecentEncounter = save.progress.last_battle_id ?? save.progress.last_jin_battle_id
    const anotherEncounterLedgerExists = [save.progress.belka_battle, save.progress.jin_battle, save.progress.subevent1_jin_battle,
      save.progress.subevent1_marco_battle, save.progress.subevent1_gald_battle, save.progress.subevent1_belka_battle,
      save.progress.random_battle].some((entry) => entry !== undefined)
    const randomBattlesAdvanced = ledger.random_battles_before !== undefined &&
      (save.progress.random_battles_completed ?? 0) > ledger.random_battles_before
    const inventoryStillRepresentsFixedSettlement = (currentCheckpoint === GUILD_CHECKPOINT
      ? guildReturnFromSameStory && !anotherEncounterLedgerExists && (!mostRecentEncounter || mostRecentEncounter === battle.id)
      : sameStoryCheckpoint) && !randomBattlesAdvanced
    if (view.outcome === 'win' && (delta < battle.gold_reward.min + goldBonus || delta > battle.gold_reward.max + goldBonus) ||
        view.outcome === 'lose' && delta !== -Math.min(ledger.balance_before, battle.hp.lose_gold) ||
        view.outcome === 'draw' && delta !== 0 || save.player.money !== ledger.balance_before + delta ||
        checkpoint === step.id && JSON.stringify(save.player.items ?? []) !== JSON.stringify(settledItems(battle, ledger, view.outcome) ?? save.player.items ?? []) ||
        inventoryStillRepresentsFixedSettlement && ledger.inventory_before &&
          JSON.stringify(save.player.inventory) !== JSON.stringify(settledInventory(battle, ledger, view)) ||
        !(historicTownLedger || (battle.id.startsWith('battle.stage2.')
          ? stage2Checkpoint
          : battle.id === 'battle.subevent2.sister-head'
            ? fixedContent.stories.some((story) => story.id.startsWith('story.subevent2.') &&
                story.steps.some((entry) => entry.id === checkpoint))
            : battle.id === 'battle.subevent3.fiona'
              ? fixedContent.stories.some((story) => story.id.startsWith('story.subevent3.') &&
                  story.steps.some((entry) => entry.id === checkpoint))
                : battle.id === 'battle.subevent4.receptionist'
                ? fixedContent.stories.some((story) => story.id.startsWith('story.subevent4.') &&
                    story.steps.some((entry) => entry.id === checkpoint))
                : battle.id.startsWith('battle.stage3.') ? stage3Checkpoint
                  : battle.id.startsWith('battle.stage4.') ? stage4Checkpoint
                  : battle.id.startsWith('battle.stage5.') ? stage5Checkpoint
                    : battle.id.startsWith('battle.stage6.') ? stage6Checkpoint
          : [step.id, step.next_id, 'matilda.normal.end'].includes(checkpoint) || laterNarrativeCheckpoint)) &&
        checkpoint !== battle.lose_checkpoint_id) {
      throw new Error('Settlement mismatch')
    }
  }
}

export function prepareFixedBattle(save: SaveData): SaveData {
  if (save.progress.fixed_battle) save = parseSave(save)
  else validateFixedState(save)
  const step = fixedContent.stories.flatMap((story) => story.steps).find((step) => step.id === save.progress.checkpoint_id)
  if (step?.kind !== 'battle') throw new Error('Not at a battle checkpoint')
  const battle = fixedContent.battles.find((entry) => entry.id === step.battle_id)!
  const previous = save.progress.fixed_battle
  if (previous && (!previous.settled || previous.battle_id === battle.id)) throw new Error('Battle already started or settled')
  const deck = save.player.prepared_deck ?? save.player.deck
  if (!validateDeck(save.player.inventory, deck, battle.player_deck_size).valid) throw new Error('Owned battle deck required')
  const startedFlag = battle.id === 'battle.matilda.normal' ? 'matilda.normal.started'
    : battle.id === 'battle.stage2.first' ? 'stage2.first-battle.started'
      : battle.id === 'battle.stage2.rematch' ? 'stage2.rematch.started'
        : battle.id === 'battle.subevent2.sister-head' ? 'subevent2.battle.started'
          : battle.id === 'battle.subevent3.fiona' ? 'subevent3.battle.started'
            : battle.id === 'battle.subevent4.receptionist' ? 'subevent4.battle.started'
                : battle.id === 'battle.stage3.first' ? 'stage3.first-battle.started'
                  : battle.id === 'battle.stage3.rematch' ? 'stage3.rematch.started'
                    : battle.id === 'battle.stage4.first' ? 'stage4.first-battle.started'
                      : battle.id === 'battle.stage4.rematch' ? 'stage4.rematch.started'
                    : battle.id === 'battle.stage5.first' ? 'stage5.first-battle.started'
                      : battle.id === 'battle.stage5.rematch' ? 'stage5.rematch.started'
                        : battle.id === 'battle.stage6.first' ? 'stage6.first-battle.started' : 'stage6.rematch.started'
  const history = previous ? [...(save.progress.fixed_battle_history ?? []), previous] : save.progress.fixed_battle_history
  const next: SaveData = { ...save, progress: { ...save.progress,
    ...(history ? { fixed_battle_history: history } : {}),
    flags: save.progress.flags.includes(startedFlag) ? [...save.progress.flags] : [...save.progress.flags, startedFlag],
    fixed_battle: { battle_id: battle.id, player_deck: deck.map((card) => ({ ...card })),
      rounds: [], acknowledged: 0, settled: false, balance_before: save.player.money,
      inventory_before: save.player.inventory.map((card) => ({ ...card })),
      equipment_before: [...(save.player.equipment ?? [])], items_before: [...(save.player.items ?? [])], round_item_ids: [],
      item_rewards: [...(battle.item_reward_ids ?? [])],
      card_reward: battle.card_reward ? { ...battle.card_reward } : null,
      capture_bonus_enabled: battle.transfer_cards && (save.player.equipment ?? []).includes('greed_ring'),
      random_battles_before: save.progress.random_battles_completed ?? 0 }
  } }
  validateFixedState(next)
  return next
}

function rollCheck(roll: number) {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid random roll')
}

export function playFixedRound(save: SaveData, playerIndex: number, roll: number, itemId?: string, bonusRoll = 0.5): SaveData {
  validateFixedState(save); rollCheck(roll)
  const ledger = save.progress.fixed_battle
  if (!ledger || ledger.settled || ledger.rounds.length !== ledger.acknowledged) throw new Error('Not selecting a card')
  const selected = itemId === undefined ? undefined : itemId as ItemId
  if (definition(save).hp.forced_outcome && selected) throw new Error('Items are disabled for a scripted-result battle')
  assertBattleItemAvailable(ledger, selected)
  const adjustment = battleItemAdjustment(selected, ledger.player_deck[playerIndex])
  const battle = definition(save)
  const before = replayFixedBattle(battle, ledger)
  const opponentIndex = selectOpponent(battle, ledger, playerIndex, roll, adjustment)
  const result = judgeCards(ledger.player_deck[playerIndex]!, opponents(battle)[opponentIndex]!)
  let bonusCaptureIndex: number | undefined
  if (result === 'win' && ledger.capture_bonus_enabled) {
    rollCheck(bonusRoll)
    const candidates = opponents(battle).map((_, index) => index)
      .filter((index) => !before.usedOpponent.includes(index) && index !== opponentIndex)
    if (candidates.length > 0) bonusCaptureIndex = candidates[Math.floor(bonusRoll * candidates.length)]
  }
  return { ...save, progress: { ...save.progress, fixed_battle: { ...ledger,
    rounds: [...ledger.rounds, { player_index: playerIndex, opponent_index: opponentIndex,
      ...(bonusCaptureIndex !== undefined ? { bonus_capture_index: bonusCaptureIndex } : {}) }],
    round_item_ids: appendBattleItem(ledger, ledger.rounds.length, selected) } } }
}

function settledItems(battle: BattleContent, ledger: FixedLedger, outcome: BattleResult): ItemId[] | undefined {
  const afterUse = consumeBattleItems(ledger.items_before, ledger.round_item_ids)
  const rewardIds = ledger.item_rewards ?? battle.item_reward_ids ?? []
  if (!afterUse || outcome !== 'win' || !rewardIds.length) return afterUse
  const rewards = rewardIds.filter((id) => !afterUse.includes(id as ItemId)) as ItemId[]
  return [...afterUse, ...rewards]
}

function settledInventory(battle: BattleContent, ledger: FixedLedger,
  view: ReturnType<typeof replayFixedBattle>): Card[] | undefined {
  if (!ledger.inventory_before || !view.outcome) return undefined
  const opponentDeck = opponents(battle)
  const transferred = view.roundResults.flatMap((round, index) => {
    if (round.result === 'win') return [round.opponent,
      ...(ledger.rounds[index]?.bonus_capture_index === undefined ? [] : [opponentDeck[ledger.rounds[index]!.bonus_capture_index!]!])]
    if (round.result === 'lose' && getItemDefinition(ledger.round_item_ids?.[index] ?? '')?.effect !== 'protect_card') return [round.player]
    return []
  })
  const inventory = applyBattlePayout({ inventory: ledger.inventory_before, money: ledger.balance_before }, view.outcome,
    { cards: transferred, gold: 0, canTransferCards: battle.transfer_cards }).inventory
  return [...inventory, ...(view.outcome === 'win' && ledger.card_reward ? [{ ...ledger.card_reward }] : [])]
}

function retainOwnedDeckCards(deck: readonly Card[], inventory: readonly Card[]): Card[] {
  const remaining = new Map<string, number>()
  for (const card of inventory) {
    const key = `${card.hand}:${card.grade}`
    remaining.set(key, (remaining.get(key) ?? 0) + 1)
  }
  return deck.filter((card) => {
    const key = `${card.hand}:${card.grade}`
    const count = remaining.get(key) ?? 0
    if (count === 0) return false
    remaining.set(key, count - 1)
    return true
  }).map((card) => ({ ...card }))
}

export function acknowledgeFixedRound(save: SaveData): SaveData {
  validateFixedState(save)
  const ledger = save.progress.fixed_battle
  if (!ledger || ledger.settled || fixedView(save).outcome || ledger.rounds.length !== ledger.acknowledged + 1) throw new Error('No ongoing pending result')
  return { ...save, progress: { ...save.progress, fixed_battle: { ...ledger, acknowledged: ledger.rounds.length } } }
}

export function settleFixedBattle(save: SaveData, roll: number): SaveData {
  validateFixedState(save); rollCheck(roll)
  const ledger = save.progress.fixed_battle
  if (!ledger || ledger.settled) throw new Error('No terminal result to settle')
  const battle = definition(save), outcome = fixedView(save).outcome
  if (!outcome) throw new Error('No terminal result to settle')
  const baseDelta = battleGoldDelta(battle, outcome, ledger.balance_before, roll)
  const delta = baseDelta + (outcome === 'win' ? getGoldBonus((ledger.equipment_before ?? []).map((id) => ({ id }))) : 0)
  if (!Number.isSafeInteger(save.player.money + delta)) throw new Error('Money overflow')
  const itemsAfter = settledItems(battle, ledger, outcome)
  const inventoryAfter = settledInventory(battle, ledger, fixedView(save))
  const deckAfter = inventoryAfter ? retainOwnedDeckCards(save.player.deck, inventoryAfter) : save.player.deck
  const preparedDeckAfter = save.player.prepared_deck && inventoryAfter &&
    validateDeck(inventoryAfter, save.player.prepared_deck, 9).valid
    ? save.player.prepared_deck : undefined
  const { prepared_deck: _preparedDeck, ...playerWithoutPreparedDeck } = save.player
  const playerAfter = inventoryAfter ? { ...playerWithoutPreparedDeck, inventory: inventoryAfter, deck: deckAfter,
    ...(preparedDeckAfter ? { prepared_deck: [...preparedDeckAfter] } : {}) } : save.player
  return { ...save, player: { ...playerAfter, money: save.player.money + delta,
    ...(itemsAfter !== undefined ? { items: itemsAfter } : {}) }, progress: { ...save.progress,
    fixed_battle: { ...ledger, acknowledged: ledger.rounds.length, settled: true, gold_delta: delta } } }
}

export function retryFixedBattle(save: SaveData): SaveData {
  const ledger = save.progress.fixed_battle
  const subevent3LossCheckpoint = 'subevent3.battle.loss.end'
  const retryable = ledger?.battle_id === 'battle.matilda.normal' &&
      ['matilda.normal.await', 'matilda.normal.loss.end'].includes(save.progress.checkpoint_id) ||
    ledger?.battle_id === 'battle.stage2.rematch' && save.progress.checkpoint_id === GUILD_CHECKPOINT &&
      save.progress.guild_return_checkpoint === 'stage2.battle2.loss.end' ||
    ledger?.battle_id === 'battle.subevent2.sister-head' && save.progress.checkpoint_id === GUILD_CHECKPOINT &&
      save.progress.guild_return_checkpoint === 'subevent2.loss.end' ||
    ledger?.battle_id === 'battle.subevent3.fiona' && save.progress.checkpoint_id === GUILD_CHECKPOINT &&
      save.progress.guild_return_checkpoint === subevent3LossCheckpoint ||
    ledger?.battle_id === 'battle.stage3.rematch' && save.progress.checkpoint_id === GUILD_CHECKPOINT &&
      save.progress.guild_return_checkpoint === 'stage3.rematch.loss.end' ||
    ledger?.battle_id === 'battle.stage4.rematch' && save.progress.checkpoint_id === GUILD_CHECKPOINT &&
      save.progress.guild_return_checkpoint === 'stage4.rematch.loss.end' ||
    ledger?.battle_id === 'battle.stage5.rematch' && save.progress.checkpoint_id === GUILD_CHECKPOINT &&
      save.progress.guild_return_checkpoint === 'stage5.rematch.loss.end' ||
    ledger?.battle_id === 'battle.stage6.rematch' && save.progress.checkpoint_id === GUILD_CHECKPOINT &&
      save.progress.guild_return_checkpoint === 'stage6.rematch.loss.end'
  parseSave(save)
  if (!ledger?.settled || fixedView(save).outcome !== 'lose' || !retryable) throw new Error('Not retrying a loss')
  const { fixed_battle: _ledger, ...progress } = save.progress
  const { guild_return_checkpoint: _origin, ...retryProgress } = progress
  const history = [...(retryProgress.fixed_battle_history ?? []), ledger]
  const reset = { ...save, progress: { ...retryProgress, checkpoint_id: ledger.battle_id === 'battle.stage2.rematch' ? 'stage2.battle2.start'
    : ledger.battle_id === 'battle.subevent2.sister-head'
    ? 'subevent2.battle.start' : ledger.battle_id === 'battle.subevent3.fiona' ? 'subevent3.battle.start'
      : ledger.battle_id === 'battle.stage3.rematch' ? 'stage3.rematch.battle'
        : ledger.battle_id === 'battle.stage4.rematch' ? 'stage4.rematch.battle'
          : ledger.battle_id === 'battle.stage5.rematch' ? 'stage5.rematch.battle'
            : ledger.battle_id === 'battle.stage6.rematch' ? 'stage6.rematch.battle' : 'matilda.normal.await', fixed_battle_history: history,
    flags: retryProgress.flags.filter((flag) => flag !== (ledger.battle_id === 'battle.matilda.normal'
      ? 'matilda.normal.started' : ledger.battle_id === 'battle.stage2.rematch' ? 'stage2.rematch.started'
        : ledger.battle_id === 'battle.subevent2.sister-head' ? 'subevent2.battle.started'
          : ledger.battle_id === 'battle.subevent3.fiona' ? 'subevent3.battle.started'
            : ledger.battle_id === 'battle.stage3.rematch' ? 'stage3.rematch.started'
              : ledger.battle_id === 'battle.stage4.rematch' ? 'stage4.rematch.started'
                : ledger.battle_id === 'battle.stage5.rematch' ? 'stage5.rematch.started' : 'stage6.rematch.started')) } }
  return prepareFixedBattle(reset)
}

export function returnFromFixedBattle(save: SaveData): SaveData {
  validateFixedState(save)
  const ledger = save.progress.fixed_battle
  if (!ledger?.settled) throw new Error('Battle not settled')
  const battle = definition(save)
  const outcome = fixedView(save).outcome
  const step = fixedContent.stories.flatMap((story) => story.steps).find((step) => step.kind === 'battle' && step.battle_id === ledger.battle_id)!
  if (step.kind !== 'battle') throw new Error('Missing return checkpoint')
  if (outcome === 'lose' && ledger.battle_id === 'battle.subevent2.sister-head') {
    return { ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT,
      guild_return_checkpoint: battle.lose_checkpoint_id ?? 'subevent2.loss.end' } }
  }
  if (outcome === 'lose' && battle.result_route === 'guild_home') {
    if (!battle.lose_checkpoint_id) throw new Error('Missing guild return checkpoint for battle loss')
    return { ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: battle.lose_checkpoint_id } }
  }
  if (outcome === 'lose' && battle.lose_checkpoint_id) {
    return { ...save, progress: { ...save.progress, checkpoint_id: battle.lose_checkpoint_id } }
  }
  return { ...save, progress: { ...save.progress, checkpoint_id: step.next_id } }
}
