import type { Card, BattleResult } from '../domain/card'
import { createOriginalBattleSurface, applyOriginalBattleSurface } from './original-battle-surface'
import { createOriginalBattleCards, originalMatildaOutcome, resolveOriginalJanken, selectOriginalCard, type OriginalJanken } from '../battle/original-janken'
import { originalBattleChapter, createOriginalQuestBattle, nextOriginalQuestBattleCommand, advanceOriginalQuestBattleCommand } from './original-quest-battle'
import type { OriginalBattlePlayback, BattleTraceCommand } from './original-battle'
import { getCaptureCount, getItemDefinition, isBattleUsable, type ItemId } from '../domain/item-catalog'

type Action = { type: 'step'; roll: number; captureRoll?: number } | { type: 'continue' } | { type: 'select'; index: number } | { type: 'item'; id: ItemId }
export interface OriginalQuestRuntime {
  chapterId: string
  initialDeck: Card[]
  battle: OriginalJanken
  playback: OriginalBattlePlayback
  phase: 'running' | 'dialogue' | 'selection' | 'result' | 'finished'
  text: string
  speaker: string
  portrait: string
  portraitOptions: Record<string, unknown>
  portraitRevision: number
  portraitCommand?: BattleTraceCommand
  background: string
  pedestal: string
  pedestalOptions: Record<string, unknown>
  uiVisible: boolean
  bubbleSide: string
  waitSeconds: number
  outcome?: BattleResult
  actions: Action[]
  resources?: { initialItems: ItemId[]; equipment: ItemId[]; consumed: ItemId[]; roundItem?: ItemId }
}

function configuration(id: string) {
  return originalBattleChapter(id)
}

function applyEffect(state: OriginalQuestRuntime, command: BattleTraceCommand) {
  const args = command.args
  switch (command.kind) {
    case 'set_portrait':
      state.portrait = String(args[1]); state.portraitOptions = structuredClone(args[2] as Record<string, unknown>)
      state.portraitRevision += 1; state.portraitCommand = structuredClone(command); break
    case 'band': state.text = String(args[1]); state.speaker = String(args[0]); state.bubbleSide = ''; state.phase = 'dialogue'; break
    case 'bubble': state.text = String(args[0]); state.speaker = ''; state.bubbleSide = String((args[1] as Record<string, unknown>)?.side ?? ''); state.phase = 'dialogue'; break
    case 'background': state.background = String(args[0]); break
    case 'leave': state.portrait = ''; state.portraitRevision += 1; state.portraitCommand = structuredClone(command); break
    case 'deck': state.pedestal = String(args[0]); state.pedestalOptions = structuredClone((args[1] ?? {}) as Record<string, unknown>); break
    case 'set_battle_ui_visible': state.uiVisible = Boolean(args[0]); break
    case 'wait': state.waitSeconds = Number(args[0]); break
    default: throw new Error(`Unsupported original quest battle effect: ${command.kind}`)
  }
}

export function createOriginalQuestRuntime(id: string, deck: readonly Card[], resources?: { items: readonly ItemId[]; equipment: readonly ItemId[] }): OriginalQuestRuntime {
  const chapter = configuration(id)
  if (deck.length !== chapter.player_deck_size) throw new Error('Original quest battle deck size mismatch')
  const state: OriginalQuestRuntime = { chapterId: id, initialDeck: structuredClone([...deck]),
    battle: createOriginalBattleCards(deck, chapter.opponent_deck, chapter.player_hp, chapter.opponent_hp),
    playback: createOriginalQuestBattle(id, chapter.opponent_hp), phase: 'running', text: '', speaker: '',
    portrait: '', portraitOptions: {}, portraitRevision: 0, background: chapter.background, pedestal: '', pedestalOptions: {},
    uiVisible: true, bubbleSide: '', waitSeconds: 0, actions: [],
    ...(resources && (resources.items.length || resources.equipment.length) ? { resources: {
      initialItems: [...resources.items], equipment: [...resources.equipment], consumed: [] } } : {}) }
  for (const command of chapter.setup) applyEffect(state, command)
  return state
}

