import { useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { createInitialGameSave } from '../../../packages/domain/new-game'
import type { SaveData } from '../../../packages/domain/save'
import type { GameApi } from '../../preload/api'
import './style.css'
import { isMatildaCheckpoint, normalContent, matildaContent, NORMAL_STORY_ID, MATILDA_STORY_ID } from './matilda-content'
import { isFixedCheckpoint } from '../../../packages/battle/fixed'
import { StoryScreen } from './StoryScreen'
import { GuildHome } from './GuildHome'
import { GUILD_CHECKPOINT } from '../../../packages/guild/routes'
import { BELKA_CHECKPOINT } from '../../../packages/battle/belka'
import { BelkaScreen } from './BelkaScreen'
import { JIN_CHECKPOINT, SUBEVENT1_JIN_CHECKPOINT, SUBEVENT1_MARCO_CHECKPOINT, SUBEVENT1_JIN_STORY_ID,
  isSubevent1JinStoryCheckpoint, prepareSubevent1Jin, prepareSubevent1Marco, returnSubevent1JinToGuild, subevent1JinContent } from '../../../packages/battle/jin'
import { JinScreen } from './JinScreen'

const game = (globalThis as typeof globalThis & { janken: GameApi }).janken

function GameScreen() {
  const [saved, setSaved] = useState<SaveData | null>(null)
  const [active, setActive] = useState<SaveData | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [readFailed, setReadFailed] = useState(false)
  const [confirming, setConfirming] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    let mounted = true
    void game.save.read().then((save) => {
      if (mounted) setSaved(save)
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
    const initial = createInitialGameSave()
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

  if (active) {
    if (active.progress.checkpoint_id === JIN_CHECKPOINT || active.progress.checkpoint_id === SUBEVENT1_JIN_CHECKPOINT ||
        active.progress.checkpoint_id === SUBEVENT1_MARCO_CHECKPOINT) {
      return <JinScreen save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (active.progress.checkpoint_id === BELKA_CHECKPOINT) {
      return <BelkaScreen save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (active.progress.checkpoint_id === GUILD_CHECKPOINT) {
      return <GuildHome save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (isMatildaCheckpoint(active.progress.checkpoint_id)) {
      const normal = isFixedCheckpoint(active.progress.checkpoint_id)
      return <StoryScreen save={active} content={normal ? normalContent : matildaContent}
        storyId={normal ? NORMAL_STORY_ID : MATILDA_STORY_ID} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} onCheckpoint={async (checkpointId) => {
        const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (isSubevent1JinStoryCheckpoint(active.progress.checkpoint_id)) {
      return <StoryScreen save={active} content={subevent1JinContent} storyId={SUBEVENT1_JIN_STORY_ID}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave = checkpointId === SUBEVENT1_JIN_CHECKPOINT
            ? prepareSubevent1Jin(active)
            : checkpointId === SUBEVENT1_MARCO_CHECKPOINT
              ? prepareSubevent1Marco(active)
            : { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onEnd={async () => {
          const nextSave = returnSubevent1JinToGuild(active)
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} />
    }
    return <main className="game-screen">
      <div className="checkpoint-panel">
        <p className="eyebrow">Janken Kingdom</p>
        <h1>保存地点</h1>
        <p>会話・演出画面は次のタスクで実装します。</p>
        <p className="checkpoint-id" data-testid="checkpoint-id">{active.progress.checkpoint_id}</p>
        <button onClick={() => setActive(null)}>タイトルに戻る</button>
      </div>
    </main>
  }

  return <main className="title-screen">
    <div className="title-panel">
      <p className="eyebrow">A game of cards and fate</p>
      <h1>Janken Kingdom</h1>
      <div className="title-actions">
        {confirming ? <div role="alertdialog" aria-labelledby="overwrite-title" aria-describedby="overwrite-description">
          <h2 id="overwrite-title">保存データを上書きしますか？</h2>
          <p id="overwrite-description">現在の進行状況は失われます。この操作は取り消せません。</p>
          <div className="confirmation-actions">
            <button autoFocus onClick={() => setConfirming(false)} disabled={saving}>キャンセル</button>
            <button onClick={() => { void startNewGame() }} disabled={saving}>保存を上書きして開始</button>
          </div>
        </div> : <>
          <button onClick={() => { if (saved) setConfirming(true); else void startNewGame() }} disabled={loading || saving || readFailed}>はじめから</button>
          <button onClick={() => { if (saved) setActive(saved) }} disabled={loading || saving || !saved}>つづきから</button>
        </>}
      </div>
      {error && <p role="alert" className="error-message">{error}</p>}
    </div>
  </main>
}

createRoot(document.getElementById('root')!).render(<GameScreen />)
