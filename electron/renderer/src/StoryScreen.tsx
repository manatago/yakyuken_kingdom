import { useLayoutEffect, useMemo, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { advanceStory, startStory } from '../../../packages/story/runner'
import { fitViewport } from '../../../packages/story/viewport'
import { matildaContent, MATILDA_STORY_ID, tutorialImage } from './matilda-content'

export function StoryScreen({ save, onCheckpoint, onTitle }: {
  save: SaveData
  onCheckpoint: (checkpointId: string) => Promise<void>
  onTitle: () => void
}) {
  const viewport = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const frame = useMemo(() => startStory(matildaContent, MATILDA_STORY_ID, save.progress.checkpoint_id), [save.progress.checkpoint_id])

  useLayoutEffect(() => {
    const element = viewport.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize()
    const observer = new ResizeObserver(resize)
    observer.observe(element)
    return () => observer.disconnect()
  }, [])

  async function next() {
    if (pending.current || frame.step.kind === 'end') return
    pending.current = true
    setBusy(true)
    setError('')
    try {
      const nextFrame = advanceStory(matildaContent, MATILDA_STORY_ID, frame)
      await onCheckpoint(nextFrame.step.id)
    } catch {
      setError('保存に失敗しました。会話は進んでいません。')
    } finally {
      pending.current = false
      setBusy(false)
    }
  }

  return <main ref={viewport} className="story-viewport">
    <div className="story-frame" data-testid="story-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        {frame.backgroundAssetId && <img className="story-background" alt="牢屋の背景" src={tutorialImage(frame.backgroundAssetId)} />}
        {Object.entries(frame.portraits).map(([slot, portrait]) => {
          const layout = matildaContent.layouts.find((entry) => entry.id === portrait.layoutId)!
          return <img key={slot} className="story-portrait" data-testid="story-portrait" alt="マチルダの立ち絵"
            src={tutorialImage(portrait.assetId)} style={{ left: layout.x, top: layout.y,
              transform: `translate(-50%, -50%) scale(${layout.flipped ? -layout.scale : layout.scale}, ${layout.scale})` }} />
        })}
        <header className="story-header">
          <h1>マチルダのチュートリアル</h1>
          <span className="story-checkpoint" data-testid="checkpoint-id">{frame.step.id}</span>
          <button onClick={onTitle} disabled={busy}>タイトルに戻る</button>
        </header>
        <aside className="story-reserved story-items">アイテムボックス<br /><small>表示機能は準備中</small></aside>
        <aside className="story-reserved story-cards">カードボックス<br /><small>カード表示は次のタスク</small></aside>
        <section className="story-dialogue" aria-label="会話">
          {frame.step.kind === 'line' ? <>
            <p className="story-speaker">{frame.step.speaker_id === 'matilda' ? 'マチルダ' : frame.step.speaker_id ?? 'ナレーション'}</p>
            <p className="story-text" data-testid="story-text" aria-live="polite">{frame.text}</p>
            <button onClick={() => { void next() }} disabled={busy}>次へ</button>
          </> : <>
            <h2>カード操作は準備中です。</h2>
            <p>会話の表示はここまでです。デッキ操作と対戦は後続タスクで実装します。</p>
          </>}
          {error && <p className="error-message" role="alert">{error}</p>}
        </section>
      </div>
    </div>
  </main>
}
