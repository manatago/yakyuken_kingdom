import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { OriginalBattleBackground } from './OriginalBattleBackground'
import { OriginalBattleDialogue } from './OriginalBattleDialogue'
import { OriginalBattleMenus } from './OriginalBattleMenus'
import { originalMinigameUiVisible } from '../../../packages/story/original-minigame-lifecycle'
import { createOriginalEvidenceGame, chooseOriginalEvidence, originalEvidenceSource as source,
  type OriginalEvidenceLedger } from '../../../packages/story/original-evidence-game'
import { finishOriginalEvidenceSave } from '../../../packages/story/original-evidence-save'
import { fitViewport } from '../../../packages/story/viewport'
import { restoreOriginalStoryState } from '../../../packages/story/original'
import { OriginalPortrait } from './OriginalStoryScreen'
import { originalAsset } from './original-assets'

function presentation(ledger: OriginalEvidenceLedger) {
  let game = createOriginalEvidenceGame(ledger.game.initialRolls)
  const commands = []
  for (const action of ledger.game.actions) {
    commands.push(...game.commands)
    game = chooseOriginalEvidence(game, action.pick, action.supportRoll, action.nextRolls)
  }
  commands.push(...game.commands.slice(0, ledger.cursor + 1))
  let gauge = source.gauge_start
  for (const command of commands) if (command.kind === 'gauge') gauge = Number(command.args[1])
  return gauge
}

