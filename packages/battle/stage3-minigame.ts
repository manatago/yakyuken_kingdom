import type { SaveData } from '../domain/save'

export const STAGE3_MINIGAME_CHECKPOINT = 'stage3.minigame'
export const STAGE3_MINIGAME_END_CHECKPOINT = 'stage3.minigame.end'
export const STAGE3_REMATCH_CHECKPOINT = 'stage3.rematch.background'
export const STAGE3_GAUGE_LIMIT = 130
const GAUGE_START = 100
const HIT_DELTA = -40
const MISS_DELTA = 5

export const STAGE3_EVIDENCE = {
  minutes: '審査会の議事録', access: '閲覧記録', letter: '日付入りの通知',
  inventory: '備品台帳', witness: '証言の写し', seal: '封印番号', signature: '確認署名'
} as const
export const STAGE3_CHAPTERS = {
  intake: '受付の記録', review: '審査の手順', custody: '資料の保管', notice: '通知の経緯',
  appeal: '異議申立て', correction: '訂正記録', archive: '保管台帳',
  history: '教会の沿革', doctrine: '規則の朗読', charity: '慈善活動', calendar: '典礼暦',
  hymns: '聖歌集', maps: '巡礼地図', biographies: '聖人伝', sermons: '説教集'
} as const

const VALID_PAIRS = [
  ['intake', 'minutes'], ['review', 'access'], ['custody', 'inventory'], ['notice', 'letter'],
  ['appeal', 'witness'], ['correction', 'signature'], ['archive', 'seal']
] as const
const HIT_CHAPTERS = VALID_PAIRS.map(([chapter]) => chapter)
const MISS_CHAPTERS = ['history', 'doctrine', 'charity', 'calendar', 'hymns', 'maps', 'biographies', 'sermons'] as const
const HIT_EVIDENCE = VALID_PAIRS.map(([, evidence]) => evidence)
const MISS_EVIDENCE = ['minutes', 'access', 'letter', 'inventory', 'witness', 'seal', 'signature'] as const

export interface Stage3Offer {
  readonly chapters: readonly string[]
  readonly evidence: readonly string[]
  readonly target_chapter: string
  readonly target_evidence: string
}
export interface Stage3Round {
  readonly offer: Stage3Offer
  readonly selected_chapter: string
  readonly selected_evidence: string
  readonly hit: boolean
  readonly delta: number
  readonly gauge_after: number
}
export interface Stage3MinigameLedger {
  readonly gauge: number
  readonly hits: number
  readonly rounds: readonly Stage3Round[]
  readonly offer?: Stage3Offer
  readonly outcome?: 'win' | 'lose'
}

function sample<T>(pool: readonly T[], rolls: readonly number[]): T[] {
  const result = [...pool]
  const picked: T[] = []
  for (const roll of rolls) picked.push(result.splice(Math.floor(roll * result.length), 1)[0]!)
  return picked
}

function checkRolls(rolls: readonly number[]): void {
  if (rolls.length !== 9 || rolls.some((roll) => !Number.isFinite(roll) || roll < 0 || roll >= 1)) {
    throw new RangeError('Stage 3 requires nine random rolls in [0, 1)')
  }
}

export function rollStage3Offer(rolls: readonly number[], previous: readonly Stage3Round[] = []): Stage3Offer {
  checkRolls(rolls)
  const used = new Set(previous.map((round) => `${round.offer.target_chapter}:${round.offer.target_evidence}`))
  const remaining = VALID_PAIRS.filter(([chapter, evidence]) => !used.has(`${chapter}:${evidence}`))
  if (!remaining.length) throw new Error('No unused Stage 3 evidence pairs remain')
  const pair = remaining[Math.floor(rolls[0]! * remaining.length)]!
  const chapters: string[] = sample(MISS_CHAPTERS, rolls.slice(1, 4))
  chapters.splice(Math.floor(rolls[4]! * 4), 0, pair[0])
  const evidence: string[] = sample(MISS_EVIDENCE.filter((id) => id !== pair[1]), rolls.slice(5, 8))
  evidence.splice(Math.floor(rolls[8]! * 4), 0, pair[1])
  return {
    chapters,
    evidence,
    target_chapter: pair[0], target_evidence: pair[1]
  }
}

