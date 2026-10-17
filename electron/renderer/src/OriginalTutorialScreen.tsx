import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { ORIGINAL_MATILDA_TUTORIAL_COMPLETE } from '../../../packages/story/original-progress'
import { originalAutoDeckIndices } from '../../../packages/battle/original-janken'
import { chooseOriginalTutorialCard, continueOriginalTutorial, prepareOriginalTutorial,
  stepOriginalTutorial, originalTutorialPreResultBattle, type OriginalTutorial } from '../../../packages/story/original-tutorial'
import { fitViewport } from '../../../packages/story/viewport'
import { OriginalPortrait } from './OriginalStoryScreen'
import { originalAsset } from './original-assets'
import { CardView } from './CardView'
import layoutContent from '../../../content/stories/matilda-tutorial.json'
import { layoutStyle, originalCardLayout } from '../../../packages/content/layout'
import type { ContentPack } from '../../../packages/content/schema'
import { OriginalShowdown } from './OriginalShowdown'
import { OriginalBattleHighlight } from './OriginalBattleHighlight'
import { OriginalBattleBackground } from './OriginalBattleBackground'
import { OriginalBattleDialogue } from './OriginalBattleDialogue'
import { OriginalBattleMenus } from './OriginalBattleMenus'
import { originalTutorialHighlightOptions } from '../../../packages/story/original-highlight'

