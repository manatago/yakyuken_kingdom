import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { OriginalBattleBackground } from './OriginalBattleBackground'
import { OriginalBattleDialogue } from './OriginalBattleDialogue'
import { OriginalBattleMenus } from './OriginalBattleMenus'
import { originalMinigameUiVisible } from '../../../packages/story/original-minigame-lifecycle'
import { createOriginalCurseGame, playOriginalCurseChoice, originalCurseSource, type CurseCommand, type OriginalCurseLedger } from '../../../packages/story/original-curse-game'
import { finishOriginalCurseSave } from '../../../packages/story/original-curse-save'
import { fitViewport } from '../../../packages/story/viewport'
import { OriginalPortrait } from './OriginalStoryScreen'
import { originalAsset } from './original-assets'
import { restoreOriginalStoryState } from '../../../packages/story/original'

function presentation(ledger: OriginalCurseLedger) {
  let game = createOriginalCurseGame(ledger.game.initialRolls)
  const commands: CurseCommand[] = []
  for (const action of ledger.game.actions) {
    commands.push(...game.commands)
    game = playOriginalCurseChoice(game, action.selected, action.pisukeRoll, action.nextRolls)
  }
  commands.push(...game.commands.slice(0, ledger.cursor + 1))
  let gauge = originalCurseSource.gauge_start
  let portrait = ''; let options: Record<string, unknown> = {}
  for (const command of commands) {
    if (command.kind === 'gauge') gauge = Number(command.args[1])
    if (command.kind === 'set_portrait') { portrait = String(command.args[1]); options = command.args[2] as Record<string, unknown> }
  }
  return { gauge, portrait, options }
}

export function OriginalCurseScreen({ save, onSave, onExit }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onExit: () => void
}) {
  const ledger = save.progress.original_curse_game!
  const command = ledger.game.commands[ledger.cursor]
  const waiting = command?.kind === 'narrator_band'
  const text = waiting ? String(command.args[0]) : ''
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
  async function persist(next: OriginalCurseLedger) {
    if (pending.current) return
    pending.current = true; setBusy(true)
    try { await onSave({ ...save, progress: { ...save.progress, original_curse_game: next } }) }
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
    if (pending.current || busy) return
    pending.current = true; setBusy(true)
    try { await onSave(finishOriginalCurseSave(save)) }
    catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { pending.current = false; setBusy(false) }
  }
  const scene = presentation(ledger)
  const position = scene.options.position as number[] | undefined
  useEffect(() => {
    if (!command && ledger.game.outcome && !busy && !error) void finish()
  }, [ledger, busy, error])
  const minigameUiVisible = originalMinigameUiVisible(ledger.game, ledger.cursor, 1)
  const ready = !command && !ledger.game.outcome
  const [, sequence, cursor] = save.progress.checkpoint_id.split(':')
  const background = restoreOriginalStoryState(sequence, Number(cursor)).background
  return <main ref={viewport} className="story-viewport">
    <div className="story-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        <OriginalBattleBackground path={originalAsset(background)} />
        <OriginalPortrait id="fiona_armor" value={{ portrait_id: scene.portrait, portrait_scale: Number(scene.options.scale || .55),
          side_override: String(scene.options.side || 'center'), position_mode: 'offset',
          position: { type: 'Vector2', x: position?.[0] || 0, y: position?.[1] || 0 }, visible: true }} />
        {minigameUiVisible && <section data-testid="original-curse-gauge" style={{ position: 'absolute', left: 40, top: 40, width: 600, height: 60,
          background: '#171720', fontSize: 24 }}>
          <div style={{ position: 'absolute', inset: 0, width: `${scene.gauge / 130 * 100}%`,
            background: scene.gauge >= 100 ? '#d93333' : scene.gauge >= 50 ? '#e6c733' : '#4dc74d' }} />
          <span style={{ position: 'relative' }}>呪いの加護度 {scene.gauge} / 130</span>
        </section>}
        {ready && <section style={{ position: 'absolute', right: 40, top: 120, display: 'grid', gap: 8 }}>
          {[...ledger.game.choices, 'pisuke' as const].map((choice, index) => <button key={choice} disabled={busy || !!error}
            onClick={() => void persist({ game: playOriginalCurseChoice(ledger.game, choice, Math.random(), Array.from({ length: 8 }, () => Math.random())), cursor: 0 })}
            style={{ width: 420, minHeight: 72, fontSize: 24 }}>
            [{index + 1}] {choice === 'pisuke' ? 'ピー助に任せる' : originalCurseSource.choices[choice].label}
          </button>)}
        </section>}
        <OriginalBattleMenus player={save.player} visible={waiting} minigame />
        {waiting && <OriginalBattleDialogue mode="minigame" textTestId="original-curse-text"
          text={text.slice(0, visible)} onAdvance={advance} />}
        <nav style={{ position: 'absolute', right: 16, top: 16 }}>
          <span data-testid="original-curse-cursor">{ledger.game.actions.length}:{ledger.cursor}</span>
          <button disabled={busy} onClick={onExit}>タイトルに戻る</button>
        </nav>
        {error && <aside role="alert" className="original-suspension">{error}</aside>}
      </div>
    </div>
  </main>
}
