import document from '../../content/stories/godot-original.json'
import battleDocument from '../../content/stories/godot-quest-battles.json'
import type { Card } from '../domain/card'
import { parseSave, type SaveData, type SavePlayer } from '../domain/save'
import { getGoldBonus, type ItemId } from '../domain/item-catalog'
import { validateDeck } from '../domain/deck'
import { ORIGINAL_STAGE1_END } from '../guild/routes'
import { originalQuestBattleChapters, originalCampaignChapterId, originalBattleChapter } from './original-quest-battle'
import { restoreOriginalStoryState } from './original'
import { originalQuestIncomingScene } from './original-quests'
import { createOriginalQuestRuntime, restoreOriginalQuestRuntime, originalQuestAvailableItems, useOriginalQuestRuntimeItem, type OriginalQuestRuntime } from './original-quest-runtime'

export interface OriginalQuestBattleLedger {
  checkpoint: string
  chapter_id: string
  inventory_before: Card[]
  deck_before: Card[]
  items_before: ItemId[]
  equipment_before: ItemId[]
  money_before: number
  draft: number[]
  runtime?: OriginalQuestRuntime
  settlement?: { roll: number; gold: number }
  aftermath?: { pattern: string; cursor: number; redirect_cursor?: number; redirect_complete?: boolean }
}

export function originalQuestBattleChapter(checkpoint: string, variant?: string) {
  const [prefix, sequenceId, cursorText] = checkpoint.split(':')
  const cursor = Number(cursorText)
  const command = document.sequences.find(sequence => sequence.id === sequenceId)?.commands[cursor - 1]
  if (prefix !== 'original' || !Number.isSafeInteger(cursor) || cursor < 1 || command?.kind !== 'battle') throw new Error('Not an original quest battle checkpoint')
  const parameters = command.parameters as Record<string, unknown>
  const chapter = variant?.startsWith('campaign:') ? originalBattleChapter(variant)
    : originalQuestBattleChapters.find(chapter => chapter.chapter_path === parameters.chapter_path)
  if (!chapter || chapter.chapter_path !== parameters.chapter_path || parameters.is_minigame || parameters.is_tutorial) throw new Error('Unsupported original quest battle')
  return chapter
}

function battleParameters(checkpoint: string): Record<string, unknown> {
  const [, id, cursor] = checkpoint.split(':')
  return document.sequences.find(s => s.id === id)!.commands[Number(cursor) - 1].parameters
}

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}

function same(left: unknown, right: unknown): boolean { return canonical(left) === canonical(right) }

function rewardGold(ledger: OriginalQuestBattleLedger, roll: number): number {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1 || ledger.runtime?.phase !== 'finished') throw new Error('Original quest battle is not ready for settlement')
  const chapter = originalQuestBattleChapter(ledger.checkpoint, ledger.chapter_id)
  const { min, max } = chapter.gold_reward
  return ledger.runtime.outcome === 'win' ? min + Math.floor(roll * (Math.max(min, max) - min + 1)) + getGoldBonus(ledger.equipment_before.map(id => ({ id })))
    : ledger.runtime.outcome === 'lose' ? -Math.floor((min + max) / 4) : 0
}

function settledPlayer(ledger: OriginalQuestBattleLedger): SavePlayer {
  if (!ledger.settlement || !ledger.runtime) throw new Error('Original quest battle is not settled')
  const chapter = originalQuestBattleChapter(ledger.checkpoint, ledger.chapter_id)
  const inventory = structuredClone(ledger.inventory_before)
  const items = ledger.runtime.resources ? originalQuestAvailableItems(ledger.runtime) : [...ledger.items_before]
  if (ledger.runtime.outcome === 'win') {
    if (chapter.can_gain_cards) for (const round of ledger.runtime.battle.rounds) if (round.result === 'win') {
      inventory.push(structuredClone(round.opponent))
      if (round.extraOpponent) inventory.push(structuredClone(round.extraOpponent))
    }
    items.push(...chapter.item_rewards as ItemId[])
    if (chapter.card_reward?.hand && chapter.card_reward.grade) inventory.push(structuredClone(chapter.card_reward as Card))
  } else if (ledger.runtime.outcome === 'lose' && chapter.can_lose_cards) {
    for (const round of ledger.runtime.battle.rounds) if (round.result === 'lose' && !round.protectedCard) {
      const index = inventory.findIndex(card => card.hand === round.player.hand && card.grade === round.player.grade)
      if (index < 0) throw new Error('Captured original quest card is not owned')
      inventory.splice(index, 1)
    }
  }
  return { inventory, items, equipment: [...ledger.equipment_before],
    deck: validateDeck(inventory, ledger.deck_before, ledger.deck_before.length).valid ? structuredClone(ledger.deck_before) : [],
    money: Math.max(0, ledger.money_before + ledger.settlement.gold) }
}

