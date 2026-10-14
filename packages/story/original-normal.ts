import type { Card, BattleResult } from '../domain/card'
import { createOriginalBattleSurface, applyOriginalBattleSurface } from './original-battle-surface'
import type { BattleTraceCommand } from './original-battle'
import type { SaveData } from '../domain/save'
import { createOriginalNormalJanken, originalMatildaOutcome, resolveOriginalJanken, selectOriginalCard, type OriginalJanken } from '../battle/original-janken'
import { advanceOriginalBattleCommand, createOriginalMatildaRoundPlayback, createOriginalBattlePlayback, nextOriginalBattleCommand, type OriginalBattlePlayback } from './original-battle'

type NormalAction = { type: 'step'; roll: number } | { type: 'continue' } | { type: 'select'; index: number } | { type: 'deck'; cards: Card[] } | { type: 'retry'; balanceBefore: number }
export interface OriginalNormal {
  battle: OriginalJanken
  initialDeck: Card[]
  playback: OriginalBattlePlayback
  phase: 'deck' | 'running' | 'dialogue' | 'selection' | 'result' | 'finished'
  text: string
  portrait: string
  portraitOptions: Record<string, unknown>
  background: string
  pedestal: string
  pedestalOptions: Record<string, unknown>
  uiVisible: boolean
  bubbleSide: string
  outcome?: BattleResult
  gold: number
  balanceBefore: number
  goldBonus: number
  actions: NormalAction[]
  seenOutfits?: number[]
}

export function createOriginalNormal(deck: readonly Card[], balanceBefore = 0, goldBonus = 0): OriginalNormal {
  if (!Number.isSafeInteger(balanceBefore) || balanceBefore < 0 || ![0, 20].includes(goldBonus)) throw new Error('Invalid original normal reward snapshot')
  const battle = createOriginalNormalJanken(deck)
  return { battle, initialDeck: structuredClone([...deck]), playback: createOriginalMatildaRoundPlayback(battle)!, phase: 'deck', text: '',
    portrait: '', portraitOptions: {}, background: 'res://assets/backgrounds/prologue/bg05_prison_cell.png',
    pedestal: 'res://assets/battle/decks/pedestal_01_marble.png', pedestalOptions: { scale: .55, position: [0, 180] },
    uiVisible: true, bubbleSide: '', gold: 0, balanceBefore, goldBonus, actions: [] }
}

export function prepareOriginalNormal(state: OriginalNormal, cards: readonly Card[]): OriginalNormal {
  if (state.phase !== 'deck') throw new Error('Original normal battle is not building a deck')
  const next = structuredClone(state)
  next.battle = createOriginalNormalJanken(cards)
  next.phase = 'running'
  next.actions.push({ type: 'deck', cards: structuredClone([...cards]) })
  return next
}

export function stepOriginalNormal(state: OriginalNormal, roll: number): OriginalNormal {
  if (state.phase !== 'running' || !Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid original normal battle step')
  const next = structuredClone(state)
  next.actions.push({ type: 'step', roll })
  const command = nextOriginalBattleCommand(state.playback)
  if (!command) {
    const outcome = originalMatildaOutcome(state.battle)
    if (outcome) {
      next.outcome = outcome; next.phase = 'finished'
      next.gold = outcome === 'win' ? 10 + Math.floor(roll * 21) + state.goldBonus : outcome === 'lose' ? -10 : 0
    }
    else {
      next.playback = createOriginalMatildaRoundPlayback(state.battle)!
      if (state.seenOutfits?.includes(state.battle.opponentHp)) next.playback.repeated = true
    }
    return next
  }
  const args = command.args
  let result: BattleResult | undefined
  switch (command.kind) {
    case 'set_portrait': next.portrait = String(args[1]); next.portraitOptions = structuredClone(args[2] as Record<string, unknown>); break
    case 'band': next.text = String(args[1]); next.bubbleSide = ''; next.phase = 'dialogue'; break
    case 'bubble': next.text = String(args[0]); next.bubbleSide = String((args[1] as Record<string, unknown>)?.side ?? ''); next.phase = 'dialogue'; break
    case 'background': next.background = String(args[0]); break
    case 'leave': next.portrait = ''; break
    case 'deck': next.pedestal = String(args[0]); next.pedestalOptions = structuredClone((args[1] ?? {}) as Record<string, unknown>); break
    case 'set_battle_ui_visible': next.uiVisible = Boolean(args[0]); break
    case 'wait': break
    case 'select_hand': next.phase = 'selection'; return next
    case 'janken':
      next.battle = resolveOriginalJanken(state.battle, args[1] as Parameters<typeof resolveOriginalJanken>[1], roll)
      result = next.battle.rounds.at(-1)!.result
      next.phase = 'result'
      break
    default: throw new Error(`Unsupported original normal battle command: ${command.kind}`)
  }
  next.playback = advanceOriginalBattleCommand(state.playback, result)
  return next
}

export function continueOriginalNormal(state: OriginalNormal): OriginalNormal {
  if (state.phase !== 'dialogue' && state.phase !== 'result') throw new Error('Original normal battle cannot continue here')
  const next = structuredClone(state)
  next.phase = 'running'
  next.actions.push({ type: 'continue' })
  return next
}

export function chooseOriginalNormalCard(state: OriginalNormal, index: number): OriginalNormal {
  if (state.phase !== 'selection') throw new Error('Original normal battle is not selecting a card')
  const next = structuredClone(state)
  next.battle = selectOriginalCard(state.battle, index)
  next.playback = advanceOriginalBattleCommand(state.playback)
  next.phase = 'running'
  next.actions.push({ type: 'select', index })
  return next
}

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}

