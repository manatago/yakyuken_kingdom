import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { OriginalBattleBackground } from './OriginalBattleBackground'
import { OriginalBackground } from './OriginalVisualTransitions'
import { OriginalBattleDialogue } from './OriginalBattleDialogue'
import { OriginalBattleMenus } from './OriginalBattleMenus'
import { OriginalStoryInventory } from './OriginalStoryInventory'
import { OriginalBattleBubble } from './OriginalBattleBubble'
import { originalBattleTypingText } from '../../../packages/story/original-bubble'
import farewellControls from '../../../content/stories/godot-farewell-controls.json'
import type { SaveData } from '../../../packages/domain/save'
import { originalAutoDeckIndices } from '../../../packages/battle/original-janken'
import { originalQuestBattleChapter, setOriginalQuestBattleDraft, prepareOriginalQuestBattleSave,
  updateOriginalQuestBattleSave, settleOriginalQuestBattleSave, resumeOriginalQuestAfterVictory,
  beginOriginalQuestAftermath, originalQuestAftermathFrames, advanceOriginalQuestAftermath, useOriginalQuestBattleItemSave,
  originalQuestLossRedirect, checkpointOriginalQuestLossRedirect, originalQuestLossIncomingScene,
  originalQuestCompletedLossScene } from '../../../packages/story/original-quest-save'
import { originalPortraitSlots, originalStory, type OriginalCommand } from '../../../packages/story/original'
import { getItemDefinition, isBattleUsable, type ItemId } from '../../../packages/domain/item-catalog'
import { stepOriginalQuestRuntime, chooseOriginalQuestRuntimeCard, continueOriginalQuestRuntime, originalQuestPreResultBattle, originalQuestSurface } from '../../../packages/story/original-quest-runtime'
import { fitViewport } from '../../../packages/story/viewport'
import { OriginalPortrait, OriginalStoryScreen } from './OriginalStoryScreen'
import { originalAsset } from './original-assets'
import { CardView } from './CardView'
import { OriginalShowdown } from './OriginalShowdown'