export function validateOriginalQuestBattleLedger(value: unknown, player: SavePlayer, checkpoint: string, flags: readonly string[] = []): OriginalQuestBattleLedger {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid original quest battle ledger')
  const saved = value as OriginalQuestBattleLedger
  const allowed = ['checkpoint', 'chapter_id', 'inventory_before', 'deck_before', 'items_before', 'equipment_before', 'money_before', 'draft', 'runtime', 'settlement', 'aftermath']
  if (Object.keys(saved).some(key => !allowed.includes(key)) || saved.checkpoint !== checkpoint ||
      saved.chapter_id !== (saved.chapter_id.startsWith('campaign:')
        ? originalCampaignChapterId(String(battleParameters(checkpoint).chapter_path), flags)
        : originalQuestBattleChapter(checkpoint).opponent_id) ||
      !Array.isArray(saved.inventory_before) || !Array.isArray(saved.deck_before) || !Array.isArray(saved.items_before) || !Array.isArray(saved.equipment_before) ||
      !Number.isSafeInteger(saved.money_before) || saved.money_before < 0) throw new Error('Invalid original quest battle snapshot')
  if (saved.settlement && (Object.keys(saved.settlement).sort().join(',') !== 'gold,roll' ||
      rewardGold(saved, saved.settlement.roll) !== saved.settlement.gold)) throw new Error('Invalid original quest battle settlement')
  const expected = saved.settlement ? settledPlayer(saved) : { inventory: saved.inventory_before, deck: saved.deck_before,
    items: saved.runtime?.resources ? originalQuestAvailableItems(saved.runtime) : saved.items_before, equipment: saved.equipment_before, money: saved.money_before }
  if (expected.money !== player.money || !same(expected.inventory, player.inventory) || !same(expected.deck, player.deck) ||
      !same(expected.items, player.items ?? []) || !same(expected.equipment, player.equipment ?? [])) throw new Error('Original quest battle snapshot does not match saved player')
  const size = originalQuestBattleChapter(checkpoint, saved.chapter_id).player_deck_size
  if (!Array.isArray(saved.draft) || saved.draft.length > size || new Set(saved.draft).size !== saved.draft.length ||
      saved.draft.some(index => !Number.isInteger(index) || index < 0 || index >= saved.inventory_before.length)) throw new Error('Invalid original quest battle draft')
  const runtime = saved.runtime ? restoreOriginalQuestRuntime(saved.runtime) : undefined
  if (saved.aftermath && (!saved.settlement || runtime?.outcome === 'win' ||
      Object.keys(saved.aftermath).some(key => !['cursor', 'pattern', 'redirect_cursor', 'redirect_complete'].includes(key)) ||
      !battleDocument.lose_narrations.ids.includes(saved.aftermath.pattern) ||
      !Number.isInteger(saved.aftermath.cursor) || saved.aftermath.cursor < 0 ||
      saved.aftermath.cursor >= originalQuestAftermathFrames(saved).length)) throw new Error('Invalid original quest aftermath')
  if (saved.aftermath) {
    const redirect = lossRedirectSequence(saved)
    const redirectCursor = saved.aftermath.redirect_cursor
    if (redirectCursor !== undefined && (!redirect || !Number.isInteger(redirectCursor) || redirectCursor < 0 ||
        redirectCursor > redirect.commands.length || saved.aftermath.cursor < farewellFrames(saved).length) ||
        saved.aftermath.redirect_complete !== undefined && (saved.aftermath.redirect_complete !== true || !redirect || redirectCursor !== redirect.commands.length) ||
        redirect && saved.aftermath.cursor > farewellFrames(saved).length && !saved.aftermath.redirect_complete ||
        !lossPatternPool(saved).includes(saved.aftermath.pattern)) throw new Error('Invalid original quest loss redirect')
  }
  if (runtime && (runtime.chapterId !== saved.chapter_id || saved.draft.length !== size ||
      !same(runtime.initialDeck, saved.draft.map(index => saved.inventory_before[index])) ||
      !same(runtime.resources?.initialItems ?? [], saved.items_before) || !same(runtime.resources?.equipment ?? [], saved.equipment_before) ||
      !validateDeck(saved.inventory_before, runtime.initialDeck, size).valid)) throw new Error('Original quest battle deck does not match owned draft')
  return structuredClone({ ...saved, ...(runtime ? { runtime } : {}) })
}

