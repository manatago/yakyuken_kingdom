import { parseSave, type SaveData } from '../domain/save'
import { validateDeck } from '../domain/deck'
import { getGoldBonus } from '../domain/item-catalog'
import { originalAutoDeckIndices } from '../battle/original-janken'
import { restoreOriginalNormal, retryOriginalNormalBattle, createOriginalNormal, type OriginalNormal } from './original-normal'
import { originalStory, restoreOriginalStoryState, type OriginalStoryState } from './original'
import { createOriginalMatildaFlow, completeOriginalMatildaFlowStory, chooseOriginalMatildaRedirect,
  chooseOriginalMatildaResult, type OriginalMatildaFlow } from './original-matilda-flow'

type Action = { type: 'story-complete' } | { type: 'redirect'; choice: 'home' }
export interface OriginalMatildaAftermath {
  battle: OriginalNormal
  flow: OriginalMatildaFlow
  cursor: number
  initialFlags: string[]
  actions: Action[]
}

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key =>
    `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}

function length(flow: OriginalMatildaFlow) {
  const sequence = originalStory.sequences.find(sequence => sequence.id === flow.sequenceId)
  if (!sequence) throw new Error('Missing original Matilda aftermath sequence')
  return sequence.commands.length
}

function storyFlags(flow: OriginalMatildaFlow, cursor: number, flags: readonly string[]) {
  const state = restoreOriginalStoryState(flow.sequenceId!, cursor, Object.fromEntries(flags.map(flag => [flag, true])))
  if (state.cursor !== cursor) throw new Error('Matilda aftermath cursor is not a source boundary')
  return Object.entries(state.flags).filter(([, value]) => value).map(([key]) => key)
}

function replay(ledger: OriginalMatildaAftermath) {
  let flow = createOriginalMatildaFlow(ledger.battle.outcome!)
  let entryFlags = [...ledger.initialFlags]
  let flags = [...entryFlags]
  let cursor = 0
  if (!Array.isArray(ledger.actions) || ledger.actions.length > 3) throw new Error('Invalid Matilda aftermath history')
  for (const action of ledger.actions) {
    if (!action || typeof action !== 'object') throw new Error('Invalid Matilda aftermath action')
    if (action.type === 'story-complete' && Object.keys(action).length === 1) {
      cursor = length(flow)
      flags = storyFlags(flow, cursor, entryFlags)
      flow = completeOriginalMatildaFlowStory(flow)
    } else if (action.type === 'redirect' && action.choice === 'home' && Object.keys(action).length === 2) {
      flow = chooseOriginalMatildaRedirect(flow, action.choice)
      entryFlags = [...flags]; cursor = 0
    } else throw new Error('Unknown Matilda aftermath action')
  }
  return { flow, entryFlags, cursor }
}

export function validateOriginalMatildaAftermath(value: unknown, checkpoint: string,
  player: SaveData['player'], flags: readonly string[]): OriginalMatildaAftermath {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid Matilda aftermath')
  const ledger = value as OriginalMatildaAftermath
  const keys = ['battle', 'flow', 'cursor', 'initialFlags', 'actions']
  if (Object.keys(ledger).length !== keys.length || keys.some(key => !Object.hasOwn(ledger, key))) throw new Error('Invalid Matilda aftermath fields')
  const battle = restoreOriginalNormal(ledger.battle)
  if (battle.phase !== 'finished' || !battle.outcome || player.money !== Math.max(0, battle.balanceBefore + battle.gold) ||
      battle.goldBonus !== getGoldBonus((player.equipment ?? []).map(id => ({ id }))) ||
      !validateDeck(player.inventory, battle.initialDeck, 9).valid || !validateDeck(player.inventory, battle.battle.playerDeck, 9).valid) {
    throw new Error('Matilda aftermath does not match its settled battle')
  }
  if (!Array.isArray(ledger.initialFlags) || ledger.initialFlags.some(flag => typeof flag !== 'string' || !flag.trim()) ||
      new Set(ledger.initialFlags).size !== ledger.initialFlags.length) throw new Error('Invalid Matilda initial flags')
  const restored = replay({ ...ledger, battle })
  if (canonical(restored.flow) !== canonical(ledger.flow) || !Number.isInteger(ledger.cursor) || ledger.cursor < 0 ||
      ledger.cursor > length(restored.flow) || restored.flow.phase.endsWith('choice') && ledger.cursor !== restored.cursor ||
      checkpoint !== `original:${restored.flow.sequenceId}:${ledger.cursor}`) throw new Error('Matilda aftermath does not match its history or checkpoint')
  const expectedFlags = storyFlags(restored.flow, ledger.cursor, restored.entryFlags)
  if (canonical([...expectedFlags].sort()) !== canonical([...flags].sort())) throw new Error('Matilda aftermath flags do not match the original commands')
  return structuredClone({ ...ledger, battle, flow: restored.flow })
}

export function originalMatildaAftermathInitialFlags(ledger: OriginalMatildaAftermath) { return replay(ledger).entryFlags }

function completedScene(id: string, incoming: OriginalStoryState) {
  const sequence = originalStory.sequences.find(sequence => sequence.id === id)!
  return restoreOriginalStoryState(id, sequence.commands.length, incoming.flags, incoming)
}

/** BattleScene is separate; Main's original StoryScene and its portrait cache survive. */
export function originalMatildaAftermathIncomingScene(save: SaveData): OriginalStoryState | undefined {
  const ledger = save.progress.original_matilda_aftermath
  if (!ledger) return undefined
  let incoming = restoreOriginalStoryState('prologue', 234, Object.fromEntries(ledger.initialFlags.map(flag => [flag, true])))
  if (save.progress.original_story_origin) incoming = completedScene(save.progress.original_story_origin, incoming)
  for (const action of ledger.battle.actions) {
    if (action.type === 'retry') incoming = completedScene(createOriginalMatildaFlow('lose').sequenceId!, incoming)
  }
  let flow = createOriginalMatildaFlow(ledger.battle.outcome!)
  for (const action of ledger.actions) {
    if (action.type === 'story-complete') {
      // The current sequence's final choice screen still needs its entry, not its exit.
      if (ledger.flow.phase.endsWith('choice') && action === ledger.actions.at(-1)) break
      incoming = completedScene(flow.sequenceId!, incoming)
      flow = completeOriginalMatildaFlowStory(flow)
    } else flow = chooseOriginalMatildaRedirect(flow, action.choice)
  }
  return incoming
}

/** Stage 1 reuses the exact win/lose aftermath, including its previous background fade. */
export function originalMainIncomingScene(save: SaveData): OriginalStoryState | undefined {
  if (!save.progress.checkpoint_id.startsWith('original:stage1:') || !save.progress.original_story_origin) return undefined
  const base = restoreOriginalStoryState('prologue', 234, Object.fromEntries(save.progress.flags.map(flag => [flag, true])))
  return completedScene(save.progress.original_story_origin, base)
}

export function beginOriginalMatildaAftermath(save: SaveData): SaveData {
  save = parseSave(save)
  const battle = save.progress.original_normal
  if (!battle || battle.phase !== 'finished' || !battle.outcome || save.progress.checkpoint_id !== 'original:prologue:234') {
    throw new Error('Original Matilda battle is not ready for settlement')
  }
  const flow = createOriginalMatildaFlow(battle.outcome)
  const ledger: OriginalMatildaAftermath = { battle: structuredClone(battle), flow, cursor: 0,
    initialFlags: [...save.progress.flags], actions: [] }
  const { original_normal: _completed, ...progress } = save.progress
  return parseSave({ ...save, player: { ...save.player, money: Math.max(0, battle.balanceBefore + battle.gold) },
    progress: { ...progress, checkpoint_id: `original:${flow.sequenceId}:0`, original_matilda_aftermath: ledger } })
}

export function checkpointOriginalMatildaAftermath(save: SaveData, cursor: number, complete = false): SaveData {
  save = parseSave(save)
  const ledger = save.progress.original_matilda_aftermath
  if (!ledger || !ledger.flow.phase.endsWith('story') || !Number.isInteger(cursor) || cursor < ledger.cursor || cursor > length(ledger.flow) ||
      complete && cursor !== length(ledger.flow)) throw new Error('Invalid Matilda aftermath story checkpoint')
  const flags = storyFlags(ledger.flow, cursor, replay(ledger).entryFlags)
  const next: OriginalMatildaAftermath = { ...ledger, cursor,
    ...(complete ? { flow: completeOriginalMatildaFlowStory(ledger.flow), actions: [...ledger.actions, { type: 'story-complete' } as const] } : {}) }
  return parseSave({ ...save, progress: { ...save.progress, flags, checkpoint_id: `original:${next.flow.sequenceId}:${cursor}`,
    original_matilda_aftermath: next } })
}

export function chooseOriginalMatildaAftermath(save: SaveData, choice: 'retry' | 'home' | 'next' | 'title'): SaveData {
  save = parseSave(save)
  const ledger = save.progress.original_matilda_aftermath
  if (!ledger) throw new Error('Original Matilda aftermath is not active')
  if (ledger.flow.phase === 'redirect-choice') {
    if (choice !== 'retry' && choice !== 'home') throw new Error('Invalid Matilda redirect choice')
    const flow = chooseOriginalMatildaRedirect(ledger.flow, choice)
    if (choice === 'home') return parseSave({ ...save, progress: { ...save.progress,
      checkpoint_id: `original:${flow.sequenceId}:0`, original_matilda_aftermath: { ...ledger, flow, cursor: 0,
        actions: [...ledger.actions, { type: 'redirect', choice }] } } })
    const { original_matilda_aftermath: _completed, ...progress } = save.progress
    return parseSave({ ...save, progress: { ...progress, checkpoint_id: 'original:prologue:234',
      original_normal: retryOriginalNormalBattle(ledger.battle, save.player.money) } })
  }
  if (choice === 'home') throw new Error('Invalid original result choice')
  const flow = chooseOriginalMatildaResult(ledger.flow, choice)
  const { original_matilda_aftermath: _completed, ...progress } = save.progress
  if (flow.phase === 'retry-story') {
    const deck = originalAutoDeckIndices(save.player.inventory).map(index => save.player.inventory[index])
    // battle_start is immediately followed by this battle in the original prologue.
    return parseSave({ ...save, progress: { ...progress, checkpoint_id: 'original:prologue:234',
      original_story_origin: ledger.flow.result === 'win' ? 'prologue_battle_win' : 'prologue_battle_lose',
      original_normal: createOriginalNormal(deck, save.player.money, getGoldBonus((save.player.equipment ?? []).map(id => ({ id })))) } })
  }
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: `original:${flow.sequenceId}:0`,
    original_story_origin: ledger.flow.result === 'win' ? 'prologue_battle_win' : 'prologue_battle_lose' } })
}