export function stepOriginalQuestRuntime(state: OriginalQuestRuntime, roll: number, captureRoll?: number): OriginalQuestRuntime {
  if (state.phase !== 'running' || !Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid original quest battle step')
  const next = structuredClone(state)
  next.waitSeconds = 0
  if (captureRoll !== undefined && (!Number.isFinite(captureRoll) || captureRoll < 0 || captureRoll >= 1)) throw new Error('Invalid original extra capture roll')
  next.actions.push({ type: 'step', roll, ...(captureRoll !== undefined ? { captureRoll } : {}) })
  const command = nextOriginalQuestBattleCommand(state.chapterId, state.playback)
  if (!command) {
    const outcome = originalMatildaOutcome(state.battle)
    if (outcome) { next.phase = 'finished'; next.outcome = outcome }
    else next.playback = createOriginalQuestBattle(state.chapterId, state.battle.opponentHp)
    return next
  }
  let result: BattleResult | undefined
  if (command.kind === 'select_hand') { next.phase = 'selection'; return next }
  if (command.kind === 'janken') {
    next.battle = resolveOriginalJanken(state.battle, {
      ...(command.args[1] as Parameters<typeof resolveOriginalJanken>[1]),
      tendency: configuration(state.chapterId).opponent_tendency,
      item: state.resources?.roundItem,
      doubleCapture: getCaptureCount((state.resources?.equipment ?? []).map(id => ({ id }))) > 1,
      captureRoll
    }, roll)
    result = next.battle.rounds.at(-1)!.result
    next.phase = 'result'
    if (next.resources?.roundItem) { next.resources.consumed.push(next.resources.roundItem); delete next.resources.roundItem }
  } else applyEffect(next, command)
  next.playback = advanceOriginalQuestBattleCommand(state.chapterId, state.playback, result)
  return next
}

export function chooseOriginalQuestRuntimeCard(state: OriginalQuestRuntime, index: number): OriginalQuestRuntime {
  if (state.phase !== 'selection') throw new Error('Original quest battle is not selecting a card')
  const next = structuredClone(state)
  next.battle = selectOriginalCard(state.battle, index)
  next.playback = advanceOriginalQuestBattleCommand(state.chapterId, state.playback)
  next.phase = 'running'
  next.actions.push({ type: 'select', index })
  return next
}

export function continueOriginalQuestRuntime(state: OriginalQuestRuntime): OriginalQuestRuntime {
  if (!['dialogue', 'result'].includes(state.phase)) throw new Error('Original quest battle cannot continue here')
  const next = structuredClone(state)
  next.phase = 'running'
  next.actions.push({ type: 'continue' })
  return next
}

export function originalQuestAvailableItems(state: OriginalQuestRuntime): ItemId[] {
  const items = [...(state.resources?.initialItems ?? [])]
  for (const id of [...(state.resources?.consumed ?? []), ...(state.resources?.roundItem ? [state.resources.roundItem] : [])]) {
    const index = items.indexOf(id)
    if (index < 0) throw new Error('Original quest used an unowned item')
    items.splice(index, 1)
  }
  return items
}

export function useOriginalQuestRuntimeItem(state: OriginalQuestRuntime, id: ItemId): OriginalQuestRuntime {
  const definition = getItemDefinition(id)
  if (state.phase !== 'selection' || !state.resources || !definition || !isBattleUsable(definition)) throw new Error('Original quest item cannot be selected')
  const next = structuredClone(state)
  if (state.resources.roundItem === id) delete next.resources!.roundItem
  else {
    if (!originalQuestAvailableItems(state).includes(id)) throw new Error('Original quest item is not owned')
    next.resources!.roundItem = id
  }
  next.actions.push({ type: 'item', id })
  return next
}

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}

/** Re-execute the immutable action ledger; saved HP/portraits are never trusted. */
export function restoreOriginalQuestRuntime(value: unknown): OriginalQuestRuntime {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid original quest battle save')
  const saved = value as OriginalQuestRuntime
  if (!Array.isArray(saved.initialDeck) || !Array.isArray(saved.actions)) throw new Error('Invalid original quest battle history')
  const state = replayOriginalQuestActions(saved, saved.actions)
  if (canonical(state) !== canonical(value)) throw new Error('Original quest battle does not match its history')
  return state
}

function replayOriginalQuestActions(saved: OriginalQuestRuntime, actions: readonly Action[], observe?: (state: OriginalQuestRuntime, command?: BattleTraceCommand) => void) {
  let state = createOriginalQuestRuntime(saved.chapterId, saved.initialDeck, saved.resources ? {
    items: saved.resources.initialItems, equipment: saved.resources.equipment } : undefined)
  for (const action of actions) {
    if (!action || typeof action !== 'object') throw new Error('Invalid original quest battle action')
    const command = observe && action.type === 'step' ? nextOriginalQuestBattleCommand(saved.chapterId, state.playback) : undefined
    switch (action.type) {
      case 'step': state = stepOriginalQuestRuntime(state, action.roll, action.captureRoll); break
      case 'select': state = chooseOriginalQuestRuntimeCard(state, action.index); break
      case 'continue': state = continueOriginalQuestRuntime(state); break
      case 'item': state = useOriginalQuestRuntimeItem(state, action.id); break
      default: throw new Error('Unknown original quest battle action')
    }
    observe?.(state, command)
  }
  return state
}

export function originalQuestBackgroundBlurred(saved: OriginalQuestRuntime): boolean {
  return originalQuestSurface(saved).blurred
}

export function originalQuestSurface(saved: OriginalQuestRuntime) {
  const surface = createOriginalBattleSurface()
  configuration(saved.chapterId).setup.forEach(command => applyOriginalBattleSurface(surface, command))
  replayOriginalQuestActions(saved, saved.actions, (_state, command) => applyOriginalBattleSurface(surface, command))
  return surface
}

/** HP/captures update after Godot's overlay, while the immutable result remains saved for resume. */
export function originalQuestPreResultBattle(state: OriginalQuestRuntime): OriginalJanken {
  if (state.phase !== 'result' || state.actions.at(-1)?.type !== 'step') throw new Error('Missing original result boundary')
  return replayOriginalQuestActions(state, state.actions.slice(0, -1)).battle
}
