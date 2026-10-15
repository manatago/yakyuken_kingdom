import { GRADES, HANDS, type Card } from './card'
import { restoreOriginalQuestionLedger, type OriginalQuestionLedger } from '../story/original-question-game'
import { restoreOriginalStrengthLedger, type OriginalStrengthLedger } from '../story/original-strength-game'
import { restoreOriginalEvidenceLedger, type OriginalEvidenceLedger } from '../story/original-evidence-game'
import { restoreOriginalExpressionLedger, type OriginalExpressionLedger } from '../story/original-expression-game'
import { restoreOriginalCurseLedger, type OriginalCurseLedger } from '../story/original-curse-game'
import { restoreOriginalTutorial, type OriginalTutorial } from '../story/original-tutorial'
import { restoreOriginalNormal, type OriginalNormal } from '../story/original-normal'
import { validateOriginalMatildaAftermath, type OriginalMatildaAftermath } from '../story/original-matilda-aftermath-save'
import originalDocument from '../../content/stories/godot-original.json'
import { parseOriginalQuest, type OriginalQuest } from '../story/original-quests'
import { validateOriginalQuestBattleLedger, validateOriginalLastLoss, type OriginalQuestBattleLedger } from '../story/original-quest-save'
import { restoreOriginalAdventurer, type OriginalAdventurer } from '../story/original-adventurer'
import { getItemDefinition, getGoldBonus, type ItemId } from './item-catalog'
import { validateDeck } from './deck'
import { validateTutorialState, type TutorialLedger } from '../battle/tutorial'
import { validateFixedState, type FixedLedger } from '../battle/fixed'
import { BELKA_CHECKPOINT, validateBelkaState, type BelkaLedger } from '../battle/belka'
import { JIN_CHECKPOINT, SUBEVENT1_JIN_BATTLE_ID, SUBEVENT1_JIN_CHECKPOINT, isSubevent1JinStoryCheckpoint, validateJinState, type JinLedger } from '../battle/jin'
import { GUILD_CHECKPOINT, ORIGINAL_STAGE1_END, guildValidationSave } from '../guild/routes'
import { validateSubevent1BelkaState } from '../battle/subevent1-belka'
import { validateRandomBattleState, type RandomBattleLedger } from '../battle/random'
import { parseStage2Minigame, STAGE2_MINIGAME_CHECKPOINT, STAGE2_MINIGAME_END_CHECKPOINT, STAGE2_REMATCH_CHECKPOINT,
  type Stage2MinigameLedger } from '../battle/stage2-minigame'
import subevent2Content from '../../content/stories/subevent2.json'
import subevent3Content from '../../content/stories/subevent3.json'
import subevent4Content from '../../content/stories/subevent4.json'
import { parseSubevent3Minigame, validateSubevent3MinigameState, type Subevent3MinigameLedger } from '../battle/subevent3-minigame'
import { parseStage3Minigame, validateStage3MinigameState, type Stage3MinigameLedger } from '../battle/stage3-minigame'
import { parseStage4Minigame, validateStage4MinigameState, type Stage4MinigameLedger } from '../battle/stage4-minigame'
import { parseStage5Minigame, validateStage5MinigameState, type Stage5MinigameLedger } from '../battle/stage5-minigame'

export interface AdventurerTutorialLedger {
  readonly step: 0 | 1 | 2 | 3
  readonly original_deck: readonly Card[]
  readonly result?: 'win' | 'lose' | 'draw'
}

export const SAVE_VERSION = 1 as const

export interface Subevent1BelkaLedger extends FixedLedger {
  readonly inventory_before: readonly Card[]
  readonly historical_deck: readonly Card[]
  readonly items_before: readonly ItemId[]
}

export interface SavePlayer {
  readonly inventory: readonly Card[]
  readonly items?: readonly ItemId[]
  readonly equipment?: readonly ItemId[]
  readonly deck: readonly Card[]
  readonly prepared_deck?: readonly Card[]
  readonly money: number
}

export interface SaveData {
  readonly save_version: typeof SAVE_VERSION
  readonly player: SavePlayer
  readonly progress: {
    readonly checkpoint_id: string
    readonly flags: readonly string[]
    readonly original_tutorial?: OriginalTutorial
    readonly original_normal?: OriginalNormal
    readonly original_matilda_aftermath?: OriginalMatildaAftermath
    readonly original_adventurer?: OriginalAdventurer
    readonly original_quest?: OriginalQuest
    readonly original_quest_battle?: OriginalQuestBattleLedger
    readonly original_completed_battles?: readonly string[]
    readonly original_completed_quests?: readonly ('subevent1' | 'subevent2' | 'subevent3' | 'subevent4')[]
    readonly original_story_origin?: 'prologue_battle_win' | 'prologue_battle_lose'
    readonly original_curse_game?: OriginalCurseLedger
    readonly original_expression_game?: OriginalExpressionLedger
    readonly original_evidence_game?: OriginalEvidenceLedger
    readonly original_strength_game?: OriginalStrengthLedger
    readonly original_question_game?: OriginalQuestionLedger
    readonly original_completed_minigames?: readonly string[]
    readonly original_last_lose_narration?: string
    readonly tutorial?: TutorialLedger
    readonly fixed_battle?: FixedLedger
    readonly fixed_battle_history?: readonly FixedLedger[]
    readonly belka_battle?: BelkaLedger
    readonly jin_draft?: readonly Card[]
    readonly jin_battle?: JinLedger
    readonly subevent1_jin_battle?: JinLedger
    readonly subevent1_marco_battle?: JinLedger
    readonly subevent1_gald_battle?: JinLedger
    readonly subevent1_belka_battle?: Subevent1BelkaLedger
    readonly random_battle?: RandomBattleLedger
    readonly town_area?: string
    readonly town_origin_checkpoint?: string
    readonly random_battles_completed?: number
    readonly adventurer_tutorial?: AdventurerTutorialLedger
    readonly last_battle_id?: string
    readonly last_jin_battle_id?: string
    readonly guild_return_checkpoint?: string
    readonly stage2_minigame?: Stage2MinigameLedger
    readonly subevent3_minigame?: Subevent3MinigameLedger
    readonly subevent3_minigame_history?: readonly Subevent3MinigameLedger[]
    readonly stage3_minigame?: Stage3MinigameLedger
    readonly stage4_minigame?: Stage4MinigameLedger
    readonly stage5_minigame?: Stage5MinigameLedger
  }
}

