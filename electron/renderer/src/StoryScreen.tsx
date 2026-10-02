import { useLayoutEffect, useMemo, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { advanceStory, startStory } from '../../../packages/story/runner'
import { SUBEVENT1_JIN_STORY_ID } from '../../../packages/battle/jin'
import { fitViewport } from '../../../packages/story/viewport'
import { matildaContent, MATILDA_STORY_ID, tutorialImage } from './matilda-content'
import { CardPanel } from './CardPanel'
import { TutorialBattle } from './TutorialBattle'
import { DeckEditor } from './DeckEditor'
import { FixedBattle } from './FixedBattle'
import type { ContentPack } from '../../../packages/content/schema'
import { enterGuildHome } from '../../../packages/guild/home'
import { canEnterGuildHome } from '../../../packages/guild/routes'

export function StoryScreen({ save, onCheckpoint, onSave, onTitle, onEnd, content = matildaContent, storyId = MATILDA_STORY_ID }: {
  save: SaveData
  onCheckpoint: (checkpointId: string) => Promise<void>
  onSave: (save: SaveData) => Promise<void>
  onTitle: () => void
  onEnd?: () => void
  content?: ContentPack
  storyId?: string
}) {
  const viewport = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [editing, setEditing] = useState(false)
  const frame = useMemo(() => startStory(content, storyId, save.progress.checkpoint_id), [content, storyId, save.progress.checkpoint_id])

  useLayoutEffect(() => {
    const element = viewport.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize()
    const observer = new ResizeObserver(resize)
    observer.observe(element)
    return () => observer.disconnect()
  }, [])

  async function next(checkpoint?: string) {
    if (pending.current || frame.step.kind === 'end' && !checkpoint) return
    pending.current = true
    setBusy(true)
    setError('')
    try {
      await onCheckpoint(checkpoint ?? advanceStory(content, storyId, frame).step.id)
    } catch {
      setError('保存に失敗しました。会話は進んでいません。')
    } finally {
      pending.current = false
      setBusy(false)
    }
  }

  async function openGuild() {
    if (pending.current || editing || !canEnterGuildHome(save)) return
    pending.current = true
    setBusy(true)
    setError('')
    try { await onSave(enterGuildHome(save)) }
    catch { setError('保存に失敗しました。ギルドホームへは移動していません。') }
    finally { pending.current = false; setBusy(false) }
  }

  return <main ref={viewport} className="story-viewport">
    <div className="story-frame" data-testid="story-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        {frame.backgroundAssetId && <img className="story-background" alt="牢屋の背景" src={tutorialImage(frame.backgroundAssetId)} />}
        {Object.entries(frame.portraits).map(([slot, portrait]) => {
          const layout = content.layouts.find((entry) => entry.id === portrait.layoutId)!
          return <img key={slot} className="story-portrait" data-testid="story-portrait" alt="マチルダの立ち絵"
            data-layout-id={layout.id}
            src={tutorialImage(portrait.assetId)} style={{ left: layout.x, top: layout.y,
              transform: `translate(-50%, -50%) scale(${layout.flipped ? -layout.scale : layout.scale}, ${layout.scale})` }} />
        })}
        <header className="story-header">
          <h1>{storyId === MATILDA_STORY_ID ? 'マチルダのチュートリアル'
            : storyId === SUBEVENT1_JIN_STORY_ID ? 'サブイベント1：盗賊団討伐' : 'マチルダ通常戦'}</h1>
          <span className="story-checkpoint" data-testid="checkpoint-id">{frame.step.id}</span>
          <button onClick={onTitle} disabled={busy}>タイトルに戻る</button>
        </header>
        <aside className="story-reserved story-items">アイテムボックス<br /><small>表示機能は準備中</small></aside>
        {frame.step.kind === 'battle'
          ? content.battles.find((battle) => frame.step.kind === 'battle' && battle.id === frame.step.battle_id)?.hp
            ? <FixedBattle save={save} onSave={onSave} onBusy={setBusy} layouts={content.layouts} />
            : <TutorialBattle save={save} onSave={onSave} onBusy={setBusy} layouts={content.layouts} />
          : <CardPanel player={save.player} layouts={content.layouts} editDisabled={busy}
            onEdit={() => { if (!pending.current) setEditing(true) }} />}
        {editing && <DeckEditor save={save} onSave={onSave} onClose={() => setEditing(false)} />}
        {frame.step.kind !== 'battle' &&
        <section className="story-dialogue" aria-label="会話">
          {frame.step.kind === 'line' ? <>
            <p className="story-speaker">{frame.step.speaker_id === 'matilda' ? 'マチルダ' : frame.step.speaker_id ?? 'ナレーション'}</p>
            <p className="story-text" data-testid="story-text" aria-live="polite">{frame.text}</p>
            <button onClick={() => { void next() }} disabled={busy}>次へ</button>
          </> : <>
            {onEnd ? <>
              <h2>ジン戦パート終了</h2>
              <button disabled={busy} onClick={onEnd}>ギルドホームへ戻る</button>
            </> : <>
              <h2>{storyId === MATILDA_STORY_ID ? 'チュートリアル完了' : '通常戦の確認完了'}</h2>
              {storyId === MATILDA_STORY_ID
                ? <button disabled={busy} onClick={() => { void next('matilda.normal.start') }}>通常戦を試す</button>
                : <p>他の固定戦と本編への接続は後続段階で追加します。</p>}
            </>}
            {canEnterGuildHome(save) && <button disabled={busy || editing} onClick={() => { void openGuild() }}>ギルドホームを確認</button>}
          </>}
          {error && <p className="error-message" role="alert">{error}</p>}
        </section>}
      </div>
    </div>
  </main>
}
