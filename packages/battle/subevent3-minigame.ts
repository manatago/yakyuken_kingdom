import type { SaveData } from '../domain/save'

export const SUBEVENT3_MINIGAME_START = 'subevent3.visit.minigame'
export const SUBEVENT3_MINIGAME_CHECKPOINT = 'subevent3.minigame'
export const SUBEVENT3_MINIGAME_END = 'subevent3.minigame.end'
export const SUBEVENT3_MINIGAME_LOSS = 'subevent3.minigame.loss.end'
export const SUBEVENT3_BATTLE_CHECKPOINT = 'subevent3.battle.start'
export const SUBEVENT3_MINIGAME_LIMIT = 130
export const SUBEVENT3_MINIGAME_START_GAUGE = 110

export const SUBEVENT3_CHOICES = [
  { id: 'neutral_weather', label: '窓から見える景色の話をする', delta: 0,
    line: '...窓の外は、きれいな庭ですね。' },
  { id: 'neutral_armor', label: '鎧の紋章について尋ねる', delta: 0,
    line: 'その紋章には、何か由来があるんですか？' },
  { id: 'neutral_history', label: '屋敷の歴史を尋ねる', delta: 0,
    line: 'エドモンド家は長い歴史があるんですね。' },
  { id: 'reassure_family', label: 'ご家族も心配していると伝える', delta: 10,
    line: 'ご家族も、きっとあなたを案じていますよ。' },
  { id: 'reassure_effort', label: 'これまで耐えた努力を称える', delta: 10,
    line: '一か月も、よく頑張ってこられましたね。' },
  { id: 'reflect_worry', label: 'いま一番気がかりなことを聞く', delta: -5,
    line: '呪いが解けたら、まず何をしたいですか？' },
  { id: 'reflect_choice', label: '自分で決めたいことを聞く', delta: -5,
    line: '呪いが解けたら、次はあなた自身が決めていいんです。' },
  { id: 'challenge_rune', label: '鎧の紋章に刻まれた矛盾を指摘する', delta: -20,
    line: 'この紋章、守るための形なのに、あなたを閉じ込めています。' },
  { id: 'challenge_curse', label: '呪いが恐れを力にしていると指摘する', delta: -20,
    line: 'この呪いは、あなたが不安になるほど強くなっているようです。' }
] as const

export type Subevent3ChoiceId = (typeof SUBEVENT3_CHOICES)[number]['id'] | 'pisuke'
export interface Subevent3MinigameRound {
  readonly choices: readonly Subevent3ChoiceId[]
  readonly selected: Subevent3ChoiceId
  readonly delta: number
  readonly gauge_after: number
}
export interface Subevent3MinigameLedger {
  readonly gauge: number
  readonly rounds: readonly Subevent3MinigameRound[]
  readonly choices?: readonly Subevent3ChoiceId[]
  readonly outcome?: 'win' | 'lose'
}

function validateRolls(rolls: readonly number[]): void {
  if (rolls.length !== 4 || rolls.some((roll) => !Number.isFinite(roll) || roll < 0 || roll >= 1)) {
    throw new RangeError('A Subevent 3 choice set requires four random rolls in [0, 1)')
  }
}

export function rollSubevent3Choices(rolls: readonly number[]): Subevent3ChoiceId[] {
  validateRolls(rolls)
  const pool = SUBEVENT3_CHOICES.map(({ id }) => id)
  const choices: Subevent3ChoiceId[] = []
  for (const roll of rolls) choices.push(pool.splice(Math.floor(roll * pool.length), 1)[0]!)
  return [...choices, 'pisuke']
}

function expectedDelta(selected: Subevent3ChoiceId, previous: readonly Subevent3MinigameRound[]): number {
  if (selected === 'pisuke') {
    const priorUses = previous.filter((round) => round.selected === 'pisuke').length
    return priorUses === 0 ? -50 : priorUses === 1 ? -20 : -5
  }
  if (!isChoiceId(selected)) throw new Error('Invalid Subevent 3 minigame choice')
  return SUBEVENT3_CHOICES.find((choice) => choice.id === selected)!.delta
}

