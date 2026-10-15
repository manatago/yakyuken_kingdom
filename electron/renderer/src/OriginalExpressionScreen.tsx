import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { OriginalBattleBackground } from './OriginalBattleBackground'
import { OriginalBattleDialogue } from './OriginalBattleDialogue'
import { OriginalBattleMenus } from './OriginalBattleMenus'
import { originalMinigameUiVisible } from '../../../packages/story/original-minigame-lifecycle'
import { createOriginalExpressionGame, chooseOriginalExpression, originalExpressionSource as source,
  type OriginalExpressionLedger } from '../../../packages/story/original-expression-game'
import { finishOriginalExpressionSave } from '../../../packages/story/original-expression-save'
import { fitViewport } from '../../../packages/story/viewport'
import { restoreOriginalStoryState } from '../../../packages/story/original'
import { OriginalPortrait } from './OriginalStoryScreen'
import { originalAsset } from './original-assets'

function presentation(ledger: OriginalExpressionLedger) {
  let game = createOriginalExpressionGame(ledger.game.initialRoll)
  const commands = []
  for (const action of ledger.game.actions) {
    commands.push(...game.commands)
    game = chooseOriginalExpression(game, action.pick, action.nextRoll)
  }
  commands.push(...game.commands.slice(0, ledger.cursor + 1))
  let gauge = source.gauge_start
  for (const command of commands) if (command.kind === 'gauge') gauge = Number(command.args[1])
  return gauge
}

export function OriginalExpressionScreen({ save, onSave, onExit }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onExit: () => void
}) {
  const ledger = save.progress.original_expression_game!
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
  async function persist(next: OriginalExpressionLedger) {
    if (pending.current) return
    pending.current = true; setBusy(true)
    try { await onSave({ ...save, progress: { ...save.progress, original_expression_game: next } }) }
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
    try { await onSave(finishOriginalExpressionSave(save)) }
    catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { pending.current = false; setBusy(false) }
  }
  useEffect(() => {
    if (!command && ledger.game.outcome && !busy && !error) void finish()
  }, [ledger, busy, error])
  const minigameUiVisible = originalMinigameUiVisible(ledger.game, ledger.cursor, 4)
  const ready = !command && !ledger.game.outcome
  const scene = source.scenes[ledger.game.scene]
  const expression = source.expressions[scene.expression as keyof typeof source.expressions]
  const setup = source.intro.find(command => command.kind === 'set_portrait')!
  const options = setup.args[2] as { scale: number; side: string; position: number[] }
  const [, sequence, cursor] = save.progress.checkpoint_id.split(':')
  const gauge = presentation(ledger)
  const unlocked = ledger.game.actions.length >= source.pisuke_unlock_turn
  return <main ref={viewport} className="story-viewport">
    <div className="story-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        <OriginalBattleBackground path={originalAsset(restoreOriginalStoryState(sequence, Number(cursor)).background)} />
        <OriginalPortrait id="layla" value={{ portrait_id: String(setup.args[1]), portrait_scale: options.scale,
          side_override: options.side, position_mode: 'offset',
          position: { type: 'Vector2', x: options.position[0], y: options.position[1] }, visible: true }} />
        {minigameUiVisible && <section data-testid="original-expression-gauge" style={{ position: 'absolute', left: 40, top: 40, width: 600, height: 60,
          border: '2px solid #8c8c9e', borderRadius: 10, background: '#0f0f17f2', fontSize: 22 }}>
          <div style={{ position: 'absolute', left: 5, top: 5, height: 50, width: 590 * gauge / source.gauge_max,
            background: gauge >= 100 ? '#d93333' : gauge >= 50 ? '#e6c733' : '#4dc74d' }} />
          <span style={{ position: 'relative', display: 'block', textAlign: 'center', lineHeight: '60px' }}>レイラの冷静度  {gauge} / {source.gauge_max}</span>
        </section>}
        {ready && <>
          <div data-testid="original-expression-badge" style={{ position: 'absolute', left: 1500, top: 110, width: 280, height: 60,
            background: '#1a141fe6', borderRadius: 6, fontSize: 32, textAlign: 'center', lineHeight: '60px',
            color: `rgb(${expression.color.slice(0, 3).map(value => Math.round(value * 255)).join(',')})` }}>【{expression.badge}】</div>
          <div data-testid="original-expression-reaction" style={{ position: 'absolute', left: 980, top: 190, width: 900, minHeight: 200,
            padding: '8px 16px', boxSizing: 'border-box', background: '#1a141fe6', border: '1px solid #cc4d80', borderRadius: 6,
            fontSize: 22, display: 'flex', alignItems: 'center' }}>{scene.reaction}</div>
          <section style={{ position: 'absolute', left: 40, top: 120, display: 'grid', gap: 8 }}>
            {[...source.choice_keys, '_pisuke'].map((choice, index) => <button key={choice}
              disabled={busy || !!error || (choice === '_pisuke' && !unlocked)}
              style={{ width: 420, minHeight: 48, fontSize: 22, textAlign: 'left' }}
              onClick={() => void persist({ game: chooseOriginalExpression(ledger.game, choice, Math.random()), cursor: 0 })}>
              [{index + 1}] {choice === '_pisuke' ? `ピー助に任せる${unlocked ? '' : '（残り 1 ターン）'}` : source.expressions[choice as keyof typeof source.expressions].choice}
            </button>)}
          </section>
        </>}
        <OriginalBattleMenus player={save.player} visible={waiting} minigame />
        {waiting && <OriginalBattleDialogue mode="minigame" textTestId="original-expression-text"
          text={text.slice(0, visible)} onAdvance={advance} />}
        <nav style={{ position: 'absolute', right: 16, top: 16 }}>
          <span data-testid="original-expression-cursor">{ledger.game.actions.length}:{ledger.cursor}</span>
          <button disabled={busy} onClick={onExit}>タイトルに戻る</button>
        </nav>
        {error && <aside role="alert" className="original-suspension">{error}</aside>}
      </div>
    </div>
  </main>
}