export function OriginalTutorialScreen({ save, onSave, onExit, layouts = layoutContent, editorPreview = false }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onExit: () => void; layouts?: Pick<ContentPack, 'layouts'>
  editorPreview?: boolean
}) {
  const state = save.progress.original_tutorial!
  const presentationBattle = useMemo(() => state.phase === 'result' ? originalTutorialPreResultBattle(state) : state.battle, [state])
  const ref = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [draft, setDraft] = useState<number[]>([])
  const [selected, setSelected] = useState<number | null>(null)
  const [visibleChars, setVisibleChars] = useState(0)
  const dialogue = state.phase === 'dialogue'
  useLayoutEffect(() => {
    const element = ref.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize()
    const observer = new ResizeObserver(resize); observer.observe(element)
    return () => observer.disconnect()
  }, [])
  useEffect(() => {
    setVisibleChars(0)
    if (!dialogue) return
    const timer = setInterval(() => setVisibleChars(n => Math.min(n + 1, state.text.length)), 30)
    return () => clearInterval(timer)
  }, [state.text, dialogue])

  async function persist(next: OriginalTutorial) {
    if (pending.current) return
    pending.current = true; setBusy(true)
    try { await onSave({ ...save, progress: { ...save.progress, original_tutorial: next } }) }
    catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { pending.current = false; setBusy(false) }
  }
  useEffect(() => {
    if (state.phase === 'running' && !busy && !error) void persist(stepOriginalTutorial(state, Math.random()))
  }, [state, busy, error])

  function advance() {
    if (busy || error || state.phase !== 'dialogue') return
    if (dialogue && visibleChars < state.text.length) setVisibleChars(state.text.length)
    else void persist(continueOriginalTutorial(state))
  }
  async function finish() {
    if (busy || pending.current || state.phase !== 'reward') return
    pending.current = true; setBusy(true)
    try {
      const { original_tutorial: _completed, ...progress } = save.progress
      await onSave({ ...save, player: { ...save.player, money: save.player.money + state.gold },
        progress: { ...progress, checkpoint_id: 'original:prologue:199',
          flags: [...new Set([...progress.flags, ORIGINAL_MATILDA_TUTORIAL_COMPLETE])] } })
    } catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { pending.current = false; setBusy(false) }
  }
  const options = state.portraitOptions
  const position = options.position as number[] | undefined
  const portrait = { portrait_id: state.portrait, portrait_scale: Number(options.scale || 1),
    side_override: String(options.side || 'center'), position_mode: 'offset',
    position: { type: 'Vector2', x: position?.[0] || 0, y: position?.[1] || 0 }, visible: true }
  const lastRound = state.battle.rounds.at(-1)
  const built = state.actions.some(action => action.type === 'deck')
  const inventoryGroups = ['paper', 'rock', 'scissors'].map(hand => ({ hand,
    indices: save.player.inventory.map((card, index) => ({ card, index })).filter(entry => entry.card.hand === hand).map(entry => entry.index) }))
  return <main ref={ref} className="story-viewport" tabIndex={0} onKeyDown={event => {
    if (event.target !== event.currentTarget) return
    if (['Enter', 'Space'].includes(event.code)) { event.preventDefault(); advance() }
  }}>
    <div className="story-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})`, fontFamily: "Arial, 'Hiragino Kaku Gothic ProN', sans-serif" }}>
        <OriginalBattleBackground path={originalAsset('res://assets/backgrounds/prologue/bg05_prison_cell.png')} />
        <OriginalPortrait id="matilda" value={portrait} layoutId="layout.matilda.explanation" layouts={layouts} />
        <OriginalPortrait id="deck" value={{ portrait_id: 'res://assets/battle/decks/pedestal_01_marble.png',
          portrait_scale: 0.55, side_override: 'center', position_mode: 'offset',
          position: { type: 'Vector2', x: 0, y: 180 }, visible: true }} />
        <section data-testid="original-opponent-hp" data-original-highlight-target="opponent_hp" style={{ position: 'absolute', left: '38%', right: '38%', top: 8,
          padding: 8, background: '#211c28', textAlign: 'center', fontSize: 22 }}>
          マチルダ HP: {presentationBattle.opponentHp}/3</section>
        <section data-original-highlight-target="item_panel" style={{ position: 'absolute', left: 8, top: 374, width: 295, height: 518,
          background: '#211c28dd', padding: 16, fontSize: 24 }}>アイテムボックス</section>
        <section data-testid="card-box" data-original-highlight-target="hand_panel" data-layout-id="layout.cards.box" style={{ position: 'absolute', width: '20%', height: 698,
          ...layoutStyle(originalCardLayout(layouts, 'layout.cards.box')),
          display: built && state.phase !== 'deck' ? 'none' : undefined, background: '#211c28dd' }}>
          <p>手持ちカード</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {inventoryGroups.filter(group => group.indices.length).map(group => {
              const available = group.indices.filter(index => !draft.includes(index))
              return <div key={group.hand} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <button aria-label={`手持ち ${group.hand} N`} disabled={busy || state.phase !== 'deck' || !available.length || draft.length >= 9}
                  style={{ width: 72, height: 108 }} onClick={() => setDraft(previous => [...previous, available[0]])}>
                  <CardView card={save.player.inventory[group.indices[0]]} /></button>
                <span style={{ fontSize: 22 }}>{group.hand === 'rock' ? 'グー' : group.hand === 'scissors' ? 'チョキ' : 'パー'}N x{available.length}</span>
              </div>
            })}
          </div>
        </section>
        {state.text && <OriginalBattleDialogue testId={dialogue ? 'original-tutorial-dialogue' : 'original-tutorial-band'}
          textTestId={dialogue ? 'original-tutorial-text' : undefined} waitForInput={dialogue}
          speaker="マチルダ" text={dialogue ? state.text.slice(0, visibleChars) : state.text} onAdvance={advance} />}
        <OriginalBattleMenus player={save.player} visible={!!state.text} />
        <section data-testid="card-deck" data-original-highlight-target="card_bar" data-layout-id="layout.cards.deck" style={{ position: 'absolute', width: 1920, height: 150,
          ...layoutStyle(originalCardLayout(layouts, 'layout.cards.deck')),
          display: 'flex', justifyContent: 'center', gap: 6, background: '#211c28dd' }}>
          {(state.phase === 'deck' ? draft.map(index => save.player.inventory[index])
            : built ? state.battle.playerDeck : []).map((card, index) =>
            <button key={index} aria-label={`デッキ ${index + 1} ${card.hand}`}
              disabled={busy || state.phase !== 'deck' && (state.phase !== 'selection' || presentationBattle.playerUsed[index])}
              aria-pressed={state.phase === 'selection' && selected === index}
              style={{ width: 70, height: 100, alignSelf: 'center', outline: selected === index ? '4px solid #f5db70' : undefined }}
              onClick={() => state.phase === 'deck' ? setDraft(previous => previous.filter((_, i) => i !== index)) : setSelected(index)}>
              <CardView card={card} /></button>)}
        </section>
        <section data-testid="original-player-hp" data-original-highlight-target="player_hp" style={{ position: 'absolute', right: '5%', bottom: 60,
          background: '#211c28', padding: 8, fontSize: 22 }}>HP: {presentationBattle.playerHp}/3</section>
        {state.phase === 'deck' && <aside style={{ position: 'absolute', left: '35%', top: '68%' }}>
          <button disabled={busy} onClick={() => setDraft(originalAutoDeckIndices(save.player.inventory))}>自動</button>
          <button disabled={busy || draft.length !== 9} onClick={() => void persist(prepareOriginalTutorial(state,
            draft.map(index => save.player.inventory[index])))}>準備完了</button>
        </aside>}
        {state.phase === 'selection' && <aside data-original-highlight-target="action_prompt" style={{ position: 'absolute', left: '35%', top: '66%' }}>
          <p>カードを選択してください</p>
          <button disabled={busy || selected === null} onClick={() => {
            if (selected !== null) { void persist(chooseOriginalTutorialCard(state, selected)); setSelected(null) }
          }}>勝負！</button>
        </aside>}
        {state.highlight && <OriginalBattleHighlight target={state.highlight} options={originalTutorialHighlightOptions(state.playback)} />}
        {state.phase === 'result' && lastRound && !error && <OriginalShowdown key={state.actions.length}
          player={lastRound.player} opponent={lastRound.opponent} result={lastRound.result}
          preview={editorPreview} layouts={layouts} cardsTestId="original-tutorial-result"
          onError={cause => setError(String(cause))} onComplete={() => void persist(continueOriginalTutorial(state))} />}
        {state.phase === 'reward' && <aside role="status" className="original-suspension">
          <p>報酬を獲得しました！</p><p>{state.gold} G</p><button disabled={busy} onClick={() => void finish()}>OK</button>
        </aside>}
        <nav style={{ position: 'absolute', right: 16, top: 12, display: 'flex', gap: 8 }}>
          <span data-testid="original-tutorial-cursor">{state.playback.cursor}:{state.phase}</span>
          <button disabled={busy} onClick={onExit}>タイトルに戻る</button>
        </nav>
        {error && <aside role="alert" className="original-suspension">{error}</aside>}
      </div>
    </div>
  </main>
}