function validChoiceList(choices: readonly Subevent3ChoiceId[]): boolean {
  return choices.length === 5 && choices[4] === 'pisuke' && new Set(choices.slice(0, 4)).size === 4 &&
    choices.slice(0, 4).every((id) => SUBEVENT3_CHOICES.some((choice) => choice.id === id))
}

export function validateSubevent3Minigame(ledger: Subevent3MinigameLedger): void {
  if (!Number.isSafeInteger(ledger.gauge) || ledger.gauge < 0 || ledger.gauge > SUBEVENT3_MINIGAME_LIMIT ||
      !Array.isArray(ledger.rounds) || ledger.rounds.length > 1000) throw new Error('Invalid Subevent 3 minigame ledger')
  let gauge = SUBEVENT3_MINIGAME_START_GAUGE
  const previous: Subevent3MinigameRound[] = []
  for (const round of ledger.rounds) {
    if (!validChoiceList(round.choices) || !round.choices.includes(round.selected) ||
        round.delta !== expectedDelta(round.selected, previous)) throw new Error('Invalid Subevent 3 minigame choice')
    gauge = Math.max(0, Math.min(SUBEVENT3_MINIGAME_LIMIT, gauge + round.delta))
    if (round.gauge_after !== gauge) throw new Error('Subevent 3 minigame gauge does not match its choices')
    previous.push(round)
  }
  if (ledger.gauge !== gauge) throw new Error('Subevent 3 minigame gauge does not match its history')
  const expectedOutcome = gauge === 0 ? 'win' : gauge === SUBEVENT3_MINIGAME_LIMIT ? 'lose' : undefined
  if (ledger.outcome !== expectedOutcome || (expectedOutcome ? ledger.choices !== undefined
    : !ledger.choices || !validChoiceList(ledger.choices))) throw new Error('Subevent 3 minigame result does not match its state')
}

function isChoiceId(value: Subevent3ChoiceId): value is (typeof SUBEVENT3_CHOICES)[number]['id'] {
  return value !== 'pisuke'
}

export function validateSubevent3MinigameState(save: SaveData): void {
  const ledger = save.progress.subevent3_minigame
  const checkpoint = save.progress.checkpoint_id
  const active = checkpoint === SUBEVENT3_MINIGAME_CHECKPOINT
  const ended = checkpoint === SUBEVENT3_MINIGAME_END
  const inSuccessRoute = [SUBEVENT3_BATTLE_CHECKPOINT, 'subevent3.post.background', 'subevent3.post.end'].includes(checkpoint)
  const inFailureRoute = checkpoint === SUBEVENT3_MINIGAME_LOSS || checkpoint === 'guild.home' &&
    save.progress.guild_return_checkpoint === SUBEVENT3_MINIGAME_LOSS
  if (!ledger) {
    if (active || ended || inSuccessRoute || inFailureRoute) throw new Error('Missing Subevent 3 minigame ledger')
    if (save.progress.subevent3_minigame_history?.length) throw new Error('Minigame history requires a current attempt')
    return
  }
  validateSubevent3Minigame(ledger)
  if (active && ledger.outcome || ended && !ledger.outcome || inSuccessRoute && ledger.outcome !== 'win' ||
      inFailureRoute && ledger.outcome !== 'lose') throw new Error('Subevent 3 minigame checkpoint mismatch')
  for (const attempt of save.progress.subevent3_minigame_history ?? []) {
    validateSubevent3Minigame(attempt)
    if (!attempt.outcome) throw new Error('Subevent 3 history contains an unfinished attempt')
  }
}

