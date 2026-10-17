import { lazy, Suspense, useEffect, useMemo, useRef, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { createNewGameSave } from '../../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../../packages/domain/save'
import type { GameApi } from '../../preload/api'
import './style.css'
import { TitleNavigation, type TitleMenu } from './TitleNavigation'
import { GameExitProvider } from './GameExit'
import { OriginalStoryViewerProvider, useOriginalStoryViewer } from './OriginalStoryViewer'
import { GuildHome } from './GuildHome'
import { GUILD_CHECKPOINT, ORIGINAL_STAGE1_END } from '../../../packages/guild/routes'
import { RandomBattleScreen } from './RandomBattleScreen'
import { RANDOM_BATTLE_CHECKPOINT, TOWN_CHECKPOINT, TOWN_ENCOUNTER_CHECKPOINT } from '../../../packages/battle/random'
const OriginalStoryScreen = lazy(() => import('./OriginalStoryScreen').then(module => ({ default: module.OriginalStoryScreen })))
const OriginalTutorialScreen = lazy(() => import('./OriginalTutorialScreen').then(module => ({ default: module.OriginalTutorialScreen })))
import { createOriginalTutorial } from '../../../packages/story/original-tutorial'
import { createOriginalNormal } from '../../../packages/story/original-normal'
import { createOriginalAdventurer } from '../../../packages/story/original-adventurer'
const OriginalAdventurerScreen = lazy(() => import('./OriginalAdventurerScreen').then(module => ({ default: module.OriginalAdventurerScreen })))
import { originalAutoDeckIndices } from '../../../packages/battle/original-janken'
import { getGoldBonus } from '../../../packages/domain/item-catalog'
import { originalQuestIncomingScene } from '../../../packages/story/original-quests'
import { originalMainIncomingScene } from '../../../packages/story/original-matilda-aftermath-save'
const OriginalNormalScreen = lazy(() => import('./OriginalNormalScreen').then(module => ({ default: module.OriginalNormalScreen })))
const OriginalMatildaAftermathScreen = lazy(() => import('./OriginalMatildaAftermathScreen').then(module => ({ default: module.OriginalMatildaAftermathScreen })))
const OriginalQuestBattleScreen = lazy(() => import('./OriginalQuestBattleScreen').then(module => ({ default: module.OriginalQuestBattleScreen })))
const OriginalCurseScreen = lazy(() => import('./OriginalCurseScreen').then(module => ({ default: module.OriginalCurseScreen })))
const OriginalExpressionScreen = lazy(() => import('./OriginalExpressionScreen').then(module => ({ default: module.OriginalExpressionScreen })))
const OriginalEvidenceScreen = lazy(() => import('./OriginalEvidenceScreen').then(module => ({ default: module.OriginalEvidenceScreen })))
const OriginalStrengthScreen = lazy(() => import('./OriginalStrengthScreen').then(module => ({ default: module.OriginalStrengthScreen })))
const OriginalQuestionScreen = lazy(() => import('./OriginalQuestionScreen').then(module => ({ default: module.OriginalQuestionScreen })))

const gameBridge = (globalThis as typeof globalThis & { janken: GameApi }).janken

function GameScreen() {
  const [saved, setSavedState] = useState<SaveData | null>(null)
  const [active, setActiveState] = useState<SaveData | null>(null)
  const [menu, setMenu] = useState<TitleMenu>('title')
  const session = useRef<{ normalSave: SaveData | null; origin: 'jump' | 'events' } | null>(null)
  const generation = useRef(0)
  const currentGeneration = generation.current
  const pendingWrites = useRef(new Set<Promise<void>>())
  const currentSession = session.current
  function setSaved(next: SaveData | null) {
    if (currentGeneration !== generation.current) return
    if (currentSession && currentSession !== session.current) return
    setSavedState(next)
  }
  // Scene selection is disposable play in this window, not a write to the normal save.
  const game = { save: { read: gameBridge.save.read, write: async (next: SaveData) => {
    if (currentGeneration !== generation.current) return
    if (currentSession) { parseSave(next); return }
    const pending = gameBridge.save.write(next)
    pendingWrites.current.add(pending)
    try { await pending } finally { pendingWrites.current.delete(pending) }
  } } }
  function setActive(next: SaveData | null) {
    if (currentGeneration !== generation.current) return
    if (currentSession && currentSession !== session.current) return
    const eventFinished = session.current?.origin === 'events' && active && next && (
      active.progress.original_normal && !next.progress.original_normal ||
      active.progress.original_quest_battle && (!next.progress.original_quest_battle || next.progress.original_quest_battle.settlement))
    if ((!next || eventFinished) && session.current) {
      setSaved(session.current.normalSave); setMenu(session.current.origin); session.current = null
      setActiveState(null); return
    }
    setActiveState(next)
  }
  function beginScene(next: SaveData, origin: 'jump' | 'events') {
    session.current = { normalSave: saved, origin }
    setSaved(next); setError(''); setActiveState(next)
  }
  const questIncomingScene = useMemo(() => active ? originalQuestIncomingScene(active) ?? originalMainIncomingScene(active) : undefined, [active])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const originalTransitionPending = useRef(false)
  const [readFailed, setReadFailed] = useState(false)
  const [confirming, setConfirming] = useState(false)
  const [error, setError] = useState('')
  const { setViewer } = useOriginalStoryViewer()
  useEffect(() => { if (!active) setViewer(null) }, [active, setViewer])

  useEffect(() => {
    let mounted = true
    void game.save.read().then((save) => {
      if (mounted) {
        setSaved(save)
        if (save && new URLSearchParams(location.search).get('resume') === '1') setActive(save)
      }
    }).catch(() => {
      if (mounted) {
        setReadFailed(true)
        setError('保存データを読み込めませんでした。既存データを保護するため、新規開始を無効にしています。')
      }
    }).finally(() => {
      if (mounted) setLoading(false)
    })
    return () => { mounted = false }
  }, [])

  async function startNewGame() {
    if (loading || saving || readFailed || (saved && !confirming)) return
    setSaving(true)
    setError('')
    const initial = createNewGameSave()
    try {
      await game.save.write(initial)
      setSaved(initial)
      setConfirming(false)
      setActive(initial)
    } catch {
      setError('保存に失敗しました')
    } finally {
      setSaving(false)
    }
  }

  function exitToTitle() {
    const previous = session.current
    generation.current++
    const exitGeneration = generation.current
    session.current = null
    if (previous) setSavedState(previous.normalSave)
    setActiveState(null); setMenu('title'); setConfirming(false); setViewer(null); setError(''); setSaving(false)
    originalTransitionPending.current = false
    if (!previous) {
      setLoading(true)
      void Promise.allSettled([...pendingWrites.current]).then(() => gameBridge.save.read()).then(next => {
        if (generation.current === exitGeneration) setSavedState(next)
      }).catch(() => {
        if (generation.current === exitGeneration) { setReadFailed(true); setError('保存データを読み込めませんでした。') }
      }).finally(() => { if (generation.current === exitGeneration) setLoading(false) })
    }
  }

  function renderScreen() {
  if (active) {
    if (active.progress.original_question_game) {
      return <Suspense fallback={<main>原本のミニゲームを読み込んでいます…</main>}>
        <OriginalQuestionScreen save={active} onExit={() => setActive(null)} onSave={async next => {
          await game.save.write(next); setSaved(next); setActive(next)
        }} />
      </Suspense>
    }
    if (active.progress.original_strength_game) {
      return <Suspense fallback={<main>原本のミニゲームを読み込んでいます…</main>}>
        <OriginalStrengthScreen save={active} onExit={() => setActive(null)} onSave={async next => {
          await game.save.write(next); setSaved(next); setActive(next)
        }} />
      </Suspense>
    }
    if (active.progress.original_evidence_game) {
      return <Suspense fallback={<main>原本のミニゲームを読み込んでいます…</main>}>
        <OriginalEvidenceScreen save={active} onExit={() => setActive(null)} onSave={async next => {
          await game.save.write(next); setSaved(next); setActive(next)
        }} />
      </Suspense>
    }
    if (active.progress.original_expression_game) {
      return <Suspense fallback={<main>原本のミニゲームを読み込んでいます…</main>}>
        <OriginalExpressionScreen save={active} onExit={() => setActive(null)} onSave={async next => {
          await game.save.write(next); setSaved(next); setActive(next)
        }} />
      </Suspense>
    }
    if (active.progress.original_curse_game) {
      return <Suspense fallback={<main>原本のミニゲームを読み込んでいます…</main>}>
        <OriginalCurseScreen save={active} onExit={() => setActive(null)} onSave={async next => {
          await game.save.write(next); setSaved(next); setActive(next)
        }} />
      </Suspense>
    }
    if (active.progress.original_adventurer) {
      return <Suspense fallback={<main>原本の冒険者チュートリアルを読み込んでいます…</main>}>
        <OriginalAdventurerScreen save={active} onExit={() => setActive(null)} onSave={async next => {
          await game.save.write(next); setSaved(next); setActive(next)
        }} />
      </Suspense>
    }
    if (active.progress.original_quest_battle) {
      return <Suspense fallback={<main>原本の依頼戦を読み込んでいます…</main>}>
        <OriginalQuestBattleScreen save={active} onExit={() => setActive(null)} onSave={async next => {
          await game.save.write(next); setSaved(next); setActive(next)
        }} />
      </Suspense>
    }
    if (active.progress.original_matilda_aftermath) {
      return <Suspense fallback={<main>原本の勝敗後処理を読み込んでいます…</main>}>
        <OriginalMatildaAftermathScreen save={active} onExit={() => setActive(null)} onSave={async next => {
          await game.save.write(next); setSaved(next); setActive(next)
        }} />
      </Suspense>
    }
    if (active.progress.original_normal) {
      return <Suspense fallback={<main>原本の通常戦を読み込んでいます…</main>}>
        <OriginalNormalScreen save={active} onExit={() => setActive(null)} onSave={async next => {
          await game.save.write(next); setSaved(next); setActive(next)
        }} />
      </Suspense>
    }
    if (active.progress.original_tutorial) {
      return <Suspense fallback={<main>原本の戦闘を読み込んでいます…</main>}>
        <OriginalTutorialScreen save={active} onExit={() => setActive(null)} onSave={async next => {
          await game.save.write(next); setSaved(next); setActive(next)
        }} />
      </Suspense>
    }
    if (active.progress.checkpoint_id.startsWith('original:')) {
      const [, sequenceId, savedCursor] = active.progress.checkpoint_id.split(':')
      const cursor = Number(savedCursor)
      const transition = async (choice: 'next' | 'retry') => {
        if (originalTransitionPending.current) return
        originalTransitionPending.current = true; setSaving(true)
        try {
          const { completeOriginalMatildaStory } = await import('../../../packages/story/original-flow')
          // Story playback updates saved checkpoints without remounting its active component.
          const next = completeOriginalMatildaStory(saved ?? active, choice)
          await game.save.write(next); setSaved(next); setActive(next)
        } catch { setError('保存に失敗しました') }
        finally { originalTransitionPending.current = false; setSaving(false) }
      }
      return <>{currentSession && <button className="scene-session-return" onClick={() => setActive(null)}>
        {currentSession.origin === 'events' ? 'イベント選択に戻る' : '場面選択に戻る'}</button>}
      <Suspense fallback={<main>原本データを読み込んでいます…</main>}>
        <OriginalStoryScreen key={sequenceId} sequenceId={sequenceId} cursor={cursor} player={active.player}
          incomingScene={questIncomingScene}
          completedBattles={[...(active.progress.original_quest?.completed_battles ?? []), ...(active.progress.original_completed_minigames ?? []), ...(active.progress.original_completed_battles ?? [])]}
          initialFlags={Object.fromEntries(active.progress.flags.map(flag => [flag, true]))}
          onExit={() => setActive(null)}
          onComplete={sequenceId === 'stage1' || active.progress.original_quest ? async state => {
            if (originalTransitionPending.current) return
            originalTransitionPending.current = true
            try {
              const { completeOriginalStage1Story, advanceOriginalQuestStory } = await import('../../../packages/story/original-flow')
              const current = { ...(saved ?? active), progress: { ...(saved ?? active).progress,
                checkpoint_id: `original:${state.sequenceId}:${state.cursor}` } }
              const next = current.progress.original_quest ? advanceOriginalQuestStory(current) : completeOriginalStage1Story(current)
              await game.save.write(next); setSaved(next); setActive(next)
            } finally { originalTransitionPending.current = false }
          } : undefined}
          ending={sequenceId === 'prologue_battle_win' ? <>
            <h2>勝利！</h2><p>見事な勝利です！次の章へ進みますか？</p>
            <button disabled={saving} onClick={() => void transition('next')}>次の章へ</button>
            <button disabled={saving} onClick={() => setActive(null)}>タイトルに戻る</button>
            {error && <p role="alert">{error}</p>}
          </> : sequenceId === 'prologue_battle_lose' ? <>
            <h2>敗北...</h2><p>残念...再戦しますか？</p>
            <button disabled={saving} onClick={() => void transition('retry')}>再戦する</button>
            <button disabled={saving} onClick={() => setActive(null)}>タイトルに戻る</button>
            {error && <p role="alert">{error}</p>}
          </> : undefined}
          onBattle={async (command, state) => {
            if (command.parameters.is_minigame && command.parameters.chapter_path === 'res://battle/chapters/Stage5MinigameChapter.gd') {
              const { createOriginalQuestionGame } = await import('../../../packages/story/original-question-game')
              const next: SaveData = { ...active, progress: { ...active.progress,
                checkpoint_id: `original:${sequenceId}:${state.cursor}`,
                flags: Object.entries(state.flags).filter(([, value]) => value).map(([key]) => key),
                original_question_game: { game: createOriginalQuestionGame(Array.from({ length: 7 }, () => Math.random())), cursor: 0 } } }
              await game.save.write(next); setSaved(next); setActive(next); return
            }
            if (command.parameters.is_minigame && command.parameters.chapter_path === 'res://battle/chapters/Stage4MinigameChapter.gd') {
              const { createOriginalStrengthGame } = await import('../../../packages/story/original-strength-game')
              const next: SaveData = { ...active, progress: { ...active.progress,
                checkpoint_id: `original:${sequenceId}:${state.cursor}`,
                flags: Object.entries(state.flags).filter(([, value]) => value).map(([key]) => key),
                original_strength_game: { game: createOriginalStrengthGame(Array.from({ length: 5 }, () => Math.random())), cursor: 0 } } }
              await game.save.write(next); setSaved(next); setActive(next); return
            }
            if (command.parameters.is_minigame && command.parameters.chapter_path === 'res://battle/chapters/Stage3MinigameChapter.gd') {
              const { createOriginalEvidenceGame } = await import('../../../packages/story/original-evidence-game')
              const next: SaveData = { ...active, progress: { ...active.progress,
                checkpoint_id: `original:${sequenceId}:${state.cursor}`,
                flags: Object.entries(state.flags).filter(([, value]) => value).map(([key]) => key),
                original_evidence_game: { game: createOriginalEvidenceGame(Array.from({ length: 13 }, () => Math.random())), cursor: 0 } } }
              await game.save.write(next); setSaved(next); setActive(next); return
            }
            if (command.parameters.is_minigame && command.parameters.chapter_path === 'res://battle/chapters/Stage2MinigameChapter.gd') {
              const { createOriginalExpressionGame } = await import('../../../packages/story/original-expression-game')
              const next: SaveData = { ...active, progress: { ...active.progress,
                checkpoint_id: `original:${sequenceId}:${state.cursor}`,
                flags: Object.entries(state.flags).filter(([, value]) => value).map(([key]) => key),
                original_expression_game: { game: createOriginalExpressionGame(Math.random()), cursor: 0 } } }
              await game.save.write(next); setSaved(next); setActive(next); return
            }
            if (active.progress.original_quest?.id === 'subevent3' && command.parameters.is_minigame &&
                command.parameters.chapter_path === 'res://battle/chapters/Subevent3MinigameChapter.gd') {
              const { createOriginalCurseGame } = await import('../../../packages/story/original-curse-game')
              const next: SaveData = { ...active, progress: { ...active.progress,
                checkpoint_id: `original:${sequenceId}:${state.cursor}`,
                flags: Object.entries(state.flags).filter(([, value]) => value).map(([key]) => key),
                original_curse_game: { game: createOriginalCurseGame(Array.from({ length: 8 }, () => Math.random())), cursor: 0 } } }
              await game.save.write(next); setSaved(next); setActive(next); return
            }
            const { originalQuestBattleChapters } = await import('../../../packages/story/original-quest-battle')
            const campaignBattle = /^res:\/\/battle\/chapters\/Stage[2-6]BattleChapter\.gd$/.test(String(command.parameters.chapter_path))
            if (!command.parameters.is_minigame && !command.parameters.is_tutorial &&
                (campaignBattle || active.progress.original_quest && originalQuestBattleChapters.some(chapter => chapter.chapter_path === command.parameters.chapter_path))) {
              const { startOriginalQuestBattleSave } = await import('../../../packages/story/original-quest-save')
              const next = startOriginalQuestBattleSave({ ...active, progress: { ...active.progress,
                checkpoint_id: `original:${sequenceId}:${state.cursor}`,
                flags: Object.entries(state.flags).filter(([, value]) => value).map(([key]) => key) } })
              await game.save.write(next); setSaved(next); setActive(next); return
            }
            if (command.parameters.chapter_path === 'res://battle/chapters/Stage1BattleChapter.gd' && command.parameters.is_tutorial) {
              const next: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: `original:${sequenceId}:${state.cursor}`,
                original_adventurer: createOriginalAdventurer(getGoldBonus((active.player.equipment ?? []).map(id => ({ id }))), active.player.money) } }
              await game.save.write(next); setSaved(next); setActive(next); return
            }
            if (command.parameters.chapter_path !== 'res://battle/chapters/PrologueBattleChapter.gd') return
            const deck = originalAutoDeckIndices(active.player.inventory).map(index => active.player.inventory[index])
            const nextSave: SaveData = { ...active, progress: { ...active.progress,
              checkpoint_id: `original:${sequenceId}:${state.cursor}`,
              ...(command.parameters.is_tutorial ? { original_tutorial: createOriginalTutorial() }
                : { original_normal: createOriginalNormal(deck, active.player.money,
                  getGoldBonus((active.player.equipment ?? []).map(id => ({ id })))) }),
              flags: Object.entries(state.flags).filter(([, value]) => value).map(([key]) => key) } }
            await game.save.write(nextSave); setSaved(nextSave); setActive(nextSave)
          }}
          onCheckpoint={async (state) => {
            const nextSave: SaveData = { ...active, progress: { ...active.progress,
              checkpoint_id: `original:${sequenceId}:${state.cursor}`,
              flags: Object.entries(state.flags).filter(([, value]) => value).map(([key]) => key) } }
            await game.save.write(nextSave)
            setSaved(nextSave)
          }} />
      </Suspense></>
    }
    if ([TOWN_CHECKPOINT, TOWN_ENCOUNTER_CHECKPOINT, RANDOM_BATTLE_CHECKPOINT].includes(active.progress.checkpoint_id)) {
      return <RandomBattleScreen save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (active.progress.checkpoint_id === GUILD_CHECKPOINT && active.progress.guild_return_checkpoint === ORIGINAL_STAGE1_END) {
      return <GuildHome save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    return <main className="game-screen">
      <div className="checkpoint-panel" data-testid="unsupported-save">
        <p className="eyebrow">Janken Kingdom</p>
        <h1>保存地点</h1>
        <p>この保存地点はGodot原本の再生に対応していません。別のストーリーには置き換えません。保存データは変更していません。</p>
        <p className="checkpoint-id" data-testid="checkpoint-id">{active.progress.checkpoint_id}</p>
        <button onClick={() => setActive(null)}>タイトルに戻る</button>
      </div>
    </main>
  }

  return <main className="title-screen">
    <div className={menu === 'title' ? 'title-panel' : 'title-panel title-panel--submenu'}>
      <p className="eyebrow">A game of cards and fate</p>
      <h1>Janken Kingdom</h1>
      <div className="title-actions">
        {menu !== 'title' ? <TitleNavigation key={menu} menu={menu} onMenu={setMenu} onPlay={beginScene}
          disabled={loading || saving || readFailed} onEditor={view => {
            if (!gameBridge.launcher) return Promise.reject(new Error('Editor launcher unavailable'))
            return gameBridge.launcher.openEditor(view)
          }} /> : confirming ? <div role="alertdialog" aria-labelledby="overwrite-title" aria-describedby="overwrite-description">
          <h2 id="overwrite-title">保存データを上書きしますか？</h2>
          <p id="overwrite-description">現在の進行状況は失われます。この操作は取り消せません。</p>
          <div className="confirmation-actions">
            <button autoFocus onClick={() => setConfirming(false)} disabled={saving}>キャンセル</button>
            <button onClick={() => { void startNewGame() }} disabled={saving}>保存を上書きして開始</button>
          </div>
        </div> : <>
          <button onClick={() => { if (saved) setConfirming(true); else void startNewGame() }} disabled={loading || saving || readFailed}>新しく始める</button>
          <button onClick={() => setMenu('jump')} disabled={loading || saving}>中断から始める</button>
          <button onClick={() => setMenu('events')} disabled={loading || saving}>イベントバトル</button>
          <button onClick={() => setMenu('edit')} disabled={loading || saving}>編集モードで始める</button>
          <button onClick={() => { if (saved) setActive(saved) }} disabled={loading || saving || !saved}>つづきから</button>
        </>}
      </div>
      {error && <p role="alert" className="error-message">{error}</p>}
    </div>
  </main>
  }
  return <GameExitProvider onExit={exitToTitle}>{renderScreen()}</GameExitProvider>
}

const originalSequence = new URLSearchParams(location.search).get('original')
const originalCursor = Number(new URLSearchParams(location.search).get('cursor') || 0)
function Application() {
  const [reference, setReference] = useState(originalSequence)
  return reference
    ? <Suspense fallback={<main>原本データを読み込んでいます…</main>}><OriginalStoryScreen sequenceId={reference} debugControls
      cursor={originalCursor} ending="原本シーケンス終了" onExit={() => {
        const url = new URL(location.href); url.search = ''
        history.replaceState(null, '', url.href)
        setReference(null)
      }} /></Suspense>
    : <GameScreen />
}
createRoot(document.getElementById('root')!).render(<OriginalStoryViewerProvider><Application /></OriginalStoryViewerProvider>)