function record(value: unknown, fields: readonly string[], optional: readonly string[] = []): Record<string, unknown> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new TypeError('Save field must be an object')
  }
  const prototype = Object.getPrototypeOf(value)
  if (prototype !== Object.prototype && prototype !== null) {
    throw new TypeError('Save field must be a plain object')
  }
  const keys = Reflect.ownKeys(value)
  if (fields.some((key) => !Object.hasOwn(value, key)) ||
      keys.some((key) => typeof key !== 'string' || ![...fields, ...optional].includes(key))) {
    throw new TypeError('Save field has missing or unknown keys')
  }
  for (const key of keys) {
    const descriptor = Object.getOwnPropertyDescriptor(value, key)
    if (!descriptor || !('value' in descriptor)) throw new TypeError('Save field has an accessor')
  }
  return value as Record<string, unknown>
}

function identifier(value: unknown): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new TypeError('Save identifier must be a non-empty string')
  }
  return value
}

function cards(value: unknown): Card[] {
  if (!Array.isArray(value)) throw new TypeError('Save cards must be an array')
  return Array.from(value, (entry) => {
    const card = record(entry, ['hand', 'grade'])
    if (!HANDS.includes(card.hand as Card['hand']) || !GRADES.includes(card.grade as Card['grade'])) {
      throw new TypeError('Save card has an invalid hand or grade')
    }
    return { hand: card.hand as Card['hand'], grade: card.grade as Card['grade'] }
  })
}

function items(value: unknown): ItemId[] {
  if (!Array.isArray(value)) throw new TypeError('Save items must be an array')
  return Array.from(value, (entry) => {
    const id = identifier(entry)
    if (!getItemDefinition(id)) throw new TypeError('Save contains an unknown item ID')
    return id as ItemId
  })
}

function equipmentSnapshot(value: unknown): ItemId[] {
  const ids = items(value)
  if (ids.some((id) => getItemDefinition(id)?.category !== 'equipment') || new Set(ids).size !== ids.length) {
    throw new TypeError('Save equipment snapshot contains an invalid or duplicate equipment item')
  }
  return ids
}

function fixedLedger(value: unknown): FixedLedger {
  const ledger = record(value, ['battle_id', 'player_deck', 'rounds', 'acknowledged', 'settled', 'balance_before'],
    ['gold_delta', 'inventory_before', 'equipment_before', 'items_before', 'round_item_ids', 'capture_bonus_enabled', 'random_battles_before', 'item_rewards', 'card_reward'])
  if (!Array.isArray(ledger.rounds)) throw new TypeError('Invalid fixed battle rounds')
  let roundItemIds: NonNullable<FixedLedger['round_item_ids']> | undefined
  if (Object.hasOwn(ledger, 'round_item_ids')) {
    if (!Array.isArray(ledger.round_item_ids)) throw new TypeError('Invalid fixed battle item IDs')
    roundItemIds = ledger.round_item_ids.map((id) => id === null ? null : items([id])[0]!)
  }
  const parsed: FixedLedger = {
    battle_id: identifier(ledger.battle_id), player_deck: cards(ledger.player_deck),
    ...(Object.hasOwn(ledger, 'inventory_before') ? { inventory_before: cards(ledger.inventory_before) } : {}),
    acknowledged: ledger.acknowledged as number, settled: ledger.settled as boolean,
    balance_before: ledger.balance_before as number,
    ...(Object.hasOwn(ledger, 'gold_delta') ? { gold_delta: ledger.gold_delta as number } : {}),
    ...(Object.hasOwn(ledger, 'random_battles_before') ? { random_battles_before: ledger.random_battles_before as number } : {}),
    ...(Object.hasOwn(ledger, 'equipment_before') ? { equipment_before: equipmentSnapshot(ledger.equipment_before) } : {}),
    ...(Object.hasOwn(ledger, 'items_before') ? { items_before: items(ledger.items_before) } : {}),
    ...(roundItemIds ? { round_item_ids: roundItemIds } : {}),
    ...(Object.hasOwn(ledger, 'capture_bonus_enabled') ? { capture_bonus_enabled: ledger.capture_bonus_enabled as boolean } : {}),
    ...(Object.hasOwn(ledger, 'item_rewards') ? { item_rewards: items(ledger.item_rewards) } : {}),
    ...(Object.hasOwn(ledger, 'card_reward') ? { card_reward: ledger.card_reward === null ? null : cards([ledger.card_reward])[0]! } : {}),
    rounds: Array.from(ledger.rounds, (entry) => {
      const round = record(entry, ['player_index', 'opponent_index'], ['bonus_capture_index'])
      return { player_index: round.player_index as number, opponent_index: round.opponent_index as number,
        ...(Object.hasOwn(round, 'bonus_capture_index') ? { bonus_capture_index: round.bonus_capture_index as number } : {}) }
    })
  }
  if (typeof parsed.settled !== 'boolean' || parsed.capture_bonus_enabled !== undefined && typeof parsed.capture_bonus_enabled !== 'boolean' ||
      !Number.isSafeInteger(parsed.acknowledged) || parsed.acknowledged < 0 ||
      !Number.isSafeInteger(parsed.balance_before) || parsed.balance_before < 0 ||
      parsed.random_battles_before !== undefined && (!Number.isSafeInteger(parsed.random_battles_before) || parsed.random_battles_before < 0) ||
      parsed.settled && (parsed.acknowledged !== parsed.rounds.length || !Number.isSafeInteger(parsed.gold_delta))) {
    throw new TypeError('Invalid fixed battle history')
  }
  return parsed
}