export function parseSubevent3Minigame(value: unknown): Subevent3MinigameLedger {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) throw new TypeError('Invalid Subevent 3 minigame ledger')
  const root = value as Record<string, unknown>
  const keys = Reflect.ownKeys(root)
  if (keys.some((key) => typeof key !== 'string' || !['gauge', 'rounds', 'choices', 'outcome'].includes(key)) ||
      keys.some((key) => { const descriptor = Object.getOwnPropertyDescriptor(root, key); return !descriptor || !('value' in descriptor) }) ||
      !Array.isArray(root.rounds) || root.choices !== undefined && !Array.isArray(root.choices)) {
    throw new TypeError('Invalid Subevent 3 minigame ledger')
  }
  const parseChoice = (entry: unknown): Subevent3ChoiceId => {
    if (entry !== 'pisuke' && !SUBEVENT3_CHOICES.some(({ id }) => id === entry)) throw new TypeError('Unknown Subevent 3 choice')
    return entry as Subevent3ChoiceId
  }
  const ledger: Subevent3MinigameLedger = {
    gauge: root.gauge as number,
    rounds: root.rounds.map((entry) => {
      if (entry === null || typeof entry !== 'object' || Array.isArray(entry)) throw new TypeError('Invalid Subevent 3 minigame round')
      const round = entry as Record<string, unknown>
      const roundKeys = Reflect.ownKeys(round)
      if (roundKeys.some((key) => typeof key !== 'string' || !['choices', 'selected', 'delta', 'gauge_after'].includes(key)) ||
          roundKeys.some((key) => { const descriptor = Object.getOwnPropertyDescriptor(round, key); return !descriptor || !('value' in descriptor) }) ||
          !Array.isArray(round.choices)) throw new TypeError('Invalid Subevent 3 minigame round')
      return { choices: round.choices.map(parseChoice), selected: parseChoice(round.selected),
        delta: round.delta as number, gauge_after: round.gauge_after as number }
    }),
    ...(root.choices !== undefined ? { choices: root.choices.map(parseChoice) } : {}),
    ...(root.outcome !== undefined ? { outcome: root.outcome as 'win' | 'lose' } : {})
  }
  if (ledger.outcome !== undefined && ledger.outcome !== 'win' && ledger.outcome !== 'lose') throw new TypeError('Invalid Subevent 3 minigame outcome')
  validateSubevent3Minigame(ledger)
  return ledger
}

export function beginSubevent3Minigame(save: SaveData, rolls: readonly number[]): SaveData {
  if (save.progress.checkpoint_id !== SUBEVENT3_MINIGAME_START || !save.progress.flags.includes('subevent3.started') ||
      save.progress.subevent3_minigame && !save.progress.subevent3_minigame.outcome) throw new Error('Subevent 3 minigame is not ready')
  const ledger: Subevent3MinigameLedger = { gauge: SUBEVENT3_MINIGAME_START_GAUGE, rounds: [], choices: rollSubevent3Choices(rolls) }
  const history = save.progress.subevent3_minigame?.outcome
    ? [...(save.progress.subevent3_minigame_history ?? []), save.progress.subevent3_minigame] : save.progress.subevent3_minigame_history
  return { ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT3_MINIGAME_CHECKPOINT,
    ...(history ? { subevent3_minigame_history: history } : {}), subevent3_minigame: ledger } }
}

export function chooseSubevent3Option(save: SaveData, selected: Subevent3ChoiceId, rolls: readonly number[]): SaveData {
  const ledger = save.progress.subevent3_minigame
  if (save.progress.checkpoint_id !== SUBEVENT3_MINIGAME_CHECKPOINT || !ledger?.choices || ledger.outcome) throw new Error('Subevent 3 minigame is not accepting a choice')
  validateRolls(rolls)
  validateSubevent3Minigame(ledger)
  if (!ledger.choices.includes(selected)) throw new Error('Choice was not offered in this round')
  const delta = expectedDelta(selected, ledger.rounds)
  const gauge = Math.max(0, Math.min(SUBEVENT3_MINIGAME_LIMIT, ledger.gauge + delta))
  const outcome = gauge === 0 ? 'win' : gauge === SUBEVENT3_MINIGAME_LIMIT ? 'lose' : undefined
  const round: Subevent3MinigameRound = { choices: [...ledger.choices], selected, delta, gauge_after: gauge }
  const next: Subevent3MinigameLedger = { gauge, rounds: [...ledger.rounds, round],
    ...(outcome ? { outcome } : { choices: rollSubevent3Choices(rolls) }) }
  validateSubevent3Minigame(next)
  return { ...save, progress: { ...save.progress, checkpoint_id: outcome ? SUBEVENT3_MINIGAME_END : SUBEVENT3_MINIGAME_CHECKPOINT,
    subevent3_minigame: next } }
}
