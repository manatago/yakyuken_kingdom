import document from '../../content/stories/godot-stage1-battle.json'
import type { Card } from '../domain/card'
import type { SaveData } from '../domain/save'
import { ADVENTURER_TUTORIAL_COMPLETE } from '../battle/adventurer-tutorial'
import { HANDS } from '../domain/card'
import { createOriginalBattleCards, resolveOriginalJanken, selectOriginalCard, type OriginalJanken } from '../battle/original-janken'

type Action = { type: 'step'; roll: number } | { type: 'continue' }
export interface OriginalAdventurer {
  cursor: number
  phase: 'running' | 'dialogue' | 'result' | 'reward'
  battle: OriginalJanken
  text: string
  portrait: string
  portraitOptions: Record<string, unknown>
  bubbleSide: string
  bayesVisible: boolean
  gold: number
  goldBonus: number
  balanceBefore: number
  actions: Action[]
}

export function createOriginalAdventurer(goldBonus = 0, balanceBefore = 0): OriginalAdventurer {
  if (![0, 20].includes(goldBonus)) throw new Error('Invalid original adventurer gold bonus')
  if (!Number.isSafeInteger(balanceBefore) || balanceBefore < 0) throw new Error('Invalid original adventurer balance')
  const cards: Card[] = HANDS.map(hand => ({ hand, grade: 1 }))
  return { cursor: 0, phase: 'running', battle: createOriginalBattleCards(cards, document.opponent_deck as Card[], document.player_hp, document.opponent_hp),
    text: '', portrait: '', portraitOptions: {}, bubbleSide: '', bayesVisible: false, gold: 0, goldBonus, balanceBefore, actions: [] }
}

export function stepOriginalAdventurer(state: OriginalAdventurer, roll: number): OriginalAdventurer {
  if (state.phase !== 'running' || !Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid original adventurer step')
  const next = structuredClone(state)
  next.actions.push({ type: 'step', roll })
  const command = document.traces[0].commands[state.cursor]
  if (!command) {
    next.phase = 'reward'
    next.gold = document.gold_reward.min + Math.floor(roll * (document.gold_reward.max - document.gold_reward.min + 1)) + state.goldBonus
    return next
  }
  const args = command.args as unknown[]
  switch (command.kind) {
    case 'set_portrait': next.portrait = String(args[1]); next.portraitOptions = structuredClone(args[2] as Record<string, unknown>); break
    case 'set_bubble_side': next.bubbleSide = String(args[0]); break
    case 'narrator_band': next.text = String(args[0]); next.phase = 'dialogue'; break
    case 'force_build_deck': next.battle = createOriginalBattleCards(args[0] as Card[], document.opponent_deck as Card[], document.player_hp, document.opponent_hp); break
    case 'force_select_hand': {
      const hand = HANDS[Number(args[0])]
      const index = state.battle.playerDeck.findIndex((card, i) => card.hand === hand && !state.battle.playerUsed[i])
      next.battle = selectOriginalCard(state.battle, index); break
    }
    case 'show_bayes_eye': next.bayesVisible = true; break
    case 'hide_bayes_eye': next.bayesVisible = false; break
    case 'janken': next.battle = resolveOriginalJanken(state.battle, args[1] as Parameters<typeof resolveOriginalJanken>[1], roll); next.phase = 'result'; break
    default: throw new Error(`Unsupported original adventurer command: ${command.kind}`)
  }
  next.cursor++
  return next
}

export function continueOriginalAdventurer(state: OriginalAdventurer): OriginalAdventurer {
  if (state.phase !== 'dialogue' && state.phase !== 'result') throw new Error('Original adventurer cannot continue here')
  const next = structuredClone(state)
  next.phase = 'running'; next.actions.push({ type: 'continue' })
  return next
}

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}

export function restoreOriginalAdventurer(value: unknown): OriginalAdventurer {
  if (!value || typeof value !== 'object') throw new Error('Invalid original adventurer save')
  const saved = value as OriginalAdventurer
  if (!Array.isArray(saved.actions) || saved.actions.length > 100) throw new Error('Invalid original adventurer history')
  const state = replayOriginalAdventurerActions(saved, saved.actions)
  if (canonical(state) !== canonical(value)) throw new Error('Original adventurer state does not match its history')
  return state
}

function replayOriginalAdventurerActions(saved: OriginalAdventurer, actions: readonly Action[]) {
  let state = createOriginalAdventurer(saved.goldBonus, saved.balanceBefore)
  for (const action of actions) {
    if (!action || typeof action !== 'object') throw new Error('Invalid original adventurer action')
    if (action.type === 'step') state = stepOriginalAdventurer(state, action.roll)
    else if (action.type === 'continue') state = continueOriginalAdventurer(state)
    else throw new Error('Unknown original adventurer action')
  }
  return state
}

export function originalAdventurerPreResultBattle(saved: OriginalAdventurer) {
  if (saved.phase !== 'result' || saved.actions.at(-1)?.type !== 'step') throw new Error('Missing original result boundary')
  return replayOriginalAdventurerActions(saved, saved.actions.slice(0, -1)).battle
}

export function finishOriginalAdventurerSave(save: SaveData): SaveData {
  if (!save.progress.original_adventurer || save.progress.checkpoint_id !== 'original:stage1:113') throw new Error('Original adventurer is not active')
  const state = restoreOriginalAdventurer(save.progress.original_adventurer)
  if (state.phase !== 'reward' || save.player.money !== state.balanceBefore) throw new Error('Original adventurer is not ready for settlement')
  const captured = state.battle.rounds.filter(round => round.result === 'win').map(round => round.opponent)
  const { original_adventurer: _completed, ...progress } = save.progress
  return { ...save, player: { ...save.player, inventory: [...save.player.inventory, ...structuredClone(captured)], money: save.player.money + state.gold },
    progress: { ...progress, checkpoint_id: 'original:stage1:114',
      flags: [...new Set([...progress.flags, ADVENTURER_TUTORIAL_COMPLETE])] } }
}