function validOffer(offer: Stage3Offer, previous: readonly Stage3Round[]): boolean {
  const pairExists = VALID_PAIRS.some(([chapter, evidence]) => chapter === offer.target_chapter && evidence === offer.target_evidence)
  return pairExists && !previous.some((round) => round.offer.target_chapter === offer.target_chapter &&
    round.offer.target_evidence === offer.target_evidence) && offer.chapters.length === 4 && offer.evidence.length === 4 &&
    offer.chapters.includes(offer.target_chapter) && offer.evidence.includes(offer.target_evidence) &&
    new Set(offer.chapters).size === 4 && new Set(offer.evidence).size === 4 &&
    offer.chapters.filter((id) => id !== offer.target_chapter).every((id) => (MISS_CHAPTERS as readonly string[]).includes(id)) &&
    offer.evidence.filter((id) => id !== offer.target_evidence).every((id) => (MISS_EVIDENCE as readonly string[]).includes(id))
}

export function askPisukeForStage3Minigame(save: SaveData, rolls: readonly number[]): SaveData {
  const offer = save.progress.stage3_minigame?.offer
  if (!offer) throw new Error('Stage 3 minigame has no active evidence')
  return chooseStage3Evidence(save, offer.target_chapter, offer.target_evidence, rolls)
}

export function validateStage3Minigame(ledger: Stage3MinigameLedger): void {
  if (!Number.isSafeInteger(ledger.gauge) || ledger.gauge < 0 || ledger.gauge > STAGE3_GAUGE_LIMIT ||
      !Number.isSafeInteger(ledger.hits) || ledger.hits < 0 || ledger.hits > 3 || !Array.isArray(ledger.rounds) || ledger.rounds.length > 100) {
    throw new Error('Invalid Stage 3 minigame state')
  }
  let gauge = GAUGE_START
  let hits = 0
  const previous: Stage3Round[] = []
  for (const round of ledger.rounds) {
    if (!validOffer(round.offer, previous) || !round.offer.chapters.includes(round.selected_chapter) ||
        !round.offer.evidence.includes(round.selected_evidence)) throw new Error('Invalid Stage 3 selection')
    const isHit = round.selected_chapter === round.offer.target_chapter && round.selected_evidence === round.offer.target_evidence
    if (round.hit !== isHit || round.delta !== (isHit ? HIT_DELTA : MISS_DELTA)) throw new Error('Invalid Stage 3 result')
    gauge = Math.max(0, Math.min(STAGE3_GAUGE_LIMIT, gauge + round.delta))
    if (round.gauge_after !== gauge) throw new Error('Stage 3 gauge does not match history')
    if (isHit) hits++
    previous.push(round)
  }
  if (gauge !== ledger.gauge || hits !== ledger.hits) throw new Error('Stage 3 state does not match history')
  const outcome = gauge === 0 ? 'win' : gauge === STAGE3_GAUGE_LIMIT ? 'lose' : undefined
  if (ledger.outcome !== outcome || (outcome ? ledger.offer !== undefined : !ledger.offer || !validOffer(ledger.offer, previous))) {
    throw new Error('Stage 3 checkpoint does not match its result')
  }
}

export function beginStage3Minigame(save: SaveData, rolls: readonly number[]): SaveData {
  if (save.progress.checkpoint_id !== 'stage3.minigame.ready' || !save.progress.flags.includes('stage3.started') ||
      save.progress.stage3_minigame?.outcome === undefined && save.progress.stage3_minigame) {
    throw new Error('Stage 3 minigame is not ready')
  }
  const ledger: Stage3MinigameLedger = { gauge: GAUGE_START, hits: 0, rounds: [], offer: rollStage3Offer(rolls) }
  validateStage3Minigame(ledger)
  return { ...save, progress: { ...save.progress, checkpoint_id: STAGE3_MINIGAME_CHECKPOINT, stage3_minigame: ledger } }
}

