import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { OriginalBattleBackground } from './OriginalBattleBackground'
import { OriginalBattleDialogue } from './OriginalBattleDialogue'
import { OriginalBattleMenus } from './OriginalBattleMenus'
import type { SaveData } from '../../../packages/domain/save'
import { continueOriginalAdventurer, finishOriginalAdventurerSave, stepOriginalAdventurer, originalAdventurerPreResultBattle, type OriginalAdventurer } from '../../../packages/story/original-adventurer'
import { fitViewport } from '../../../packages/story/viewport'
import { OriginalPortrait } from './OriginalStoryScreen'
import { originalAsset } from './original-assets'
import { CardView } from './CardView'
import { OriginalShowdown } from './OriginalShowdown'

export function OriginalAdventurerScreen({ save, onSave, onExit }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onExit: () => void
}) {
  const state = save.progress.original_adventurer!
  const presentationBattle = useMemo(() => state.phase === 'result' ? originalAdventurerPreResultBattle(state) : state.battle, [state])
  const container = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [visibleChars, setVisibleChars] = useState(0)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  useLayoutEffect(() => {
    const element = container.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize(); const observer = new ResizeObserver(resize); observer.observe(element)
    return () => observer.disconnect()
  }, [])
  useEffect(() => {
    setVisibleChars(0)
    if (state.phase !== 'dialogue') return
    const timer = setInterval(() => setVisibleChars(n => Math.min(n + 1, state.text.length)), 30)
    return () => clearInterval(timer)
  }, [state.text, state.phase])
  async function write(next: SaveData) {
    if (pending.current) return
    pending.current = true; setBusy(true)
    try { await onSave(next) }
    catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { pending.current = false; setBusy(false) }
  }
  function persist(next: OriginalAdventurer) { return write({ ...save, progress: { ...save.progress, original_adventurer: next } }) }
  useEffect(() => {
    if (state.phase === 'running' && !busy && !error) void persist(stepOriginalAdventurer(state, Math.random()))
  }, [state, busy, error])
  function advance() {
    if (busy || error || state.phase !== 'dialogue') return
    if (state.phase === 'dialogue' && visibleChars < state.text.length) setVisibleChars(state.text.length)
    else void persist(continueOriginalAdventurer(state))
  }
  const options = state.portraitOptions
  const position = options.position as number[] | undefined
  const round = state.battle.rounds.at(-1)
  return <main ref={container} className="story-viewport" tabIndex={0} onKeyDown={event => {
    if (event.target === event.currentTarget && ['Enter', 'Space'].includes(event.code)) { event.preventDefault(); advance() }
  }}>
    <div className="story-frame" style={{ width: fit.width, height: fit.height }}><div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
      <OriginalBattleBackground path={originalAsset('res://assets/backgrounds/stage1/bg07_st1_001.png')} />
      <OriginalPortrait id="adventurer_a" value={{ portrait_id: state.portrait, portrait_scale: Number(options.scale || 1), side_override: String(options.side || 'center'),
        position_mode: 'offset', position: { type: 'Vector2', x: position?.[0] || 0, y: position?.[1] || 0 }, visible: true }} />
      <section style={{ position: 'absolute', top: 8, left: '40%', fontSize: 24 }}>冒険者A HP: {presentationBattle.opponentHp}/1</section>
      {state.bayesVisible && <section data-testid="original-bayes-eye" style={{ position: 'absolute', top: 100, left: 16, padding: 20, background: '#14141fcc', fontSize: 24 }}>
        ベイズ・アイ<br />グー 90%　チョキ 0%　パー 10%
      </section>}
      {state.text && <OriginalBattleDialogue testId={state.phase === 'dialogue' ? 'original-adventurer-dialogue' : 'original-adventurer-band'}
        waitForInput={state.phase === 'dialogue'} text={state.phase === 'dialogue' ? state.text.slice(0, visibleChars) : state.text} onAdvance={advance} />}
      <OriginalBattleMenus player={save.player} visible={!!state.text} />
      <section style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 150, display: 'flex', justifyContent: 'center', gap: 6 }}>
        {state.battle.playerDeck.map((card, index) => <div key={index} style={{ width: 70, height: 100, alignSelf: 'center', opacity: presentationBattle.playerUsed[index] ? .4 : 1 }}><CardView card={card} /></div>)}
      </section>
      {state.phase === 'result' && round && !error && <OriginalShowdown key={state.actions.length}
        player={round.player} opponent={round.opponent} result={round.result} onError={cause => setError(String(cause))}
        onComplete={() => void persist(continueOriginalAdventurer(state))} />}
      {state.phase === 'reward' && <aside role="status" className="original-suspension"><p>報酬を獲得しました！</p><p>グー N ×1</p><p>{state.gold} G</p>
        <button disabled={busy} onClick={() => void write(finishOriginalAdventurerSave(save))}>OK</button></aside>}
      <nav style={{ position: 'absolute', right: 16, top: 12 }}><span data-testid="original-adventurer-cursor">{state.cursor}:{state.phase}</span>
        <button disabled={busy} onClick={onExit}>タイトルに戻る</button></nav>
      {error && <aside role="alert" className="original-suspension">{error}</aside>}
    </div></div>
  </main>
}