export function OriginalEvidenceScreen({ save, onSave, onExit }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onExit: () => void
}) {
  const ledger = save.progress.original_evidence_game!
  const command = ledger.game.commands[ledger.cursor]
  const waiting = command?.kind === 'narrator_band' || command?.kind === 'dialogue_band'
  const text = waiting ? String(command.args[command.kind === 'narrator_band' ? 0 : 1]) : ''
  const viewport = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [book, setBook] = useState('')
  const [proof, setProof] = useState('')
  const [visible, setVisible] = useState(0)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  useLayoutEffect(() => {
    const element = viewport.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize(); const observer = new ResizeObserver(resize); observer.observe(element)
    return () => observer.disconnect()
  }, [])
  useEffect(() => {
    setVisible(0)
    if (!text) return
    const timer = setInterval(() => setVisible(value => Math.min(value + 1, text.length)), 30)
    return () => clearInterval(timer)
  }, [text, ledger.cursor, ledger.game.actions.length])
  async function persist(next: OriginalEvidenceLedger) {
    if (pending.current) return
    pending.current = true; setBusy(true)
    try { await onSave({ ...save, progress: { ...save.progress, original_evidence_game: next } }) }
    catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { pending.current = false; setBusy(false) }
  }
  useEffect(() => {
    if (!command || waiting || busy || error) return
    const timer = setTimeout(() => void persist({ ...ledger, cursor: ledger.cursor + 1 }),
      command.kind === 'wait' ? Number(command.args[0]) * 1000 : 0)
    return () => clearTimeout(timer)
  }, [ledger, busy, error])
  function advance() {
    if (!waiting || busy || error) return
    if (visible < text.length) setVisible(text.length)
    else void persist({ ...ledger, cursor: ledger.cursor + 1 })
  }
  async function finish() {
    if (pending.current) return
    pending.current = true; setBusy(true)
    try { await onSave(finishOriginalEvidenceSave(save)) }
    catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { pending.current = false; setBusy(false) }
  }
  useEffect(() => {
    if (!command && ledger.game.outcome && !busy && !error) void finish()
  }, [ledger, busy, error])
  const minigameUiVisible = originalMinigameUiVisible(ledger.game, ledger.cursor, 4)
  const ready = !command && !ledger.game.outcome
  const setup = source.intro.find(command => command.kind === 'set_portrait')!
  const options = setup.args[2] as { scale: number; side: string; position: number[] }
  const [, sequence, cursor] = save.progress.checkpoint_id.split(':')
  const gauge = useMemo(() => presentation(ledger), [ledger])
  const unlocked = ledger.game.actions.length >= 1
  return <main ref={viewport} className="story-viewport">
    <div className="story-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        <OriginalBattleBackground path={originalAsset(restoreOriginalStoryState(sequence, Number(cursor)).background)} />
        <OriginalPortrait id="magdalena" value={{ portrait_id: String(setup.args[1]), portrait_scale: options.scale,
          side_override: options.side, position_mode: 'offset',
          position: { type: 'Vector2', x: options.position[0], y: options.position[1] }, visible: true }} />
        {minigameUiVisible && <section data-testid="original-evidence-gauge" style={{ position: 'absolute', left: 40, top: 40, width: 600, height: 60,
          border: '2px solid #8c8c9e', borderRadius: 10, background: '#0f0f17f2', fontSize: 22 }}>
          <div style={{ position: 'absolute', left: 5, top: 5, height: 50, width: 590 * gauge / source.gauge_max,
            background: gauge >= 100 ? '#d93333' : gauge >= 40 ? '#e6c733' : '#4dc74d' }} />
          <span style={{ position: 'relative', display: 'block', textAlign: 'center', lineHeight: '60px' }}>信仰の威厳  {gauge} / {source.gauge_max}</span>
        </section>}
        {ready && <>
          <h3 style={{ position: 'absolute', left: 40, top: 120, margin: 0 }}>本のジャンル</h3>
          <h3 style={{ position: 'absolute', left: 490, top: 120, margin: 0 }}>物証</h3>
          <section style={{ position: 'absolute', left: 40, top: 170, display: 'grid', gap: 6 }}>
            {ledger.game.chapters.map((key, index) => {
              const entry = source.chapters[key as keyof typeof source.chapters]
              return <button key={key} data-testid={`original-evidence-book-${key}`} aria-pressed={book === key}
                disabled={busy || !!error} onClick={() => setBook(key)}
                style={{ width: 440, minHeight: 88, fontSize: 20, padding: '6px 8px 6px 16px', textAlign: 'left', whiteSpace: 'pre-wrap' }}>
                {book === key ? '▶ 選択中  ' : `[${index + 1}] `}{entry.label}{'\n   「'}{entry.excerpt}{'」'}
              </button>
            })}
          </section>
          <section style={{ position: 'absolute', left: 490, top: 170, display: 'grid', gap: 6 }}>
            {ledger.game.evidences.map((key, index) => {
              const entry = source.evidences[key as keyof typeof source.evidences]
              return <button key={key} data-testid={`original-evidence-proof-${key}`} aria-pressed={proof === key}
                disabled={busy || !!error} onClick={() => setProof(key)}
                style={{ width: 440, minHeight: 88, fontSize: 20, padding: '6px 8px 6px 16px', textAlign: 'left', whiteSpace: 'pre-wrap' }}>
                {proof === key ? '▶ 選択中  ' : `[${index + 5}] `}{entry.label}{'\n   '}{entry.description}
              </button>
            })}
          </section>
          <section style={{ position: 'absolute', left: 40, top: 570, display: 'flex', gap: 16 }}>
            <button disabled={busy || !!error || !ledger.game.chapters.includes(book) || !ledger.game.evidences.includes(proof)}
              style={{ width: 440, minHeight: 56, fontSize: 22 }}
              onClick={() => {
                const game = chooseOriginalEvidence(ledger.game, { chapter: book, evidence: proof }, Math.random(), Array.from({ length: 13 }, () => Math.random()))
                setBook(''); setProof(''); void persist({ game, cursor: 0 })
              }}>[決定] この組み合わせで攻撃</button>
            <button disabled={busy || !!error || !unlocked} style={{ width: 440, minHeight: 56, fontSize: 22 }}
              onClick={() => {
                const game = chooseOriginalEvidence(ledger.game, '_pisuke', Math.random(), Array.from({ length: 13 }, () => Math.random()))
                setBook(''); setProof(''); void persist({ game, cursor: 0 })
              }}>{unlocked ? '[ピー助に任せる]' : '[ピー助に任せる]（残り 1 ターン）'}</button>
          </section>
        </>}
        <OriginalBattleMenus player={save.player} visible={waiting} minigame />
        {waiting && <OriginalBattleDialogue mode="minigame" textTestId="original-evidence-text"
          text={text.slice(0, visible)} onAdvance={advance} />}
        <nav style={{ position: 'absolute', right: 16, top: 16 }}>
          <span data-testid="original-evidence-cursor">{ledger.game.actions.length}:{ledger.cursor}</span>
          <button disabled={busy} onClick={onExit}>タイトルに戻る</button>
        </nav>
        {error && <aside role="alert" className="original-suspension">{error}</aside>}
      </div>
    </div>
  </main>
}