export function chooseStage3Evidence(save: SaveData, chapter: string, evidence: string, rolls: readonly number[]): SaveData {
  const ledger = save.progress.stage3_minigame
  if (save.progress.checkpoint_id !== STAGE3_MINIGAME_CHECKPOINT || !ledger?.offer || ledger.outcome) throw new Error('Stage 3 is not accepting an answer')
  validateStage3Minigame(ledger)
  checkRolls(rolls)
  if (!ledger.offer.chapters.includes(chapter) || !ledger.offer.evidence.includes(evidence)) throw new Error('Unlisted evidence selection')
  const hit = chapter === ledger.offer.target_chapter && evidence === ledger.offer.target_evidence
  const delta = hit ? HIT_DELTA : MISS_DELTA
  const gauge = Math.max(0, Math.min(STAGE3_GAUGE_LIMIT, ledger.gauge + delta))
  const hits = ledger.hits + Number(hit)
  const outcome = gauge === 0 ? 'win' : gauge === STAGE3_GAUGE_LIMIT ? 'lose' : undefined
  const round: Stage3Round = { offer: ledger.offer, selected_chapter: chapter, selected_evidence: evidence, hit, delta, gauge_after: gauge }
  const next: Stage3MinigameLedger = { gauge, hits, rounds: [...ledger.rounds, round],
    ...(outcome ? { outcome } : { offer: rollStage3Offer(rolls, [...ledger.rounds, round]) }) }
  validateStage3Minigame(next)
  return { ...save, progress: { ...save.progress, checkpoint_id: outcome ? STAGE3_MINIGAME_END_CHECKPOINT : STAGE3_MINIGAME_CHECKPOINT,
    stage3_minigame: next } }
}

export function parseStage3Minigame(value: unknown): Stage3MinigameLedger {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) throw new TypeError('Invalid Stage 3 ledger')
  const raw = value as Record<string, unknown>
  const allowed = ['gauge', 'hits', 'rounds', 'offer', 'outcome']
  if (Reflect.ownKeys(raw).some((key) => typeof key !== 'string' || !allowed.includes(key)) || !Array.isArray(raw.rounds)) throw new TypeError('Invalid Stage 3 ledger')
  const offer = (entry: unknown): Stage3Offer => {
    if (entry === null || typeof entry !== 'object' || Array.isArray(entry)) throw new TypeError('Invalid Stage 3 offer')
    const item = entry as Record<string, unknown>
    if (Reflect.ownKeys(item).some((key) => typeof key !== 'string' || !['chapters', 'evidence', 'target_chapter', 'target_evidence'].includes(key)) ||
        !Array.isArray(item.chapters) || !Array.isArray(item.evidence)) throw new TypeError('Invalid Stage 3 offer')
    return { chapters: item.chapters as string[], evidence: item.evidence as string[], target_chapter: item.target_chapter as string,
      target_evidence: item.target_evidence as string }
  }
  const rounds = raw.rounds.map((entry) => {
    if (entry === null || typeof entry !== 'object' || Array.isArray(entry)) throw new TypeError('Invalid Stage 3 round')
    const item = entry as Record<string, unknown>
    return { offer: offer(item.offer), selected_chapter: item.selected_chapter as string, selected_evidence: item.selected_evidence as string,
      hit: item.hit as boolean, delta: item.delta as number, gauge_after: item.gauge_after as number }
  })
  const parsed: Stage3MinigameLedger = { gauge: raw.gauge as number, hits: raw.hits as number, rounds,
    ...(raw.offer !== undefined ? { offer: offer(raw.offer) } : {}),
    ...(raw.outcome !== undefined ? { outcome: raw.outcome as 'win' | 'lose' } : {}) }
  if (parsed.outcome !== undefined && parsed.outcome !== 'win' && parsed.outcome !== 'lose') throw new TypeError('Invalid Stage 3 outcome')
  validateStage3Minigame(parsed)
  return parsed
}

export function validateStage3MinigameState(save: SaveData): void {
  const ledger = save.progress.stage3_minigame
  const active = save.progress.checkpoint_id === STAGE3_MINIGAME_CHECKPOINT
  const ended = save.progress.checkpoint_id === STAGE3_MINIGAME_END_CHECKPOINT
  const rematch = ['stage3.rematch.background', 'stage3.rematch.hero', 'stage3.rematch.magdalena', 'stage3.rematch.start',
    'stage3.rematch.battle', 'stage3.rematch.result', 'stage3.rematch.end', 'stage3.post.background', 'stage3.post.magdalena',
    'stage3.post.outcome', 'stage3.post.hero', 'stage3.post.reception', 'stage3.post.end'].includes(save.progress.checkpoint_id)
  if (!ledger) { if (active || ended || rematch) throw new Error('Missing Stage 3 minigame ledger'); return }
  validateStage3Minigame(ledger)
  if (active && ledger.outcome || ended && !ledger.outcome || rematch && !ledger.outcome) throw new Error('Stage 3 ledger checkpoint mismatch')
}