export function restoreOriginalNormal(value: unknown): OriginalNormal {
  if (!value || typeof value !== 'object') throw new Error('Invalid original normal battle save')
  const saved = value as OriginalNormal
  if (!Array.isArray(saved.actions)) throw new Error('Invalid original normal battle history')
  const state = replayOriginalNormalActions(saved, saved.actions)
  if (canonical(state) !== canonical(value)) throw new Error('Original normal battle does not match its history')
  return state
}

function replayOriginalNormalActions(saved: OriginalNormal, actions: readonly NormalAction[], observe?: (state: OriginalNormal, action: NormalAction, command?: BattleTraceCommand) => void) {
  let state = createOriginalNormal(saved.initialDeck, saved.balanceBefore, saved.goldBonus)
  for (const action of actions) {
    if (!action || typeof action !== 'object') throw new Error('Invalid original normal battle action')
    const command = observe && action.type === 'step' ? nextOriginalBattleCommand(state.playback) : undefined
    switch (action.type) {
      case 'step': state = stepOriginalNormal(state, action.roll); break
      case 'continue': state = continueOriginalNormal(state); break
      case 'select': state = chooseOriginalNormalCard(state, action.index); break
      case 'deck': state = prepareOriginalNormal(state, action.cards); break
      case 'retry': state = retryOriginalNormalBattle(state, action.balanceBefore); break
      default: throw new Error('Unknown original normal battle action')
    }
    observe?.(state, action, command)
  }
  return state
}

export function originalNormalBackgroundBlurred(saved: OriginalNormal): boolean {
  return originalNormalSurface(saved).blurred
}

export function originalNormalSurface(saved: OriginalNormal) {
  let surface = createOriginalBattleSurface()
  replayOriginalNormalActions(saved, saved.actions, (_state, action, command) => {
    if (action.type === 'retry') surface = createOriginalBattleSurface()
    applyOriginalBattleSurface(surface, command)
  })
  return surface
}

export function originalNormalPreResultBattle(saved: OriginalNormal) {
  if (saved.phase !== 'result' || saved.actions.at(-1)?.type !== 'step') throw new Error('Missing original result boundary')
  return replayOriginalNormalActions(saved, saved.actions.slice(0, -1)).battle
}

/** Main's redirect retry reuses its chapter instance; its first-call flags do not reset. */
export function retryOriginalNormalBattle(state: OriginalNormal, balanceBefore: number): OriginalNormal {
  if (state.phase !== 'finished' || state.outcome === 'win') throw new Error('Original Matilda cannot retry this battle')
  const seen = new Set(state.seenOutfits ?? [])
  let hp = 3
  for (const round of state.battle.rounds) {
    seen.add(hp)
    if (round.result === 'win') hp--
  }
  const next = createOriginalNormal(state.initialDeck, balanceBefore, state.goldBonus)
  next.seenOutfits = [...seen].sort((a, b) => b - a)
  next.playback = createOriginalBattlePlayback('outfit_3', seen.has(3))
  next.actions = [...structuredClone(state.actions), { type: 'retry', balanceBefore }]
  return next
}

export function finishOriginalNormalSave(save: SaveData): SaveData {
  if (!save.progress.original_normal || save.progress.checkpoint_id !== 'original:prologue:234') throw new Error('Original normal battle is not active')
  const state = restoreOriginalNormal(save.progress.original_normal)
  if (state.phase !== 'finished' || save.player.money !== state.balanceBefore) throw new Error('Original normal battle is not ready for settlement')
  const { original_normal: _completed, ...progress } = save.progress
  return { ...save, player: { ...save.player, money: Math.max(0, state.balanceBefore + state.gold) },
    progress: { ...progress, checkpoint_id: `original:${state.outcome === 'win' ? 'prologue_battle_win' : 'prologue_battle_lose'}:0` } }
}
