import { useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { createInitialGameSave, MATILDA_START_CHECKPOINT } from '../../../packages/domain/new-game'
import type { SaveData } from '../../../packages/domain/save'
import type { GameApi } from '../../preload/api'
import './style.css'

const game = (globalThis as typeof globalThis & { janken: GameApi }).janken

function GameScreen() {
  const [saved, setSaved] = useState<SaveData | null>(null)
  const [active, setActive] = useState<SaveData | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    let mounted = true
    void game.save.read().then((save) => {
      if (mounted) setSaved(save)
    }).catch(() => {
      if (mounted) setError('保存データを読み込めませんでした')
    }).finally(() => {
      if (mounted) setLoading(false)
    })
    return () => { mounted = false }
  }, [])

  async function startNewGame() {
    setSaving(true)
    setError('')
    const initial = createInitialGameSave()
    try {
      await game.save.write(initial)
      setSaved(initial)
      setActive(initial)
    } catch {
      setError('保存に失敗しました')
    } finally {
      setSaving(false)
    }
  }

  if (active) {
    const isMatilda = active.progress.checkpoint_id === MATILDA_START_CHECKPOINT
    return <main className="game-screen">
      <div className="checkpoint-panel">
        <p className="eyebrow">Janken Kingdom</p>
        <h1>{isMatilda ? 'マチルダのチュートリアル' : '保存地点'}</h1>
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
        <button onClick={() => { void startNewGame() }} disabled={loading || saving}>はじめから</button>
        <button onClick={() => { if (saved) setActive(saved) }} disabled={loading || saving || !saved}>つづきから</button>
      </div>
      {error && <p role="alert" className="error-message">{error}</p>}
    </div>
  </main>
}

createRoot(document.getElementById('root')!).render(<GameScreen />)