export function OriginalQuestBattleScreen({ save, onSave, onExit }: {
  save: SaveData; onSave: (next: SaveData) => Promise<void>; onExit: () => void
}) {
  const ledger = save.progress.original_quest_battle!
  const redirect = originalQuestLossRedirect(save)
  const redirecting = !!redirect
  const state = ledger.runtime
  const presentationBattle = useMemo(() => state?.phase === 'result' ? originalQuestPreResultBattle(state) : state?.battle, [state])
  const surface = useMemo(() => state ? originalQuestSurface(state) : undefined, [state?.actions, ledger.chapter_id])
  const portraitCommand = useMemo(() => state?.portraitCommand?.kind === 'set_portrait' ? {
    kind: 'show_character', parameters: { ...state.portraitOptions,
      character_id: String(state.portraitCommand.args[0]), portrait_id: state.portrait }
  } as OriginalCommand : undefined, [state?.portraitRevision])
  const chapter = originalQuestBattleChapter(ledger.checkpoint, ledger.chapter_id)
  const frame = ledger.aftermath ? originalQuestAftermathFrames(ledger)[ledger.aftermath.cursor] : undefined
  const farewellControl = ledger.runtime?.outcome === 'lose' && ledger.aftermath
    ? farewellControls.cases.find(entry => entry.checkpoint === ledger.checkpoint)?.frames[ledger.aftermath.cursor] : undefined
  const phase = frame ? 'aftermath' : state?.phase ?? 'deck'
  const text = frame?.text ?? state?.text ?? ''
  const bubbleSide = !frame ? state?.bubbleSide ?? '' : ''
  const typingText = originalBattleTypingText(text, bubbleSide)
  const container = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const latestSave = useRef(save)
  useLayoutEffect(() => { latestSave.current = save }, [save])
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [selected, setSelected] = useState<number | null>(null)
  const [visibleChars, setVisibleChars] = useState(0)
  const [bubbleReady, setBubbleReady] = useState(false)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  useLayoutEffect(() => {
    const element = container.current
    if (!element) return
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize(); const observer = new ResizeObserver(resize); observer.observe(element)
    return () => observer.disconnect()
  }, [redirecting])
  useLayoutEffect(() => { setBubbleReady(false) }, [text, phase])
  useLayoutEffect(() => {
    setVisibleChars(0)
    if (farewellControl) { setVisibleChars(text.length); return }
    if (!['dialogue', 'aftermath'].includes(phase) || bubbleSide && !bubbleReady) return
    const timer = setInterval(() => setVisibleChars(n => Math.min(n + 1, typingText.length)), bubbleSide ? 60 : 30)
    return () => clearInterval(timer)
  }, [text, phase, ledger.aftermath?.cursor, bubbleReady])
  async function write(makeNext: () => SaveData) {
    if (pending.current) return
    pending.current = true; setBusy(true)
    try { await onSave(makeNext()) }
    catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { pending.current = false; setBusy(false) }
  }
  useEffect(() => {
    if (state?.phase !== 'running' || busy || error) return
    const timer = setTimeout(() => void write(() => updateOriginalQuestBattleSave(save,
      stepOriginalQuestRuntime(state, Math.random(), Math.random()))), state.waitSeconds * 1000)
    return () => clearTimeout(timer)
  }, [state, busy, error])
  function advance() {
    if (!state || busy || error) return
    if (frame) {
      if (farewellControl) { void write(() => advanceOriginalQuestAftermath(save)); return }
      if (visibleChars < text.length) setVisibleChars(text.length)
      else void write(() => advanceOriginalQuestAftermath(save))
      return
    }
    if (state.phase === 'dialogue' && visibleChars < typingText.length) setVisibleChars(typingText.length)
    else if (state.phase === 'dialogue') void write(() => updateOriginalQuestBattleSave(save, continueOriginalQuestRuntime(state)))
  }
  function portrait(path: string, options: Record<string, unknown>) {
    const position = options.position as number[] | undefined
    return { portrait_id: path, portrait_scale: Number(options.scale ?? 1), side_override: String(options.side ?? 'center'),
      position_mode: 'offset', position: { type: 'Vector2', x: position?.[0] ?? 0, y: position?.[1] ?? 0 }, visible: true }
  }
  const round = state?.battle.rounds.at(-1)
  const cards = state?.battle.playerDeck ?? ledger.draft.map(index => save.player.inventory[index])
  const lossScene = originalQuestCompletedLossScene(save)
  const farewellScene = farewellControl ? originalQuestLossIncomingScene(save) : undefined
  if (redirect) return <OriginalStoryScreen key={redirect.sequenceId} sequenceId={redirect.sequenceId} cursor={redirect.cursor}
    incomingScene={originalQuestLossIncomingScene(save)} player={save.player}
    initialFlags={Object.fromEntries(save.progress.flags.map(flag => [flag, true]))} onExit={onExit}
    onCheckpoint={async story => {
      // The child playback retains callbacks; always checkpoint against the latest ledger.
      const next = checkpointOriginalQuestLossRedirect(latestSave.current, story.cursor,
        Object.entries(story.flags).filter(([, value]) => value).map(([key]) => key))
      await onSave(next); latestSave.current = next
    }} onComplete={async story => {
      const next = checkpointOriginalQuestLossRedirect(latestSave.current, story.cursor,
        Object.entries(story.flags).filter(([, value]) => value).map(([key]) => key), true)
      await onSave(next); latestSave.current = next
    }} />
  return <main ref={container} className="story-viewport" tabIndex={0} onKeyDown={event => {
    if (event.target === event.currentTarget && ['Enter', 'Space'].includes(event.code)) { event.preventDefault(); advance() }
  }}>
    <div className="story-frame" style={{ width: fit.width, height: fit.height }}><div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
      {farewellScene && farewellControl ? <OriginalBackground path={originalAsset(farewellScene.background)} filtered={farewellControl.filtered} duration={0} />
        : lossScene ? <OriginalBackground path={originalAsset(lossScene.background)} filtered={lossScene.backgroundFiltered} duration={0} />
        : frame || surface?.blurred === false ? <img className="story-background" alt="背景" src={originalAsset(state?.background || chapter.background)} />
          : <OriginalBattleBackground path={originalAsset(state?.background || chapter.background)} />}
      {state && !frame && <><OriginalPortrait id="deck" value={portrait(state.pedestal, state.pedestalOptions)} />
        <OriginalPortrait id={chapter.opponent_id} value={portrait(state.portrait, state.portraitOptions)} command={portraitCommand} /></>}
      {lossScene ? originalPortraitSlots(lossScene).filter(slot => slot.value.visible).map(slot =>
        <OriginalPortrait key={slot.side} id={slot.id} value={slot.value} />)
        : frame?.portrait && <OriginalPortrait id={chapter.opponent_id} rawLayout value={{ ...portrait(frame.portrait, { scale: frame.scale, side: 'right' }), flip: 0 }} />}
      {!frame && (!state || state.uiVisible) && <>
        <section data-testid="original-opponent-hp" style={{ position: 'absolute', top: 8, left: '40%', fontSize: 24 }}>{chapter.opponent_name} HP: {presentationBattle?.opponentHp ?? chapter.opponent_hp}/{chapter.opponent_hp}</section>
        <section data-testid="original-player-hp" style={{ position: 'absolute', bottom: 160, right: 40, fontSize: 24 }}>HP: {presentationBattle?.playerHp ?? chapter.player_hp}/{chapter.player_hp}</section>
        <section style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 150, display: 'flex', justifyContent: 'center', gap: 6, background: '#211c28dd' }}>
          {cards.map((card, index) => <button key={index} aria-label={`デッキ ${index + 1} ${card.hand}`} aria-pressed={selected === index}
            disabled={busy || !!state && (phase !== 'selection' || presentationBattle!.playerUsed[index])}
            style={{ width: 70, height: 100, alignSelf: 'center' }} onClick={() => state ? setSelected(index)
              : void write(() => setOriginalQuestBattleDraft(save, ledger.draft.filter((_, i) => i !== index)))}><CardView card={card} /></button>)}
        </section>
      </>}
      {!state && <>
        <section aria-label="手持ちカード" style={{ position: 'absolute', right: 20, top: 70, width: 300, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
          {save.player.inventory.map((card, index) => <button key={index} aria-label={`手持ち ${index + 1} ${card.hand} ${card.grade}`}
            style={{ width: 70, height: 100 }} disabled={busy || ledger.draft.includes(index) || ledger.draft.length >= chapter.player_deck_size}
            onClick={() => void write(() => setOriginalQuestBattleDraft(save, [...ledger.draft, index]))}><CardView card={card} /></button>)}
        </section>
        <aside className="original-suspension"><p>デッキに{chapter.player_deck_size}枚セットしてください</p>
          <button disabled={busy} onClick={() => void write(() => setOriginalQuestBattleDraft(save,
            originalAutoDeckIndices(save.player.inventory).slice(0, chapter.player_deck_size)))}>自動</button>
          <button disabled={busy || ledger.draft.length !== chapter.player_deck_size} onClick={() => void write(() => prepareOriginalQuestBattleSave(save))}>準備完了</button>
        </aside>
      </>}
      {frame ? <OriginalStoryInventory player={save.player} palette={farewellScene?.bandColor} />
        : <OriginalBattleMenus player={save.player} visible={surface?.bandVisible ?? false} />}
      {frame ? <OriginalBattleDialogue testId="original-quest-dialogue" textTestId="original-quest-text"
        mode="minigame" bodyVisible={farewellControl?.body_visible ?? true}
        text={text.slice(0, visibleChars)} onAdvance={advance} /> : <>
        {surface?.bandVisible && surface.band && <OriginalBattleDialogue
          testId={phase === 'dialogue' && !bubbleSide ? 'original-quest-dialogue' : 'original-quest-band'}
          textTestId={phase === 'dialogue' && !bubbleSide ? 'original-quest-text' : undefined}
          waitForInput={phase === 'dialogue' && !bubbleSide}
          speaker={String(originalStory.cast[surface.band.speaker]?.display_name ?? (surface.band.speaker === chapter.opponent_id ? chapter.opponent_name : ''))}
          text={phase === 'dialogue' && !bubbleSide ? surface.band.text.slice(0, visibleChars) : surface.band.text} onAdvance={advance} />}
        {surface?.bubble && <OriginalBattleBubble
          testId={phase === 'dialogue' && bubbleSide ? 'original-quest-dialogue' : 'original-quest-bubble'}
          textTestId={phase === 'dialogue' && bubbleSide ? 'original-quest-text' : undefined}
          text={surface.bubble.text} side={surface.bubble.side} revision={surface.bubble.revision}
          waitForInput={phase === 'dialogue' && !!bubbleSide} onReady={() => setBubbleReady(true)}
          visibleCharacters={phase === 'dialogue' && bubbleSide ? visibleChars : originalBattleTypingText(surface.bubble.text, surface.bubble.side).length}
          onAdvance={advance} />}
      </>}
      {state?.phase === 'selection' && <aside className="original-suspension"><p>カードを選択してください</p>
        <section aria-label="戦闘アイテム">
          {[...new Set([...(save.player.items ?? []), ...(state.resources?.roundItem ? [state.resources.roundItem] : [])])].map(id => {
            const item = getItemDefinition(id)
            return item && isBattleUsable(item) ? <button key={id} disabled={busy} aria-pressed={state.resources?.roundItem === id}
              title={item.description} onClick={() => void write(() => useOriginalQuestBattleItemSave(save, id as ItemId))}>{item.name}</button> : null
          })}
          {(save.player.equipment ?? []).map(id => <span key={id} title={getItemDefinition(id)?.description}>{getItemDefinition(id)?.name}</span>)}
        </section>
        <button disabled={busy || selected === null} onClick={() => { if (selected !== null) {
          void write(() => updateOriginalQuestBattleSave(save, chooseOriginalQuestRuntimeCard(state, selected))); setSelected(null)
        } }}>勝負！</button></aside>}
      {state?.phase === 'result' && round && !error && <OriginalShowdown key={state.actions.length}
        player={round.player} opponent={round.opponent} result={round.result} onError={cause => setError(String(cause))}
        onComplete={() => void write(() => updateOriginalQuestBattleSave(save, continueOriginalQuestRuntime(state)))} />}
      {state?.phase === 'finished' && !frame && <aside role="status" className="original-suspension">
        <p>{state.outcome === 'win' ? '報酬を獲得しました！' : state.outcome === 'lose' ? '奪われました...' : '引き分け'}</p>
        {!ledger.settlement ? <button disabled={busy} onClick={() => void write(() => {
          const settled = settleOriginalQuestBattleSave(save, Math.random())
          return state.outcome === 'win' ? resumeOriginalQuestAfterVictory(settled) : beginOriginalQuestAftermath(settled, Math.random())
        })}>OK</button> : <button disabled={busy} onClick={() => void write(() => beginOriginalQuestAftermath(save, Math.random()))}>次へ</button>}
      </aside>}
      <nav style={{ position: 'absolute', top: 12, right: 16 }}><span data-testid="original-quest-battle-cursor">{chapter.opponent_id}:{state?.actions.length ?? 0}:{phase}</span>
        <button disabled={busy} onClick={onExit}>タイトルに戻る</button></nav>
      {error && <aside role="alert" className="original-suspension">{error}</aside>}
    </div></div>
  </main>
}