function jinLedger(value: unknown): JinLedger {
  const ledger = record(value, ['battle_id', 'origin_checkpoint', 'player_deck', 'inventory_before', 'historical_deck', 'belka_preceded_jin', 'rounds', 'acknowledged', 'settled', 'balance_before'], ['gold_delta', 'items_before', 'equipment_before', 'bonus_capture_index', 'round_item_ids', 'item_rewards', 'card_reward'])
  if (!Array.isArray(ledger.rounds)) throw new TypeError('Invalid Jin rounds')
  let roundItemIds: NonNullable<JinLedger['round_item_ids']> | undefined
  if (Object.hasOwn(ledger, 'round_item_ids')) {
    if (!Array.isArray(ledger.round_item_ids)) throw new TypeError('Invalid Jin item IDs')
    roundItemIds = ledger.round_item_ids.map((id) => id === null ? null : items([id])[0]!)
  }
  return {
    battle_id: identifier(ledger.battle_id), origin_checkpoint: identifier(ledger.origin_checkpoint) as JinLedger['origin_checkpoint'],
    player_deck: cards(ledger.player_deck), inventory_before: cards(ledger.inventory_before), historical_deck: cards(ledger.historical_deck),
    belka_preceded_jin: ledger.belka_preceded_jin as boolean,
    ...(Object.hasOwn(ledger, 'items_before') ? { items_before: items(ledger.items_before) } : {}),
    ...(Object.hasOwn(ledger, 'equipment_before') ? { equipment_before: equipmentSnapshot(ledger.equipment_before) } : {}),
    ...(roundItemIds ? { round_item_ids: roundItemIds } : {}),
    ...(Object.hasOwn(ledger, 'item_rewards') ? { item_rewards: items(ledger.item_rewards) } : {}),
    ...(Object.hasOwn(ledger, 'card_reward') ? { card_reward: ledger.card_reward === null ? null : cards([ledger.card_reward])[0]! } : {}),
    ...(Object.hasOwn(ledger, 'bonus_capture_index') ? { bonus_capture_index: ledger.bonus_capture_index as number } : {}),
    acknowledged: ledger.acknowledged as number, settled: ledger.settled as boolean,
    balance_before: ledger.balance_before as number,
    ...(Object.hasOwn(ledger, 'gold_delta') ? { gold_delta: ledger.gold_delta as number } : {}),
    rounds: Array.from(ledger.rounds, (entry) => {
      const round = record(entry, ['player_index', 'opponent_index'])
      return { player_index: round.player_index as number, opponent_index: round.opponent_index as number }
    })
  }
}

