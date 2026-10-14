import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { OriginalBattleBackground } from './OriginalBattleBackground'
import { OriginalBattleDialogue } from './OriginalBattleDialogue'
import { OriginalBattleMenus } from './OriginalBattleMenus'
import { originalMinigameUiVisible } from '../../../packages/story/original-minigame-lifecycle'
import { createOriginalQuestionGame, chooseOriginalQuestion, originalQuestionSource as source,
  type OriginalQuestionLedger } from '../../../packages/story/original-question-game'
import { finishOriginalQuestionSave } from '../../../packages/story/original-question-save'
import { fitViewport } from '../../../packages/story/viewport'
import { restoreOriginalStoryState } from '../../../packages/story/original'
import { OriginalPortrait } from './OriginalStoryScreen'
import { originalAsset } from './original-assets'

function presentation(ledger: OriginalQuestionLedger) {
  let game = createOriginalQuestionGame(ledger.game.initialRolls)
  const commands = []
  for (const action of ledger.game.actions) {
    commands.push(...game.commands)
    game = chooseOriginalQuestion(game, action.pick, action.nextRolls)
  }
  commands.push(...game.commands.slice(0, ledger.cursor + 1))
  let gauge = source.config.gauge_start
  for (const command of commands) if (command.kind === 'gauge') gauge = Number(command.args[1])
  return gauge
}

export function OriginalQuestionScreen({ save, onSave, onExit }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onExit: () => void
}) {
  const ledger = save.progress.original_question_game!
  const command = ledger.game.commands[ledger.cursor]
  const waiting = command?.kind === 'narrator_band' || command?.kind === 'dialogue_band'
  const text = waiting ? String(command.args[command.kind === 'narrator_band' ? 0 : 1]) : ''
  const viewport = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
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
  async function persist(next: OriginalQuestionLedger) {
    if (pending.current) return
    pending.current = true; setBusy(true)
    try { await onSave({ ...save, progress: { ...save.progress, original_question_game: next } }) }
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
    try { await onSave(finishOriginalQuestionSave(save)) }
    catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { pending.current = false; setBusy(false) }
  }
  const question = source.questions.find(question => question.pool === ledger.game.pool && question.index === ledger.game.question)!
  useEffect(() => {
    if (!command && ledger.game.outcome && !busy && !error) void finish()
  }, [ledger, busy, error])
  const minigameUiVisible = originalMinigameUiVisible(ledger.game, ledger.cursor, ledger.game.outcome ? source[ledger.game.outcome].length : 0)
  const ready = !command && !ledger.game.outcome
  const setup = source.intro.find(command => command.kind === 'set_portrait')!
  const options = setup.args[2] as { scale: number; side: string; position: number[] }
  const [, sequence, cursor] = save.progress.checkpoint_id.split(':')
  const gauge = useMemo(() => presentation(ledger), [ledger])
  return <main ref={viewport} className="story-viewport">
    <div className="story-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        <OriginalBattleBackground path={originalAsset(restoreOriginalStoryState(sequence, Number(cursor)).background)} />
        <OriginalPortrait id="feria" value={{ portrait_id: String(setup.args[1]), portrait_scale: options.scale,
          side_override: options.side, position_mode: 'offset',
          position: { type: 'Vector2', x: options.position[0], y: options.position[1] }, visible: true }} />
        {minigameUiVisible && <section data-testid="original-question-gauge" style={{ position: 'absolute', left: 40, top: 40, width: 600, height: 60,
          border: '2px solid #8c8c9e', borderRadius: 10, background: '#0f0f17f2', fontSize: 22 }}>
          <div style={{ position: 'absolute', left: 5, top: 5, height: 50, width: 590 * gauge / source.config.gauge_max,
            background: source.zones[gauge] === 'red' ? '#d93333' : source.zones[gauge] === 'yellow' ? '#e6c733' : '#4dc74d' }} />
          <span style={{ position: 'relative', display: 'block', textAlign: 'center', lineHeight: '60px' }}>{source.config.gauge_label}  {gauge} / {source.config.gauge_max}</span>
        </section>}
        {ready && <>
          <section style={{ position: 'absolute', left: 40, top: 120, display: 'grid', gap: 8 }}>
            {[...ledger.game.choices, 1].map((choice, index) => <button key={index}
              data-testid={choice === 1 ? 'original-question-support' : 'original-question-choice-' + index}
              disabled={busy || !!error} style={{ width: 420, minHeight: 48, fontSize: 22, textAlign: 'left' }}
              onClick={() => void persist({ game: chooseOriginalQuestion(ledger.game, choice, Array.from({ length: 7 }, () => Math.random())), cursor: 0 })}>
              [{index + 1}] {choice === 1 ? 'ピー助に任せる' : choice === 0 ? question.data.hit.label : question.data.misses[choice - 2].label}
            </button>)}
          </section>
        </>}
        <OriginalBattleMenus player={save.player} visible={waiting} minigame />
        {waiting && <OriginalBattleDialogue mode="minigame" textTestId="original-question-text"
          text={text.slice(0, visible)} onAdvance={advance} />}
        <nav style={{ position: 'absolute', right: 16, top: 16 }}>
          <span data-testid="original-question-cursor">{ledger.game.actions.length}:{ledger.cursor}</span>
          <button disabled={busy} onClick={onExit}>タイトルに戻る</button>
        </nav>
        {error && <aside role="alert" className="original-suspension">{error}</aside>}
      </div>
    </div>
  </main>
}
