import { useLayoutEffect, useMemo, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { nextStoryCheckpoint, startStory } from '../../../packages/story/runner'
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
import type { StoryTextVariables } from '../../../packages/story/runner'
import { getItemDefinition } from '../../../packages/domain/item-catalog'

const completionByStory: Readonly<Record<string, { flag: string; endingCheckpoint: string }>> = {
  [SUBEVENT1_JIN_STORY_ID]: { flag: 'sub1_cleared', endingCheckpoint: 'subevent1.belka.end' },
  'story.subevent2.post': { flag: 'sub2_cleared', endingCheckpoint: 'subevent2.post.end' },
  'story.subevent3.post': { flag: 'sub3_cleared', endingCheckpoint: 'subevent3.post.end' },
  'story.subevent4.post': { flag: 'sub4_cleared', endingCheckpoint: 'subevent4.post.end' },
  'story.stage2.close': { flag: 'stage2_complete', endingCheckpoint: 'stage2.close.end' },
  'story.stage3.post': { flag: 'stage3_complete', endingCheckpoint: 'stage3.post.end' },
  'story.stage4.post': { flag: 'stage4_complete', endingCheckpoint: 'stage4.post.end' },
  'story.stage5.post': { flag: 'stage5_complete', endingCheckpoint: 'stage5.post.end' },
  'story.stage6.post': { flag: 'stage6_complete', endingCheckpoint: 'stage6.post.end' },
  'story.stage7.epilogue': { flag: 'game_complete', endingCheckpoint: 'stage7.epilogue.end' }
}

export function StoryScreen({ save, onCheckpoint, onSave, onTitle, onEnd, content = matildaContent, storyId = MATILDA_STORY_ID,
  onRetry, textVariables = {} }: {
  save: SaveData
  onCheckpoint: (checkpointId: string) => Promise<void>
  onSave: (save: SaveData) => Promise<void>
  onTitle: () => void
  onEnd?: () => void
  onRetry?: () => Promise<void>
  content?: ContentPack
  storyId?: string
  textVariables?: StoryTextVariables
}) {
  const viewport = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [editing, setEditing] = useState(false)
  const frame = useMemo(() => startStory(content, storyId, save.progress.checkpoint_id, textVariables),
    [content, storyId, save.progress.checkpoint_id, textVariables])

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
      await onCheckpoint(checkpoint ?? nextStoryCheckpoint(content, storyId, frame))
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

  async function finish() {
    if (pending.current || !onEnd) return
    pending.current = true
    setBusy(true)
    setError('')
    try { if (alreadyCompleted) await onSave(enterGuildHome(save)); else await onEnd() }
    catch { setError('保存に失敗しました。場面は進んでいません。') }
    finally { pending.current = false; setBusy(false) }
  }

  async function retry() {
    if (pending.current || !onRetry) return
    pending.current = true
    setBusy(true)
    setError('')
    try { await onRetry() }
    catch { setError('保存に失敗しました。再挑戦は開始されていません。') }
    finally { pending.current = false; setBusy(false) }
  }

  const endTitle = storyId === 'story.prologue' ? 'プロローグ終了'
    : storyId === 'story.matilda.normal.loss' ? 'マチルダ通常戦：敗北'
    : storyId.startsWith('story.stage2.') ? 'レイラ編：場面終了'
    : storyId.startsWith('story.stage7.') ? '最終章：場面終了'
    : storyId.startsWith('story.stage6.') ? 'Stage 6：場面終了'
    : storyId.startsWith('story.stage5.') ? 'Stage 5：場面終了'
    : storyId.startsWith('story.stage4.') ? 'Stage 4：場面終了'
      : storyId.startsWith('story.stage3.') ? 'Stage 3：場面終了'
      : storyId.startsWith('story.subevent2.') ? 'サブイベント2：場面終了'
      : storyId.startsWith('story.subevent3.') ? 'サブイベント3：場面終了'
      : storyId.startsWith('story.subevent4.') ? 'サブイベント4：場面終了'
      : storyId === SUBEVENT1_JIN_STORY_ID
        ? frame.step.id === 'subevent1.belka.end' ? 'サブイベント1：討伐完了' : 'サブイベント1：戦闘終了'
        : 'ストーリー終了'
  const endAction = storyId === 'story.matilda.normal.loss' ? 'デッキを確認して再挑戦する'
    : storyId === 'story.prologue' ? 'チュートリアルへ進む'
    : storyId.startsWith('story.stage4.') ? storyId === 'story.stage4.recover' ? '魔力の調整訓練を始める'
    : storyId === 'story.stage4.post' ? '検証結果を保存してギルドへ戻る' : '次の場面へ'
    : storyId.startsWith('story.stage5.') ? storyId === 'story.stage5.recover' ? '尋問記録を照合する'
      : storyId === 'story.stage5.post' ? '再審結果を保存してギルドへ戻る' : '次の場面へ'
    : storyId.startsWith('story.stage7.') ? storyId === 'story.stage7.epilogue' ? 'エピローグを終える' : '次の場面へ'
      : storyId.startsWith('story.stage6.') ? storyId === 'story.stage6.post' ? '継承の記録を保存してギルドへ戻る' : '次の場面へ'
    : storyId.startsWith('story.stage3.') ? storyId === 'story.stage3.first' ? '証拠を照合する'
    : storyId === 'story.stage3.post' ? '審査結果を保存してギルドへ戻る' : '次の場面へ'
    : storyId.startsWith('story.stage2.') ? '次の場面へ'
    : storyId.startsWith('story.subevent3.') ? storyId === 'story.subevent3.visit' ? '水晶で呪いを調べる'
      : storyId === 'story.subevent3.post' ? 'ギルドへ戻る' : '次の場面へ'
      : storyId.startsWith('story.subevent4.') ? storyId === 'story.subevent4.post' ? '審査結果を確定してギルドへ戻る'
        : 'カード勝負へ進む'
    : 'ギルドホームへ戻る'
  const completion = completionByStory[storyId]
  const alreadyCompleted = frame.step.kind === 'end' && completion !== undefined &&
    frame.step.id === completion.endingCheckpoint && save.progress.flags.includes(completion.flag)

  return <main ref={viewport} className="story-viewport">
    <div className="story-frame" data-testid="story-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        {frame.backgroundAssetId && <img className="story-background" alt="ストーリー背景" src={tutorialImage(frame.backgroundAssetId)} />}
        {Object.entries(frame.portraits).map(([slot, portrait]) => {
          const layout = content.layouts.find((entry) => entry.id === portrait.layoutId)!
          const portraitName = slot === 'layla' ? 'レイラ' : slot === 'hero' ? 'サトシ' : slot
          return <img key={slot} className="story-portrait" data-testid="story-portrait" alt={`${portraitName}の立ち絵`}
            data-layout-id={layout.id}
            src={tutorialImage(portrait.assetId)} style={{ left: layout.x, top: layout.y,
              transform: `translate(-50%, -50%) scale(${layout.flipped ? -layout.scale : layout.scale}, ${layout.scale})` }} />
        })}
        <header className="story-header">
          <h1>{storyId === 'story.prologue' ? 'プロローグ'
            : storyId === MATILDA_STORY_ID ? 'マチルダのチュートリアル'
            : storyId === SUBEVENT1_JIN_STORY_ID ? 'サブイベント1：盗賊団討伐'
              : storyId.startsWith('story.stage7.') ? '最終章：王位継承とエピローグ'
                : storyId.startsWith('story.stage6.') ? 'Stage 6：王宮での公開検証'
                  : storyId.startsWith('story.stage5.') ? 'Stage 5：フェリアの再審'
                : storyId.startsWith('story.stage4.') ? 'Stage 4：セレスの魔法検証'
                : storyId.startsWith('story.stage3.') ? 'Stage 3：公開審査'
                : storyId.startsWith('story.stage2.') ? 'Stage 2：レイラ編'
                : storyId.startsWith('story.subevent2.') ? 'サブイベント2：教会の不正調査'
                  : storyId.startsWith('story.subevent3.') ? 'サブイベント3：呪われた鎧'
                    : storyId.startsWith('story.subevent4.') ? 'サブイベント4：公開審査'
                      : 'マチルダ通常戦'}</h1>
          <span className="story-checkpoint" data-testid="checkpoint-id">{frame.step.id}</span>
          <button onClick={onTitle} disabled={busy}>{storyId === 'story.matilda.normal.loss' ? 'ホームに戻る' : 'タイトルに戻る'}</button>
        </header>
        <aside className="story-reserved story-items" aria-label="所持アイテム" data-testid="story-items">
          <h2>所持アイテム</h2>
          {(save.player.items ?? []).length === 0 && (save.player.equipment ?? []).length === 0
            ? <p>アイテムなし</p>
            : <ul>{[...(save.player.items ?? []), ...(save.player.equipment ?? [])].map((id, index) => {
              const item = getItemDefinition(id)
              return <li key={`${id}-${index}`}><span>{item?.name ?? id}</span>
                {item?.category === 'equipment' && <small>装備中</small>}
                <small>{item?.description ?? ''}</small></li>
            })}</ul>}
        </aside>
        {frame.step.kind === 'battle'
          ? content.battles.find((battle) => frame.step.kind === 'battle' && battle.id === frame.step.battle_id)?.hp
            ? <FixedBattle save={save} battleId={frame.step.battle_id} onSave={onSave} onBusy={setBusy} layouts={content.layouts} />
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
            {onRetry ? <>
              <h2>{endTitle}</h2>
              <button disabled={busy} onClick={() => { void retry() }}>{endAction}</button>
            </> : onEnd ? <>
              <h2>{endTitle}</h2>
              <button disabled={busy} onClick={() => { void finish() }}>
                {alreadyCompleted ? 'ギルドホームへ戻る' : endAction}
              </button>
            </> : <>
              <h2>{storyId === MATILDA_STORY_ID ? 'チュートリアル完了'
                : storyId === 'story.matilda.normal' ? '通常戦終了' : 'ストーリー終了'}</h2>
              {storyId === MATILDA_STORY_ID
                ? <button disabled={busy} onClick={() => { void next('matilda.normal.start') }}>通常戦を試す</button>
                : <p>対戦結果は保存済みです。続きはギルドホームから選べます。</p>}
            </>}
            {canEnterGuildHome(save) && !(frame.step.kind === 'end' && onEnd) &&
              <button disabled={busy || editing} onClick={() => { void openGuild() }}>ギルドホームを確認</button>}
          </>}
          {error && <p className="error-message" role="alert">{error}</p>}
        </section>}
      </div>
    </div>
  </main>
}
