import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { OriginalBattleBackground } from './OriginalBattleBackground'
import { OriginalBattleDialogue } from './OriginalBattleDialogue'
import { OriginalBattleMenus } from './OriginalBattleMenus'
import { OriginalBattleBubble } from './OriginalBattleBubble'
import { originalBattleTypingText } from '../../../packages/story/original-bubble'
import type { SaveData } from '../../../packages/domain/save'
import { chooseOriginalNormalCard, continueOriginalNormal, prepareOriginalNormal, stepOriginalNormal, originalNormalPreResultBattle, originalNormalSurface, type OriginalNormal } from '../../../packages/story/original-normal'
import { beginOriginalMatildaAftermath } from '../../../packages/story/original-matilda-aftermath-save'
import { originalAutoDeckIndices } from '../../../packages/battle/original-janken'
import { fitViewport } from '../../../packages/story/viewport'
import { OriginalPortrait } from './OriginalStoryScreen'
import { originalAsset } from './original-assets'
import { CardView } from './CardView'
import { OriginalShowdown } from './OriginalShowdown'

export function OriginalNormalScreen({ save, onSave, onExit }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onExit: () => void
}) {
  const state = save.progress.original_normal!
  const presentationBattle = useMemo(() => state.phase === 'result' ? originalNormalPreResultBattle(state) : state.battle, [state])
  const container = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [selected, setSelected] = useState<number | null>(null)
  const [draft, setDraft] = useState<number[]>([])
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [visibleChars, setVisibleChars] = useState(0)
  const [bubbleReady, setBubbleReady] = useState(false)
  const typingText = originalBattleTypingText(state.text, state.bubbleSide)
  const surface = useMemo(() => originalNormalSurface(state), [state.actions])
  useLayoutEffect(() => {
    const element = container.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize(); const observer = new ResizeObserver(resize); observer.observe(element)
    return () => observer.disconnect()
  }, [])
  useLayoutEffect(() => { setBubbleReady(false) }, [state.text, state.phase])
  useEffect(() => {
    setVisibleChars(0)
    if (state.phase !== 'dialogue' || state.bubbleSide && !bubbleReady) return
    const timer = setInterval(() => setVisibleChars(n => Math.min(n + 1, typingText.length)), state.bubbleSide ? 60 : 30)
    return () => clearInterval(timer)
  }, [state.text, state.phase, bubbleReady])
  async function write(next: SaveData) {
    if (pending.current) return
    pending.current = true; setBusy(true)
    try { await onSave(next) }
    catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { pending.current = false; setBusy(false) }
  }
  function persist(next: OriginalNormal) { return write({ ...save, progress: { ...save.progress, original_normal: next } }) }
  useEffect(() => {
    if (state.phase === 'running' && !busy && !error) void persist(stepOriginalNormal(state, Math.random()))
  }, [state, busy, error])
  function advance() {
    if (busy || error || state.phase !== 'dialogue') return
    if (state.phase === 'dialogue' && visibleChars < typingText.length) setVisibleChars(typingText.length)
    else void persist(continueOriginalNormal(state))
  }
  function portrait(path: string, options: Record<string, unknown>) {
    const position = options.position as number[] | undefined
    return { portrait_id: path, portrait_scale: Number(options.scale || 1), side_override: String(options.side || 'center'),
      position_mode: 'offset', position: { type: 'Vector2', x: position?.[0] || 0, y: position?.[1] || 0 }, visible: true }
  }
  const round = state.battle.rounds.at(-1)
  return <main ref={container} className="story-viewport" tabIndex={0} onKeyDown={event => {
    if (event.target === event.currentTarget && ['Enter', 'Space'].includes(event.code)) { event.preventDefault(); advance() }
  }}>
    <div className="story-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        {surface.blurred ? <OriginalBattleBackground path={originalAsset(state.background)} />
          : <img className="story-background" alt="背景" src={originalAsset(state.background)} />}
        <OriginalPortrait id="matilda" value={portrait(state.portrait, state.portraitOptions)} />
        <OriginalPortrait id="deck" value={portrait(state.pedestal, state.pedestalOptions)} />
        {state.uiVisible && <>
          <section data-testid="original-opponent-hp" style={{ position: 'absolute', top: 8, left: '40%', fontSize: 24 }}>マチルダ HP: {presentationBattle.opponentHp}/3</section>
          <section data-testid="original-player-hp" style={{ position: 'absolute', bottom: 160, right: 40, fontSize: 24 }}>HP: {presentationBattle.playerHp}/3</section>
          <section style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 150, display: 'flex', justifyContent: 'center', gap: 6, background: '#211c28dd' }}>
            {(state.phase === 'deck' ? draft.map(index => save.player.inventory[index]) : state.battle.playerDeck).map((card, index) => <button key={index} aria-label={`デッキ ${index + 1} ${card.hand}`}
              aria-pressed={selected === index} disabled={busy || state.phase !== 'deck' && (state.phase !== 'selection' || presentationBattle.playerUsed[index])}
              style={{ width: 70, height: 100, alignSelf: 'center' }} onClick={() => state.phase === 'deck'
                ? setDraft(previous => previous.filter((_, i) => i !== index)) : setSelected(index)}><CardView card={card} /></button>)}
          </section>
        </>}
        {state.phase === 'deck' && <>
          <section aria-label="手持ちカード" style={{ position: 'absolute', right: 20, top: 70, width: 300, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {save.player.inventory.map((card, index) => <button key={index} aria-label={`手持ち ${index + 1} ${card.hand} ${card.grade}`}
              style={{ width: 70, height: 100 }} disabled={busy || draft.includes(index) || draft.length >= 9}
              onClick={() => setDraft(previous => [...previous, index])}><CardView card={card} /></button>)}
          </section>
          <aside className="original-suspension"><p>デッキに9枚セットしてください</p>
            <button disabled={busy} onClick={() => setDraft(originalAutoDeckIndices(save.player.inventory))}>自動</button>
            <button disabled={busy || draft.length !== 9} onClick={() => void persist(prepareOriginalNormal(state,
              draft.map(index => save.player.inventory[index])))}>準備完了</button>
          </aside>
        </>}
        <OriginalBattleMenus player={save.player} visible={surface.bandVisible} />
        {surface.bandVisible && surface.band && <OriginalBattleDialogue
          testId={state.phase === 'dialogue' && !state.bubbleSide ? 'original-normal-dialogue' : 'original-normal-band'}
          textTestId={state.phase === 'dialogue' && !state.bubbleSide ? 'original-normal-text' : undefined}
          waitForInput={state.phase === 'dialogue' && !state.bubbleSide} speaker="マチルダ"
          text={state.phase === 'dialogue' && !state.bubbleSide ? surface.band.text.slice(0, visibleChars) : surface.band.text} onAdvance={advance} />}
        {surface.bubble && <OriginalBattleBubble testId={state.phase === 'dialogue' && state.bubbleSide ? 'original-normal-dialogue' : 'original-normal-bubble'}
          textTestId={state.phase === 'dialogue' && state.bubbleSide ? 'original-normal-text' : undefined}
          text={surface.bubble.text} side={surface.bubble.side} fontSize={surface.bubble.fontSize} waitForInput={state.phase === 'dialogue' && !!state.bubbleSide}
          revision={surface.bubble.revision} onReady={() => setBubbleReady(true)}
          visibleCharacters={state.phase === 'dialogue' && state.bubbleSide ? visibleChars : originalBattleTypingText(surface.bubble.text, surface.bubble.side).length}
          onAdvance={advance} />}
        {state.phase === 'selection' && <aside className="original-suspension"><p>カードを選択してください</p>
          <button disabled={busy || selected === null} onClick={() => { if (selected !== null) {
            void persist(chooseOriginalNormalCard(state, selected)); setSelected(null)
          } }}>勝負！</button></aside>}
        {state.phase === 'result' && round && !error && <OriginalShowdown key={state.actions.length}
          player={round.player} opponent={round.opponent} result={round.result} onError={cause => setError(String(cause))}
          onComplete={() => void persist(continueOriginalNormal(state))} />}
        {state.phase === 'finished' && <aside role="status" className="original-suspension"><p>{state.outcome === 'win' ? '報酬を獲得しました！' : state.outcome === 'lose' ? '奪われました...' : '引き分け'}</p>
          <p>{state.gold} G</p><button disabled={busy} onClick={() => void write(beginOriginalMatildaAftermath(save))}>OK</button></aside>}
        <nav style={{ position: 'absolute', top: 12, right: 16 }}><span data-testid="original-normal-cursor">{state.playback.method}:{state.playback.cursor}:{state.phase}</span>
          <button disabled={busy} onClick={onExit}>タイトルに戻る</button></nav>
        {error && <aside role="alert" className="original-suspension">{error}</aside>}
      </div>
    </div>
  </main>
}