export function startOriginalQuestBattleSave(save: SaveData): SaveData {
  const current = parseSave(save)
  if (current.progress.original_quest_battle || current.progress.original_completed_battles?.includes(current.progress.checkpoint_id)) throw new Error('Original quest battle cannot start here')
  const chapterId = current.progress.original_quest ? originalQuestBattleChapter(current.progress.checkpoint_id).opponent_id
    : originalCampaignChapterId(String(battleParameters(current.progress.checkpoint_id).chapter_path), current.progress.flags)
  originalQuestBattleChapter(current.progress.checkpoint_id, chapterId)
  const ledger: OriginalQuestBattleLedger = { checkpoint: current.progress.checkpoint_id, chapter_id: chapterId,
    inventory_before: structuredClone([...current.player.inventory]), deck_before: structuredClone([...current.player.deck]),
    items_before: [...(current.player.items ?? [])], equipment_before: [...(current.player.equipment ?? [])],
    money_before: current.player.money, draft: [] }
  return parseSave({ ...current, progress: { ...current.progress, original_quest_battle: ledger } })
}

export function setOriginalQuestBattleDraft(save: SaveData, indices: readonly number[]): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_quest_battle
  if (!ledger || ledger.runtime) throw new Error('Original quest battle is not building a deck')
  return parseSave({ ...current, progress: { ...current.progress, original_quest_battle: { ...ledger, draft: [...indices] } } })
}

export function prepareOriginalQuestBattleSave(save: SaveData): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_quest_battle
  if (!ledger || ledger.runtime) throw new Error('Original quest battle is not building a deck')
  const runtime = createOriginalQuestRuntime(ledger.chapter_id, ledger.draft.map(index => current.player.inventory[index]),
    { items: ledger.items_before, equipment: ledger.equipment_before })
  return parseSave({ ...current, player: { ...current.player, items: runtime.resources ? originalQuestAvailableItems(runtime) : current.player.items },
    progress: { ...current.progress, original_quest_battle: { ...ledger, runtime } } })
}

export function useOriginalQuestBattleItemSave(save: SaveData, id: ItemId): SaveData {
  const current = parseSave(save)
  const runtime = current.progress.original_quest_battle?.runtime
  if (!runtime) throw new Error('Original quest battle has not started')
  return updateOriginalQuestBattleSave(current, useOriginalQuestRuntimeItem(runtime, id))
}

export function updateOriginalQuestBattleSave(save: SaveData, runtime: OriginalQuestRuntime): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_quest_battle
  if (!ledger?.runtime || ledger.settlement || runtime.actions.length !== ledger.runtime.actions.length + 1 ||
      !same(runtime.actions.slice(0, -1), ledger.runtime.actions)) throw new Error('Original quest battle action history must advance once')
  return parseSave({ ...current, player: { ...current.player, items: runtime.resources ? originalQuestAvailableItems(runtime) : current.player.items },
    progress: { ...current.progress, original_quest_battle: { ...ledger, runtime } } })
}

/** Main._execute_battle applies inventory and money only after the result panel closes. */
export function settleOriginalQuestBattleSave(save: SaveData, roll: number): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_quest_battle
  if (!ledger || ledger.settlement) throw new Error('Original quest battle cannot settle twice')
  const settled = { ...ledger, settlement: { roll, gold: rewardGold(ledger, roll) } }
  const player = settledPlayer(settled)
  const prepared = current.player.prepared_deck
  return parseSave({ ...current, player: { ...player, ...(prepared && validateDeck(player.inventory, prepared, 9).valid ? { prepared_deck: prepared } : {}) },
    progress: { ...current.progress, original_quest_battle: settled } })
}

/** Resume at the command AFTER Battle, without incrementing the already-saved cursor. */
export function resumeOriginalQuestAfterVictory(save: SaveData): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_quest_battle
  const quest = current.progress.original_quest
  if (!ledger?.settlement || ledger.runtime?.outcome !== 'win') throw new Error('Original quest victory is not settled')
  const { original_quest_battle: _battle, ...progress } = current.progress
  return parseSave({ ...current, progress: { ...progress, ...(quest ? { original_quest: { ...quest,
    completed_battles: [...(quest.completed_battles ?? []), ledger.checkpoint] } }
    : { original_completed_battles: [...(progress.original_completed_battles ?? []), ledger.checkpoint] }) } })
}

export interface OriginalQuestAftermathFrame { speaker: string; text: string; portrait: string; scale: number }
type LossPattern = { frames: string[][]; outcome: string }
const lossPatterns = battleDocument.lose_narrations.patterns as Record<string, LossPattern>

