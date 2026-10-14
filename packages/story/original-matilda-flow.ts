import source from '../../content/stories/godot-main-flow.json'
import type { BattleResult } from '../domain/card'

export interface OriginalMatildaFlow {
  phase: 'redirect-story' | 'redirect-choice' | 'retry-battle' | 'aftermath-story' | 'aftermath-choice' | 'retry-story' | 'next-story'
  result: BattleResult
  sequenceId?: string
  label?: string
}

const entry = source.scenario_order.find(entry => entry.id === 'prologue')!

export function createOriginalMatildaFlow(result: BattleResult): OriginalMatildaFlow {
  if (!['win', 'lose', 'draw'].includes(result)) throw new Error('Invalid original Matilda result')
  if (result === 'win') return { phase: 'aftermath-story', result, sequenceId: entry.battle_win }
  if (source.matilda_lose_behavior !== 'redirect' || source.matilda_redirect.type !== 'story_sequence') {
    throw new Error('Unsupported original Matilda redirect')
  }
  return { phase: 'redirect-story', result, sequenceId: source.matilda_redirect.sequence_id }
}

export function completeOriginalMatildaFlowStory(state: OriginalMatildaFlow): OriginalMatildaFlow {
  if (state.phase === 'redirect-story') return { ...state, phase: 'redirect-choice' }
  if (state.phase === 'aftermath-story') return { ...state, phase: 'aftermath-choice' }
  throw new Error('Original Matilda conversation is not active')
}

export function originalMatildaFlowChoices(state: OriginalMatildaFlow) {
  if (state.phase === 'redirect-choice') return source.matilda_redirect.choices.map((label, index) => ({
    label, choice: index === 0 ? 'retry' : 'home' }))
  if (state.phase === 'aftermath-choice') {
    const screen = source.result_screens.find(screen => screen.result === state.result)
    if (!screen) throw new Error('Missing original result screen')
    return structuredClone(screen.buttons)
  }
  throw new Error('Original Matilda choices are not available')
}

export function chooseOriginalMatildaRedirect(state: OriginalMatildaFlow, choice: 'retry' | 'home'): OriginalMatildaFlow {
  if (state.phase !== 'redirect-choice' || !originalMatildaFlowChoices(state).some(button => button.choice === choice)) {
    throw new Error('Invalid original Matilda redirect choice')
  }
  if (choice === 'retry') return { phase: 'retry-battle', result: state.result }
  // Main converts a draw/home to lose too, then aborts and runs the scenario aftermath.
  return { phase: 'aftermath-story', result: 'lose', sequenceId: entry.battle_lose }
}

export function chooseOriginalMatildaResult(state: OriginalMatildaFlow, choice: 'next' | 'retry' | 'title'): OriginalMatildaFlow {
  if (state.phase !== 'aftermath-choice' || !originalMatildaFlowChoices(state).some(button => button.choice === choice)) {
    throw new Error('Invalid original Matilda result choice')
  }
  if (choice === 'retry') return { phase: 'retry-story', result: state.result, sequenceId: entry.id, label: 'battle_start' }
  // _handle_battle_aftermath only handles retry. Title falls through the normal scenario loop.
  const next = source.scenario_order[source.scenario_order.indexOf(entry) + 1]
  if (!next) throw new Error('Missing original next scenario')
  return { phase: 'next-story', result: state.result, sequenceId: next.id }
}