export function parseSave(value: unknown): SaveData {
  const root = record(value, ['save_version', 'player', 'progress'])
  if (root.save_version !== SAVE_VERSION) throw new RangeError('Unsupported save version')

  const player = record(root.player, ['inventory', 'deck', 'money'], ['prepared_deck', 'items', 'equipment'])
  const inventory = cards(player.inventory)
  const deck = cards(player.deck)
  const itemInventory = Object.hasOwn(player, 'items') ? items(player.items) : []
  const equipment = Object.hasOwn(player, 'equipment') ? items(player.equipment) : []
  if (equipment.some((id) => getItemDefinition(id)?.category !== 'equipment') || new Set(equipment).size !== equipment.length) {
    throw new TypeError('Save equipment contains an invalid or duplicate equipment item')
  }
  const prepared = Object.hasOwn(player, 'prepared_deck') ? cards(player.prepared_deck) : undefined
  if (prepared && !validateDeck(inventory, prepared, 9).valid) {
    throw new RangeError('Prepared deck must contain nine owned cards')
  }
  if (!Number.isSafeInteger(player.money) || (player.money as number) < 0) {
    throw new RangeError('Save money must be a non-negative safe integer')
  }
  if (deck.length > 0 && !validateDeck(inventory, deck, deck.length).valid) {
    throw new RangeError('Save deck contains cards not owned by the player')
  }

const progress = record(root.progress, ['checkpoint_id', 'flags'], ['original_story_origin', 'original_completed_quests', 'original_matilda_aftermath', 'original_completed_battles', 'original_question_game', 'original_strength_game', 'original_evidence_game', 'original_expression_game', 'original_completed_minigames', 'original_curse_game', 'original_last_lose_narration', 'original_quest_battle', 'original_quest', 'original_adventurer', 'original_normal', 'original_tutorial', 'tutorial', 'fixed_battle', 'fixed_battle_history', 'belka_battle', 'jin_draft', 'jin_battle', 'subevent1_jin_battle', 'subevent1_marco_battle', 'subevent1_gald_battle', 'subevent1_belka_battle', 'random_battle', 'town_area', 'town_origin_checkpoint', 'random_battles_completed', 'adventurer_tutorial', 'last_battle_id', 'last_jin_battle_id', 'guild_return_checkpoint', 'stage2_minigame', 'subevent3_minigame', 'stage3_minigame', 'subevent3_minigame_history', 'stage4_minigame', 'stage5_minigame'])
  const completedQuests = Object.hasOwn(progress, 'original_completed_quests') ? (() => {
    const ids = progress.original_completed_quests
    if (!Array.isArray(ids) || ids.length > 4 || new Set(ids).size !== ids.length ||
        ids.some(id => !['subevent1', 'subevent2', 'subevent3', 'subevent4'].includes(id))) throw new Error('Invalid original completed quests')
    return [...ids] as ('subevent1' | 'subevent2' | 'subevent3' | 'subevent4')[]
  })() : undefined
  const storyOrigin = Object.hasOwn(progress, 'original_story_origin') ? (() => {
    if (typeof progress.original_story_origin !== 'string' || !['prologue_battle_win', 'prologue_battle_lose'].includes(progress.original_story_origin) ||
        !(String(progress.checkpoint_id).startsWith('original:stage1:') || progress.checkpoint_id === 'original:prologue:234' ||
          Object.hasOwn(progress, 'original_matilda_aftermath'))) throw new Error('Invalid original story origin')
    return progress.original_story_origin as 'prologue_battle_win' | 'prologue_battle_lose'
  })() : undefined
  const completedCampaign = Object.hasOwn(progress, 'original_completed_battles') ? (() => {
    const checkpoints = progress.original_completed_battles
    if (!Array.isArray(checkpoints) || checkpoints.length > 10 || new Set(checkpoints).size !== checkpoints.length ||
        checkpoints.some(checkpoint => {
          if (typeof checkpoint !== 'string') return true
          const [prefix, id, cursor, extra] = checkpoint.split(':')
          const command = originalDocument.sequences.find(sequence => sequence.id === id)?.commands[Number(cursor) - 1]
          return prefix !== 'original' || extra !== undefined || !/^\d+$/.test(cursor) || command?.kind !== 'battle' ||
            command.parameters.is_minigame || command.parameters.is_tutorial ||
            !/^res:\/\/battle\/chapters\/Stage[2-6]BattleChapter\.gd$/.test(String(command.parameters.chapter_path))
        })) throw new Error('Invalid original completed campaign battles')
    return checkpoints as string[]
  })() : undefined
  const originalExpression = Object.hasOwn(progress, 'original_expression_game') ? restoreOriginalExpressionLedger(progress.original_expression_game) : undefined
  const originalCompletedMinigames = Object.hasOwn(progress, 'original_completed_minigames') ? (() => {
    if (!Array.isArray(progress.original_completed_minigames) || progress.original_completed_minigames.length > 4 ||
        new Set(progress.original_completed_minigames).size !== progress.original_completed_minigames.length ||
        progress.original_completed_minigames.some(checkpoint => !['original:stage2_recover:30', 'original:stage3_recover:56', 'original:stage4_recover:18', 'original:stage5_recover:65'].includes(String(checkpoint)))) throw new Error('Invalid original completed minigames')
    return [...progress.original_completed_minigames] as string[]
  })() : undefined
  if (originalExpression && (progress.checkpoint_id !== 'original:stage2_recover:30' ||
      originalCompletedMinigames?.includes(String(progress.checkpoint_id)) ||
      ['original_strength_game', 'original_evidence_game', 'original_curse_game', 'original_quest', 'original_quest_battle', 'original_tutorial', 'original_normal', 'original_adventurer',
        'stage2_minigame', 'stage3_minigame', 'stage4_minigame', 'stage5_minigame', 'subevent3_minigame'].some(key => Object.hasOwn(progress, key)))) throw new Error('Original expression game is outside its battle')
  const originalQuest = Object.hasOwn(progress, 'original_quest') ? parseOriginalQuest(progress.original_quest, String(progress.checkpoint_id)) : undefined
  const originalEvidence = Object.hasOwn(progress, 'original_evidence_game') ? restoreOriginalEvidenceLedger(progress.original_evidence_game) : undefined
  if (originalEvidence && (progress.checkpoint_id !== 'original:stage3_recover:56' ||
      originalCompletedMinigames?.includes(String(progress.checkpoint_id)) ||
      ['original_question_game', 'original_strength_game', 'original_expression_game', 'original_curse_game', 'original_quest', 'original_quest_battle', 'original_tutorial', 'original_normal', 'original_adventurer',
        'stage2_minigame', 'stage3_minigame', 'stage4_minigame', 'stage5_minigame', 'subevent3_minigame'].some(key => Object.hasOwn(progress, key)))) throw new Error('Original evidence game is outside its battle')
  const originalQuestion = Object.hasOwn(progress, 'original_question_game') ? restoreOriginalQuestionLedger(progress.original_question_game) : undefined
  if (originalQuestion && (progress.checkpoint_id !== 'original:stage5_recover:65' ||
      originalCompletedMinigames?.includes(String(progress.checkpoint_id)) ||
      ['original_strength_game', 'original_expression_game', 'original_evidence_game', 'original_curse_game', 'original_quest', 'original_quest_battle', 'original_tutorial', 'original_normal', 'original_adventurer',
        'stage2_minigame', 'stage3_minigame', 'stage4_minigame', 'stage5_minigame', 'subevent3_minigame'].some(key => Object.hasOwn(progress, key)))) throw new Error('Original question game is outside its battle')
  const originalCurse = Object.hasOwn(progress, 'original_curse_game') ? restoreOriginalCurseLedger(progress.original_curse_game) : undefined
  const originalStrength = Object.hasOwn(progress, 'original_strength_game') ? restoreOriginalStrengthLedger(progress.original_strength_game) : undefined
  if (originalStrength && (progress.checkpoint_id !== 'original:stage4_recover:18' ||
      originalCompletedMinigames?.includes(String(progress.checkpoint_id)) ||
      ['original_question_game', 'original_expression_game', 'original_evidence_game', 'original_curse_game', 'original_quest', 'original_quest_battle', 'original_tutorial', 'original_normal', 'original_adventurer',
        'stage2_minigame', 'stage3_minigame', 'stage4_minigame', 'stage5_minigame', 'subevent3_minigame'].some(key => Object.hasOwn(progress, key)))) throw new Error('Original strength game is outside its battle')
  if (originalCurse) {
    const [, sequenceId, cursor] = String(progress.checkpoint_id).split(':')
    const command = originalDocument.sequences.find(sequence => sequence.id === sequenceId)?.commands[Number(cursor) - 1]
    if (originalQuest?.id !== 'subevent3' || !String(progress.checkpoint_id).startsWith('original:') || command?.kind !== 'battle' ||
        command.parameters.chapter_path !== 'res://battle/chapters/Subevent3MinigameChapter.gd' || !command.parameters.is_minigame ||
        ['original_quest_battle', 'original_tutorial', 'original_normal', 'original_adventurer', 'subevent3_minigame'].some(key => Object.hasOwn(progress, key))) throw new Error('Original curse game is outside its battle')
  }
  const originalQuestBattle = Object.hasOwn(progress, 'original_quest_battle') ? validateOriginalQuestBattleLedger(progress.original_quest_battle,
    { inventory, deck, money: player.money as number, items: itemInventory, equipment }, String(progress.checkpoint_id), progress.flags as string[]) : undefined
  if (originalQuestBattle && completedCampaign?.includes(originalQuestBattle.checkpoint)) {
    throw new Error('Original campaign battle is already completed')
  }
  if (originalQuestBattle && ((!originalQuest && !originalQuestBattle.chapter_id.startsWith('campaign:')) ||
      originalQuest && originalQuestBattle.chapter_id.startsWith('campaign:') ||
      ['original_tutorial', 'original_normal', 'original_adventurer'].some(key => Object.hasOwn(progress, key)))) throw new Error('Original quest battle is outside its quest')
  const originalAdventurer = Object.hasOwn(progress, 'original_adventurer') ? restoreOriginalAdventurer(progress.original_adventurer) : undefined
  if (originalAdventurer && (progress.checkpoint_id !== 'original:stage1:113' ||
      originalAdventurer.balanceBefore !== player.money || originalAdventurer.goldBonus !== getGoldBonus(equipment.map(id => ({ id }))) ||
      Object.hasOwn(progress, 'original_normal') || Object.hasOwn(progress, 'original_tutorial'))) throw new Error('Original adventurer save does not match its battle')
  const originalNormal = Object.hasOwn(progress, 'original_normal') ? restoreOriginalNormal(progress.original_normal) : undefined
  if (typeof progress.checkpoint_id === 'string' && progress.checkpoint_id.startsWith('original:')) {
    const parts = progress.checkpoint_id.split(':')
    const sequence = originalDocument.sequences.find(sequence => sequence.id === parts[1])
    const cursor = Number(parts[2])
    if (parts.length !== 3 || !sequence || !/^\d+$/.test(parts[2]) || !Number.isSafeInteger(cursor) || cursor > sequence.commands.length) {
      throw new Error('Invalid original story checkpoint')
    }
  }
  if (originalNormal && (progress.checkpoint_id !== 'original:prologue:234' ||
      originalNormal.balanceBefore !== player.money ||
      originalNormal.goldBonus !== getGoldBonus(equipment.map(id => ({ id }))) ||
      Object.hasOwn(progress, 'original_tutorial') || !validateDeck(inventory, originalNormal.initialDeck, 9).valid ||
      !validateDeck(inventory, originalNormal.battle.playerDeck, 9).valid)) {
    throw new Error('Original normal battle does not match the saved battle or owned cards')
  }
  const originalTutorial = Object.hasOwn(progress, 'original_tutorial') ? restoreOriginalTutorial(progress.original_tutorial) : undefined
  if (originalTutorial && (progress.checkpoint_id !== 'original:prologue:198' ||
      !validateDeck(inventory, originalTutorial.battle.playerDeck, 9).valid)) {
    throw new Error('Original tutorial does not match the saved battle or owned cards')
  }
  if (!Array.isArray(progress.flags)) throw new TypeError('Save flags must be an array')
  const flags = Array.from(progress.flags, identifier)
  if (new Set(flags).size !== flags.length) throw new TypeError('Save flags must be unique')
  const originalMatildaAftermath = Object.hasOwn(progress, 'original_matilda_aftermath')
    ? validateOriginalMatildaAftermath(progress.original_matilda_aftermath, String(progress.checkpoint_id),
      { inventory, deck, money: player.money as number, items: itemInventory, equipment }, flags) : undefined
  if (originalMatildaAftermath && ['original_normal', 'original_tutorial', 'original_adventurer', 'original_quest', 'original_quest_battle',
    'original_curse_game', 'original_expression_game', 'original_evidence_game', 'original_strength_game', 'original_question_game',
    'tutorial', 'fixed_battle', 'belka_battle', 'jin_battle', 'random_battle'].some(key => Object.hasOwn(progress, key))) {
    throw new Error('Matilda aftermath overlaps another active game')
  }

  let tutorial: TutorialLedger | undefined
  if (Object.hasOwn(progress, 'tutorial')) {
    const ledger = record(progress.tutorial, ['battle_id', 'rounds', 'acknowledged'], ['player_deck'])
    if (!Array.isArray(ledger.rounds) || ledger.rounds.length > 2) throw new TypeError('Invalid tutorial rounds')
    tutorial = {
      battle_id: identifier(ledger.battle_id), acknowledged: ledger.acknowledged as number,
      ...(Object.hasOwn(ledger, 'player_deck') ? { player_deck: cards(ledger.player_deck) } : {}),
      rounds: Array.from(ledger.rounds, (entry) => {
        const round = record(entry, ['player_index', 'opponent_index'])
        return { player_index: round.player_index as number, opponent_index: round.opponent_index as number }
      })
    }
  }
  const fixed = Object.hasOwn(progress, 'fixed_battle') ? fixedLedger(progress.fixed_battle) : undefined
  let fixedHistory: FixedLedger[] | undefined
  if (Object.hasOwn(progress, 'fixed_battle_history')) {
    if (!Array.isArray(progress.fixed_battle_history) || progress.fixed_battle_history.length > 100) throw new TypeError('Invalid fixed battle history')
    fixedHistory = progress.fixed_battle_history.map(fixedLedger)
    if (fixedHistory.some((entry) => !entry.settled)) throw new TypeError('Fixed battle history must contain settled battles')
  }
  let belka: BelkaLedger | undefined
  if (Object.hasOwn(progress, 'belka_battle')) {
    const ledger = record(progress.belka_battle, ['battle_id', 'origin_checkpoint', 'player_deck', 'rounds', 'acknowledged', 'settled', 'balance_before'], ['gold_delta', 'equipment_before', 'items_before', 'round_item_ids'])
    if (!Array.isArray(ledger.rounds)) throw new TypeError('Invalid Belka rounds')
    let roundItemIds: NonNullable<BelkaLedger['round_item_ids']> | undefined
    if (Object.hasOwn(ledger, 'round_item_ids')) {
      if (!Array.isArray(ledger.round_item_ids)) throw new TypeError('Invalid Belka item IDs')
      roundItemIds = ledger.round_item_ids.map((id) => id === null ? null : items([id])[0]!)
    }
    belka = {
      battle_id: identifier(ledger.battle_id), origin_checkpoint: identifier(ledger.origin_checkpoint) as BelkaLedger['origin_checkpoint'],
      player_deck: cards(ledger.player_deck), acknowledged: ledger.acknowledged as number,
      settled: ledger.settled as boolean, balance_before: ledger.balance_before as number,
      ...(Object.hasOwn(ledger, 'gold_delta') ? { gold_delta: ledger.gold_delta as number } : {}),
      ...(Object.hasOwn(ledger, 'equipment_before') ? { equipment_before: equipmentSnapshot(ledger.equipment_before) } : {}),
      ...(Object.hasOwn(ledger, 'items_before') ? { items_before: items(ledger.items_before) } : {}),
      ...(roundItemIds ? { round_item_ids: roundItemIds } : {}),
      rounds: Array.from(ledger.rounds, (entry) => {
        const round = record(entry, ['player_index', 'opponent_index'])
        return { player_index: round.player_index as number, opponent_index: round.opponent_index as number }
      })
    }
  }
  const jinDraft = Object.hasOwn(progress, 'jin_draft') ? cards(progress.jin_draft) : undefined
  const stage2Minigame = Object.hasOwn(progress, 'stage2_minigame') ? parseStage2Minigame(progress.stage2_minigame) : undefined
  const subevent3Minigame = Object.hasOwn(progress, 'subevent3_minigame') ? parseSubevent3Minigame(progress.subevent3_minigame) : undefined
  const subevent3MinigameHistory = Object.hasOwn(progress, 'subevent3_minigame_history')
    ? (() => {
      if (!Array.isArray(progress.subevent3_minigame_history)) throw new TypeError('Invalid Subevent 3 minigame history')
      return progress.subevent3_minigame_history.map(parseSubevent3Minigame)
    })() : undefined
  const stage3Minigame = Object.hasOwn(progress, 'stage3_minigame') ? parseStage3Minigame(progress.stage3_minigame) : undefined
  const stage4Minigame = Object.hasOwn(progress, 'stage4_minigame') ? parseStage4Minigame(progress.stage4_minigame) : undefined
  const stage5Minigame = Object.hasOwn(progress, 'stage5_minigame') ? parseStage5Minigame(progress.stage5_minigame) : undefined
  let adventurerTutorial: AdventurerTutorialLedger | undefined
  if (Object.hasOwn(progress, 'adventurer_tutorial')) {
    const ledger = record(progress.adventurer_tutorial, ['step', 'original_deck'], ['result'])
    const step = ledger.step
    if (!Number.isSafeInteger(step) || (step as number) < 0 || (step as number) > 3) {
      throw new RangeError('Invalid adventurer tutorial step')
    }
    if (Object.hasOwn(ledger, 'result') && !['win', 'lose', 'draw'].includes(ledger.result as string)) {
      throw new TypeError('Invalid adventurer tutorial result')
    }
    adventurerTutorial = { step: step as AdventurerTutorialLedger['step'], original_deck: cards(ledger.original_deck),
      ...(Object.hasOwn(ledger, 'result') ? { result: ledger.result as AdventurerTutorialLedger['result'] } : {}) }
    if (!validateDeck(inventory, adventurerTutorial.original_deck, adventurerTutorial.original_deck.length).valid) {
      throw new RangeError('Adventurer tutorial snapshot must contain owned cards')
    }
  }
  let jin = Object.hasOwn(progress, 'jin_battle') ? jinLedger(progress.jin_battle) : undefined
  let subevent1Jin = Object.hasOwn(progress, 'subevent1_jin_battle') ? jinLedger(progress.subevent1_jin_battle) : undefined
  const subevent1Marco = Object.hasOwn(progress, 'subevent1_marco_battle') ? jinLedger(progress.subevent1_marco_battle) : undefined
  const subevent1Gald = Object.hasOwn(progress, 'subevent1_gald_battle') ? jinLedger(progress.subevent1_gald_battle) : undefined
  let subevent1Belka: Subevent1BelkaLedger | undefined
  if (Object.hasOwn(progress, 'subevent1_belka_battle')) {
    const ledger = record(progress.subevent1_belka_battle, ['battle_id', 'player_deck', 'inventory_before', 'historical_deck', 'items_before', 'rounds', 'acknowledged', 'settled', 'balance_before'], ['gold_delta', 'equipment_before', 'round_item_ids', 'capture_bonus_enabled', 'item_rewards', 'card_reward'])
    if (!Array.isArray(ledger.rounds)) throw new TypeError('Invalid Subevent 1 Belka rounds')
    let roundItemIds: NonNullable<Subevent1BelkaLedger['round_item_ids']> | undefined
    if (Object.hasOwn(ledger, 'round_item_ids')) {
      if (!Array.isArray(ledger.round_item_ids)) throw new TypeError('Invalid Subevent 1 Belka item IDs')
      roundItemIds = ledger.round_item_ids.map((id) => id === null ? null : items([id])[0]!)
    }
    subevent1Belka = {
      battle_id: identifier(ledger.battle_id), player_deck: cards(ledger.player_deck), inventory_before: cards(ledger.inventory_before),
      historical_deck: cards(ledger.historical_deck),
      items_before: items(ledger.items_before), acknowledged: ledger.acknowledged as number, settled: ledger.settled as boolean,
      ...(Object.hasOwn(ledger, 'equipment_before') ? { equipment_before: equipmentSnapshot(ledger.equipment_before) } : {}),
      ...(roundItemIds ? { round_item_ids: roundItemIds } : {}),
      ...(Object.hasOwn(ledger, 'capture_bonus_enabled') ? { capture_bonus_enabled: ledger.capture_bonus_enabled as boolean } : {}),
      ...(Object.hasOwn(ledger, 'item_rewards') ? { item_rewards: items(ledger.item_rewards) } : {}),
      ...(Object.hasOwn(ledger, 'card_reward') ? { card_reward: ledger.card_reward === null ? null : cards([ledger.card_reward])[0]! } : {}),
      balance_before: ledger.balance_before as number,
      ...(Object.hasOwn(ledger, 'gold_delta') ? { gold_delta: ledger.gold_delta as number } : {}),
      rounds: Array.from(ledger.rounds, (entry) => {
        const round = record(entry, ['player_index', 'opponent_index'], ['bonus_capture_index'])
        return { player_index: round.player_index as number, opponent_index: round.opponent_index as number,
          ...(Object.hasOwn(round, 'bonus_capture_index') ? { bonus_capture_index: round.bonus_capture_index as number } : {}) }
      })
    }
  }
  let randomBattle: RandomBattleLedger | undefined
  if (Object.hasOwn(progress, 'random_battle')) {
    const ledger = record(progress.random_battle,
      ['battle_id', 'area_id', 'opponent_id', 'opponent_name', 'char_type', 'player_deck', 'historical_deck', 'opponent_deck', 'opponent_tendency', 'gold_reward', 'loss_gold', 'inventory_before', 'items_before', 'rounds', 'acknowledged', 'settled', 'balance_before', 'equipment_before'],
      ['item_reward_id', 'gold_delta', 'bonus_capture_index', 'dialogue_indexes', 'round_item_ids'])
    if (!Array.isArray(ledger.rounds)) throw new TypeError('Invalid random battle rounds')
    const tendencyRecord = record(ledger.opponent_tendency, [], ['rock', 'scissors', 'paper'])
    const goldReward = record(ledger.gold_reward, ['min', 'max'])
    let dialogueIndexes: NonNullable<RandomBattleLedger['dialogue_indexes']> | undefined
    if (Object.hasOwn(ledger, 'dialogue_indexes')) {
      const indexes = record(ledger.dialogue_indexes, ['greeting', 'battle_start', 'farewell_win', 'farewell_lose'])
      if (Object.values(indexes).some((index) => !Number.isSafeInteger(index) || (index as number) < 0)) {
        throw new RangeError('Random battle dialogue index must be a non-negative integer')
      }
      dialogueIndexes = { greeting: indexes.greeting as number, battle_start: indexes.battle_start as number,
        farewell_win: indexes.farewell_win as number, farewell_lose: indexes.farewell_lose as number }
    }
    let roundItemIds: NonNullable<RandomBattleLedger['round_item_ids']> | undefined
    if (Object.hasOwn(ledger, 'round_item_ids')) {
      if (!Array.isArray(ledger.round_item_ids)) throw new TypeError('Random battle item IDs must be an array')
      roundItemIds = ledger.round_item_ids.map((id) => id === null ? null : items([id])[0]!)
    }
    randomBattle = {
      battle_id: identifier(ledger.battle_id), area_id: identifier(ledger.area_id) as RandomBattleLedger['area_id'],
      opponent_id: identifier(ledger.opponent_id) as RandomBattleLedger['opponent_id'],
      opponent_name: identifier(ledger.opponent_name), char_type: ledger.char_type as RandomBattleLedger['char_type'],
      ...(Object.hasOwn(ledger, 'item_reward_id') ? { item_reward_id: items([ledger.item_reward_id])[0] } : {}),
      player_deck: cards(ledger.player_deck), historical_deck: cards(ledger.historical_deck),
      opponent_deck: cards(ledger.opponent_deck),
      opponent_tendency: Object.fromEntries(Object.entries(tendencyRecord).map(([hand, value]) => [hand, value as number])),
      ...(dialogueIndexes ? { dialogue_indexes: dialogueIndexes } : {}),
      ...(roundItemIds ? { round_item_ids: roundItemIds } : {}),
      gold_reward: { min: goldReward.min as number, max: goldReward.max as number }, loss_gold: ledger.loss_gold as number,
      inventory_before: cards(ledger.inventory_before), items_before: items(ledger.items_before),
      ...(Object.hasOwn(ledger, 'bonus_capture_index') ? { bonus_capture_index: ledger.bonus_capture_index as number } : {}),
      rounds: Array.from(ledger.rounds, (entry) => {
        const round = record(entry, ['player_index', 'opponent_index'])
        return { player_index: round.player_index as number, opponent_index: round.opponent_index as number }
      }),
      acknowledged: ledger.acknowledged as number, settled: ledger.settled as boolean,
      balance_before: ledger.balance_before as number, equipment_before: equipmentSnapshot(ledger.equipment_before),
      ...(Object.hasOwn(ledger, 'gold_delta') ? { gold_delta: ledger.gold_delta as number } : {})
    }
  }
  if (jin?.battle_id === SUBEVENT1_JIN_BATTLE_ID) {
    if (subevent1Jin) throw new TypeError('Duplicate Subevent 1 Jin ledger')
    subevent1Jin = jin
    jin = undefined
  }
  const save: SaveData = {
    save_version: SAVE_VERSION,
    player: { inventory, deck, money: player.money as number, items: itemInventory, equipment,
      ...(prepared ? { prepared_deck: prepared } : {}) },
    progress: { checkpoint_id: identifier(progress.checkpoint_id), flags,
      ...(originalQuest ? { original_quest: originalQuest } : {}),
      ...(originalQuestBattle ? { original_quest_battle: originalQuestBattle } : {}),
      ...(completedCampaign ? { original_completed_battles: completedCampaign } : {}),
      ...(completedQuests ? { original_completed_quests: completedQuests } : {}),
      ...(storyOrigin ? { original_story_origin: storyOrigin } : {}),
      ...(originalCurse ? { original_curse_game: originalCurse } : {}),
      ...(originalExpression ? { original_expression_game: originalExpression } : {}),
      ...(originalEvidence ? { original_evidence_game: originalEvidence } : {}),
      ...(originalStrength ? { original_strength_game: originalStrength } : {}),
      ...(originalQuestion ? { original_question_game: originalQuestion } : {}),
      ...(originalCompletedMinigames ? { original_completed_minigames: originalCompletedMinigames } : {}),
      ...(Object.hasOwn(progress, 'original_last_lose_narration') ? { original_last_lose_narration: validateOriginalLastLoss(progress.original_last_lose_narration) } : {}),
      ...(originalMatildaAftermath ? { original_matilda_aftermath: originalMatildaAftermath } : {}), ...(originalAdventurer ? { original_adventurer: originalAdventurer } : {}), ...(originalNormal ? { original_normal: originalNormal } : {}), ...(originalTutorial ? { original_tutorial: originalTutorial } : {}), ...(tutorial ? { tutorial } : {}), ...(fixed ? { fixed_battle: fixed } : {}),
      ...(fixedHistory ? { fixed_battle_history: fixedHistory } : {}),
      ...(belka ? { belka_battle: belka } : {}),
      ...(jinDraft ? { jin_draft: jinDraft } : {}), ...(jin ? { jin_battle: jin } : {}),
      ...(subevent1Jin ? { subevent1_jin_battle: subevent1Jin } : {}),
      ...(subevent1Marco ? { subevent1_marco_battle: subevent1Marco } : {}),
      ...(subevent1Gald ? { subevent1_gald_battle: subevent1Gald } : {}),
      ...(subevent1Belka ? { subevent1_belka_battle: subevent1Belka } : {}),
      ...(randomBattle ? { random_battle: randomBattle } : {}),
      ...(adventurerTutorial ? { adventurer_tutorial: adventurerTutorial } : {}),
      ...(Object.hasOwn(progress, 'town_area') ? { town_area: identifier(progress.town_area) } : {}),
      ...(Object.hasOwn(progress, 'town_origin_checkpoint') ? { town_origin_checkpoint: identifier(progress.town_origin_checkpoint) } : {}),
      ...(Object.hasOwn(progress, 'random_battles_completed') ? { random_battles_completed: progress.random_battles_completed as number } : {}),
      ...(Object.hasOwn(progress, 'last_battle_id') ? { last_battle_id: identifier(progress.last_battle_id) } : {}),
      ...(Object.hasOwn(progress, 'last_jin_battle_id') ? { last_jin_battle_id: identifier(progress.last_jin_battle_id) } : {}),
      ...(Object.hasOwn(progress, 'guild_return_checkpoint') ? { guild_return_checkpoint: identifier(progress.guild_return_checkpoint) } : {}),
      ...(stage2Minigame ? { stage2_minigame: stage2Minigame } : {}),
      ...(subevent3Minigame ? { subevent3_minigame: subevent3Minigame } : {}),
      ...(subevent3MinigameHistory ? { subevent3_minigame_history: subevent3MinigameHistory } : {}),
      ...(stage3Minigame ? { stage3_minigame: stage3Minigame } : {}),
      ...(stage4Minigame ? { stage4_minigame: stage4Minigame } : {}),
      ...(stage5Minigame ? { stage5_minigame: stage5Minigame } : {}) }
  }
  const stage2MinigameCheckpoint = [STAGE2_MINIGAME_CHECKPOINT, STAGE2_MINIGAME_END_CHECKPOINT].includes(save.progress.checkpoint_id)
  if (stage2MinigameCheckpoint && !stage2Minigame) throw new Error('Missing Stage 2 minigame ledger')
  if ((save.progress.checkpoint_id === STAGE2_MINIGAME_CHECKPOINT && stage2Minigame?.outcome) ||
      (save.progress.checkpoint_id === STAGE2_MINIGAME_END_CHECKPOINT && !stage2Minigame?.outcome)) {
    throw new Error('Stage 2 minigame checkpoint does not match its result')
  }
  if (save.progress.checkpoint_id === STAGE2_REMATCH_CHECKPOINT &&
      (!stage2Minigame?.outcome || !flags.includes('stage2_first_battle_done') || !flags.includes('stage2_minigame_completed'))) {
    throw new Error('Stage 2 rematch is not unlocked')
  }
  const inRandomTown = ['town.area', 'town.encounter', 'random.await'].includes(save.progress.checkpoint_id)
  const inSubevent2Story = subevent2Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id))
  const inSubevent3Story = subevent3Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id))
  const inSubevent4Story = subevent4Content.stories.some((story) => story.steps.some((step) => step.id === save.progress.checkpoint_id))
  const historicalCheckpoint = inRandomTown
    ? { ...save, progress: { ...save.progress,
      checkpoint_id: save.progress.town_origin_checkpoint === ORIGINAL_STAGE1_END ? ORIGINAL_STAGE1_END : 'matilda.normal.end',
      guild_return_checkpoint: undefined } }
    : inSubevent2Story && fixed?.battle_id !== 'battle.subevent2.sister-head'
    ? { ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end', guild_return_checkpoint: undefined } }
    : inSubevent3Story && fixed?.battle_id !== 'battle.subevent3.fiona'
    ? { ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end', guild_return_checkpoint: undefined } }
    : inSubevent4Story && fixed?.battle_id !== 'battle.subevent4.receptionist'
    ? { ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end', guild_return_checkpoint: undefined } }
    : [BELKA_CHECKPOINT, JIN_CHECKPOINT, SUBEVENT1_JIN_CHECKPOINT].includes(save.progress.checkpoint_id) ||
    isSubevent1JinStoryCheckpoint(save.progress.checkpoint_id)
    ? { ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end' } }
    : guildValidationSave(save)
  const lastBattleId = save.progress.last_battle_id ?? save.progress.last_jin_battle_id
  const latestJin = [jin, subevent1Jin, subevent1Marco, subevent1Gald]
    .find((ledger) => ledger?.battle_id === lastBattleId) ?? subevent1Gald ?? subevent1Marco ?? subevent1Jin ?? jin
  const subeventBelka = subevent1Belka
  const historicInventory = randomBattle?.inventory_before ?? fixed?.inventory_before ?? subeventBelka?.inventory_before ?? latestJin?.inventory_before ?? save.player.inventory
  const historicDeck = randomBattle?.historical_deck ?? fixed?.player_deck ?? subeventBelka?.historical_deck ?? latestJin?.historical_deck ?? save.player.deck
  const fixedBalance = fixed?.settled ? fixed.balance_before + (fixed.gold_delta ?? 0) : fixed?.balance_before
  const validationSave = { ...historicalCheckpoint,
    player: { ...historicalCheckpoint.player, inventory: historicInventory, deck: historicDeck,
      money: fixedBalance ?? (belka?.balance_before ?? save.player.money) } }
  validateTutorialState(validationSave)
  validateFixedState(fixed?.settled
    ? { ...validationSave, player: { ...validationSave.player, inventory: save.player.inventory } }
    : validationSave, save.progress.checkpoint_id, historicInventory)
  validateSubevent3MinigameState(save)
  validateStage3MinigameState(save)
  validateStage4MinigameState(save)
  validateStage5MinigameState(save)
  const jinPrecededBelka = !!(latestJin && belka && !latestJin.belka_preceded_jin)
  const belkaProjection = belka && (latestJin || inRandomTown || save.progress.checkpoint_id === JIN_CHECKPOINT || save.progress.checkpoint_id === SUBEVENT1_JIN_CHECKPOINT)
    ? { ...save, progress: { ...save.progress, checkpoint_id: belka.settled ? 'guild.home' : BELKA_CHECKPOINT,
      ...(belka.settled ? { guild_return_checkpoint: 'matilda.normal.end' } : { guild_return_checkpoint: undefined }) },
      player: { ...save.player, inventory: randomBattle?.inventory_before ?? (jinPrecededBelka ? save.player.inventory : historicInventory),
        money: belka.balance_before + (belka.settled ? (belka.gold_delta ?? 0) : 0) } }
    : save
  validateBelkaState(belkaProjection)
  const jinHistoryProjection = subeventBelka
    ? { ...save, progress: { ...save.progress, checkpoint_id: 'subevent1.gald.end' },
      player: { ...save.player, inventory: subeventBelka.inventory_before, deck: subeventBelka.historical_deck,
        money: subeventBelka.balance_before, items: subeventBelka.items_before } }
    : randomBattle
      ? { ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: 'matilda.normal.end' },
        player: { ...save.player, inventory: randomBattle.inventory_before, deck: randomBattle.historical_deck,
          money: randomBattle.balance_before } }
      : save
  validateJinState(jinHistoryProjection)
  validateSubevent1BelkaState(randomBattle
    ? { ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: 'matilda.normal.end' } }
    : save)
  if (save.progress.random_battles_completed !== undefined && (!Number.isSafeInteger(save.progress.random_battles_completed) || save.progress.random_battles_completed < 0)) {
    throw new RangeError('Invalid random battle count')
  }
  if (adventurerTutorial) {
    if (save.progress.checkpoint_id !== GUILD_CHECKPOINT || !save.progress.guild_return_checkpoint ||
        !flags.includes('matilda.tutorial.completed') || flags.includes('adventurer.tutorial.completed') ||
        JSON.stringify(deck) !== JSON.stringify(adventurerTutorial.original_deck) ||
        (adventurerTutorial.step === 3) !== (adventurerTutorial.result !== undefined) ||
        (adventurerTutorial.step === 3 && adventurerTutorial.result !== 'win')) {
      throw new Error('Adventurer tutorial ledger does not match the saved checkpoint')
    }
  }
  validateRandomBattleState(save)
  return save
}

export function createNewSave(checkpointId: string, player: SavePlayer): SaveData {
  return parseSave({
    save_version: SAVE_VERSION,
    player,
    progress: { checkpoint_id: checkpointId, flags: [] }
  })
}