function farewellFrames(ledger: OriginalQuestBattleLedger): OriginalQuestAftermathFrame[] {
  const chapter = originalQuestBattleChapter(ledger.checkpoint, ledger.chapter_id)
  const farewell = chapter.farewell[ledger.runtime!.outcome!]
  const frames: OriginalQuestAftermathFrame[] = []
  if (farewell.narration) frames.push({ speaker: '', text: String(farewell.narration), portrait: '', scale: 1 })
  const portrait = String(farewell.portrait ?? '')
  if (portrait || farewell.text) frames.push({ speaker: chapter.opponent_name, text: String(farewell.text ?? ''),
    portrait, scale: Number(farewell.portrait_scale ?? 0.5) })
  return frames
}

function usesCommonLoss(ledger: OriginalQuestBattleLedger): boolean {
  const chapter = originalQuestBattleChapter(ledger.checkpoint, ledger.chapter_id)
  const allowed = battleParameters(ledger.checkpoint).lose_patterns as string[]
  return !(allowed.length === 1 && allowed[0] === '__skip__') &&
    (chapter.lose_behavior === 'abort' || chapter.lose_redirect.type === 'story_sequence_then_guild_home')
}

function lossPatternPool(ledger: OriginalQuestBattleLedger): string[] {
  const allowed = battleParameters(ledger.checkpoint).lose_patterns as string[]
  return usesCommonLoss(ledger) && allowed.length ? allowed : battleDocument.lose_narrations.ids
}

function lossRedirectSequence(ledger: OriginalQuestBattleLedger) {
  const chapter = originalQuestBattleChapter(ledger.checkpoint, ledger.chapter_id)
  return chapter.lose_behavior === 'redirect' && chapter.lose_redirect.type === 'story_sequence_then_guild_home'
    ? document.sequences.find(s => s.id === chapter.lose_redirect.sequence_id) : undefined
}

export function originalQuestLossRedirect(save: SaveData) {
  const ledger = save.progress.original_quest_battle
  if (!ledger?.aftermath) return undefined
  const sequence = lossRedirectSequence(ledger)
  const cursor = ledger.aftermath.redirect_cursor ?? 0
  return sequence && ledger.aftermath.cursor === farewellFrames(ledger).length && !ledger.aftermath.redirect_complete
    ? { sequenceId: sequence.id, cursor } : undefined
}

/** Main._play_scene reuses StoryScene; nested loss scenes do not reset its visuals. */
export function originalQuestLossIncomingScene(save: SaveData) {
  const ledger = save.progress.original_quest_battle!
  const [, id, cursor] = ledger.checkpoint.split(':')
  const scene = restoreOriginalStoryState(id, Number(cursor), Object.fromEntries(save.progress.flags.map(flag => [flag, true])), originalQuestIncomingScene(save))
  const farewell = originalQuestBattleChapter(ledger.checkpoint, ledger.chapter_id).farewell[ledger.runtime!.outcome!]
  if (farewell.narration || farewell.portrait || farewell.text) {
    // Main farewell hides all three slots and cleans up its temporary right portrait.
    for (const portrait of Object.values(scene.portraits)) portrait.visible = false
  }
  return scene
}

export function originalQuestCompletedLossScene(save: SaveData) {
  const ledger = save.progress.original_quest_battle
  if (!ledger?.aftermath?.redirect_complete) return undefined
  const sequence = lossRedirectSequence(ledger)!
  const incoming = originalQuestLossIncomingScene(save)
  return restoreOriginalStoryState(sequence.id, sequence.commands.length, incoming.flags, incoming)
}

export function checkpointOriginalQuestLossRedirect(save: SaveData, cursor: number, flags: readonly string[], complete = false): SaveData {
  const current = parseSave(save)
  const redirect = originalQuestLossRedirect(current)
  const sequence = redirect && document.sequences.find(s => s.id === redirect.sequenceId)!
  if (!redirect || !sequence || !Number.isInteger(cursor) || cursor < redirect.cursor || cursor > sequence.commands.length ||
      complete && cursor !== sequence.commands.length) throw new Error('Invalid original quest loss scene checkpoint')
  const ledger = current.progress.original_quest_battle!
  return parseSave({ ...current, progress: { ...current.progress, flags: [...flags], original_quest_battle: {
    ...ledger, aftermath: { ...ledger.aftermath!, redirect_cursor: cursor, ...(complete ? { redirect_complete: true } : {}) } } } })
}

export function originalQuestAftermathFrames(ledger: OriginalQuestBattleLedger): OriginalQuestAftermathFrame[] {
  if (!ledger.aftermath || !ledger.runtime || ledger.runtime.outcome === 'win') throw new Error('Original quest aftermath has not started')
  const chapter = originalQuestBattleChapter(ledger.checkpoint, ledger.chapter_id)
  const farewell = chapter.farewell[ledger.runtime.outcome!]
  const frames = farewellFrames(ledger)
  if (!usesCommonLoss(ledger)) return frames
  const pattern = lossPatterns[ledger.aftermath.pattern]
  if (!pattern) throw new Error('Unknown original loss narration')
  // Main retains the farewell portrait while playing the common Band sequence.
  frames.push(...pattern.frames.map(([speaker, text]) => ({ speaker,
    text: text.replaceAll('{opponent}', String(battleParameters(ledger.checkpoint).lose_opponent || chapter.opponent_name)),
    portrait: String(farewell.portrait ?? ''), scale: Number(farewell.portrait_scale ?? 0.5) })))
  return frames
}

export function beginOriginalQuestAftermath(save: SaveData, roll: number): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_quest_battle
  if (!ledger?.settlement || ledger.runtime?.outcome === 'win' || ledger.aftermath || !Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Original quest aftermath cannot start')
  // Godot's continue chapters may omit farewell entirely; do not invent a page.
  if (!usesCommonLoss(ledger) && farewellFrames(ledger).length === 0) {
    const { original_quest_battle: _battle, ...progress } = current.progress
    const quest = current.progress.original_quest
    if (ledger.runtime!.outcome === 'lose' && originalQuestBattleChapter(ledger.checkpoint, ledger.chapter_id).lose_behavior !== 'continue') {
      const { original_quest: _quest, ...homeProgress } = progress
      return parseSave({ ...current, progress: { ...homeProgress, checkpoint_id: 'guild.home',
        guild_return_checkpoint: quest?.origin_checkpoint ?? ORIGINAL_STAGE1_END } })
    }
    return parseSave({ ...current, progress: { ...progress, ...(quest ? { original_quest: { ...quest,
      completed_battles: [...(quest.completed_battles ?? []), ledger.checkpoint] } }
      : { original_completed_battles: [...(progress.original_completed_battles ?? []), ledger.checkpoint] }) } })
  }
  const allowed = lossPatternPool(ledger)
  const alternatives = allowed.filter(id => id !== current.progress.original_last_lose_narration)
  const pool = alternatives.length ? alternatives : allowed
  const pattern = pool[Math.floor(roll * pool.length)]
  return parseSave({ ...current, progress: { ...current.progress, ...(usesCommonLoss(ledger) ? { original_last_lose_narration: pattern } : {}),
    original_quest_battle: { ...ledger, aftermath: { pattern, cursor: 0 } } } })
}

export function advanceOriginalQuestAftermath(save: SaveData): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_quest_battle
  if (!ledger?.aftermath) throw new Error('Original quest aftermath has not started')
  if (originalQuestLossRedirect(current)) throw new Error('Original quest loss scene is not complete')
  if (ledger.aftermath.cursor + 1 < originalQuestAftermathFrames(ledger).length) return parseSave({ ...current,
    progress: { ...current.progress, original_quest_battle: { ...ledger, aftermath: { ...ledger.aftermath, cursor: ledger.aftermath.cursor + 1 } } } })
  const cost = usesCommonLoss(ledger) && lossPatterns[ledger.aftermath.pattern].outcome === 'lose_clothes' ? battleDocument.lose_narrations.replacement_cost : 0
  const { original_quest_battle: _battle, original_quest: quest, ...progress } = current.progress
  if (ledger.runtime!.outcome === 'lose' && originalQuestBattleChapter(ledger.checkpoint, ledger.chapter_id).lose_behavior !== 'continue') return parseSave({ ...current, player: { ...current.player, money: Math.max(0, current.player.money - cost) },
    progress: { ...progress, checkpoint_id: 'guild.home', guild_return_checkpoint: quest?.origin_checkpoint ?? ORIGINAL_STAGE1_END } })
  // Main aborts only an actual loss; a draw resumes the next raw command.
  return parseSave({ ...current, player: { ...current.player, money: Math.max(0, current.player.money - cost) },
    progress: { ...progress, ...(quest ? { original_quest: { ...quest, completed_battles: [...(quest.completed_battles ?? []), ledger.checkpoint] } }
      : { original_completed_battles: [...(progress.original_completed_battles ?? []), ledger.checkpoint] }) } })
}

export function validateOriginalLastLoss(value: unknown): string {
  if (typeof value !== 'string' || !battleDocument.lose_narrations.ids.includes(value)) throw new Error('Invalid original last loss narration')
  return value
}
