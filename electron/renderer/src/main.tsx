import { useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { createNewGameSave } from '../../../packages/domain/new-game'
import type { SaveData } from '../../../packages/domain/save'
import type { GameApi } from '../../preload/api'
import './style.css'
import { isMatildaCheckpoint, isStage2Checkpoint, normalContent, matildaContent, stage2Content,
  NORMAL_STORY_ID, MATILDA_STORY_ID, normalStoryForCheckpoint } from './matilda-content'
import { isFixedCheckpoint, retryFixedBattle } from '../../../packages/battle/fixed'
import { StoryScreen } from './StoryScreen'
import { GuildHome } from './GuildHome'
import { GUILD_CHECKPOINT } from '../../../packages/guild/routes'
import { BELKA_CHECKPOINT } from '../../../packages/battle/belka'
import { BelkaScreen } from './BelkaScreen'
import { Subevent1BelkaScreen } from './Subevent1BelkaScreen'
import { SUBEVENT1_BELKA_CHECKPOINT, SUBEVENT1_BELKA_END_CHECKPOINT, SUBEVENT1_BELKA_REPORT_CHECKPOINT, returnSubevent1BelkaToGuild,
  settleSubevent1Belka, startSubevent1Belka } from '../../../packages/battle/subevent1-belka'
import { JIN_CHECKPOINT, SUBEVENT1_JIN_CHECKPOINT, SUBEVENT1_MARCO_CHECKPOINT, SUBEVENT1_GALD_CHECKPOINT,
  SUBEVENT1_GALD_END_CHECKPOINT, SUBEVENT1_JIN_STORY_ID,
  isSubevent1JinStoryCheckpoint, prepareSubevent1Jin, prepareSubevent1Marco, prepareSubevent1Gald,
  returnSubevent1JinToGuild, returnSubevent1GaldToGuild, subevent1JinContent } from '../../../packages/battle/jin'
import { JinScreen } from './JinScreen'
import { RandomBattleScreen } from './RandomBattleScreen'
import { RANDOM_BATTLE_CHECKPOINT, TOWN_CHECKPOINT, TOWN_ENCOUNTER_CHECKPOINT } from '../../../packages/battle/random'
import { STAGE2_MINIGAME_CHECKPOINT, STAGE2_MINIGAME_END_CHECKPOINT } from '../../../packages/battle/stage2-minigame'
import { Stage2MinigameScreen } from './Stage2MinigameScreen'
import { finishStage2Story, stage2StoryForCheckpoint } from '../../../packages/battle/stage2'
import { STAGE2_MINIGAME_SCENES } from '../../../packages/battle/stage2-minigame'
import { completeSubevent2, isSubevent2Checkpoint, subevent2StoryForCheckpoint } from '../../../packages/battle/subevent2'
import { fixedContent } from '../../../packages/battle/fixed'
import { finishSubevent3Story, isSubevent3Checkpoint,
  subevent3StoryForCheckpoint } from '../../../packages/battle/subevent3'
import { SUBEVENT3_MINIGAME_CHECKPOINT, SUBEVENT3_MINIGAME_END } from '../../../packages/battle/subevent3-minigame'
import { Subevent3MinigameScreen } from './Subevent3MinigameScreen'
import { finishSubevent4Story, isSubevent4Checkpoint, subevent4StoryForCheckpoint } from '../../../packages/battle/subevent4'
import { finishStage3Story, isStage3Checkpoint, stage3StoryForCheckpoint } from '../../../packages/battle/stage3'
import { STAGE3_MINIGAME_CHECKPOINT, STAGE3_MINIGAME_END_CHECKPOINT } from '../../../packages/battle/stage3-minigame'
import { Stage3MinigameScreen } from './Stage3MinigameScreen'
import { finishStage4Story, isStage4Checkpoint, stage4StoryForCheckpoint } from '../../../packages/battle/stage4'
import { STAGE4_MINIGAME_CHECKPOINT, STAGE4_MINIGAME_END_CHECKPOINT } from '../../../packages/battle/stage4-minigame'
import { Stage4MinigameScreen } from './Stage4MinigameScreen'
import { finishStage5Story, isStage5Checkpoint, stage5StoryForCheckpoint } from '../../../packages/battle/stage5'
import { STAGE5_MINIGAME_CHECKPOINT, STAGE5_MINIGAME_END_CHECKPOINT } from '../../../packages/battle/stage5-minigame'
import { Stage5MinigameScreen } from './Stage5MinigameScreen'
import { finishStage6Story, isStage6Checkpoint, stage6StoryForCheckpoint } from '../../../packages/battle/stage6'
import { finishStage7Story, isStage7Checkpoint, stage7StoryForCheckpoint } from '../../../packages/battle/stage7'
import { finishPrologue, isPrologueCheckpoint, PROLOGUE_STORY_ID } from '../../../packages/story/prologue'
import { prologueContent } from './matilda-content'

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

  if (active) {
    if (isPrologueCheckpoint(active.progress.checkpoint_id)) {
      return <StoryScreen save={active} content={prologueContent} storyId={PROLOGUE_STORY_ID}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave); setSaved(nextSave); setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave); setSaved(nextSave); setActive(nextSave)
        }} onEnd={async () => {
          const nextSave = finishPrologue(active)
          await game.save.write(nextSave); setSaved(nextSave); setActive(nextSave)
        }} />
    }
    if (isSubevent2Checkpoint(active.progress.checkpoint_id)) {
      const storyId = subevent2StoryForCheckpoint(active.progress.checkpoint_id)
      if (!storyId) throw new Error(`Unknown Subevent 2 checkpoint: ${active.progress.checkpoint_id}`)
      return <StoryScreen save={active} content={fixedContent} storyId={storyId}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onEnd={storyId === 'story.subevent2.post' ? async () => {
          const nextSave = completeSubevent2(active)
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        } : undefined} />
    }
    if ([SUBEVENT3_MINIGAME_CHECKPOINT, SUBEVENT3_MINIGAME_END].includes(active.progress.checkpoint_id)) {
      return <Subevent3MinigameScreen save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (isSubevent3Checkpoint(active.progress.checkpoint_id)) {
      const storyId = subevent3StoryForCheckpoint(active.progress.checkpoint_id)
      if (!storyId) throw new Error(`Unknown Subevent 3 checkpoint: ${active.progress.checkpoint_id}`)
      return <StoryScreen save={active} content={fixedContent} storyId={storyId}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onEnd={async () => {
          const nextSave = finishSubevent3Story(active, storyId, Array.from({ length: 4 }, () => Math.random()))
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} />
    }
    if ([STAGE2_MINIGAME_CHECKPOINT, STAGE2_MINIGAME_END_CHECKPOINT].includes(active.progress.checkpoint_id)) {
      return <Stage2MinigameScreen save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (isSubevent4Checkpoint(active.progress.checkpoint_id)) {
      const storyId = subevent4StoryForCheckpoint(active.progress.checkpoint_id)
      if (!storyId) throw new Error(`Unknown Subevent 4 checkpoint: ${active.progress.checkpoint_id}`)
      return <StoryScreen save={active} content={fixedContent} storyId={storyId}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onEnd={async () => {
          const nextSave = finishSubevent4Story(active, storyId)
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} />
    }
    if ([STAGE3_MINIGAME_CHECKPOINT, STAGE3_MINIGAME_END_CHECKPOINT].includes(active.progress.checkpoint_id)) {
      return <Stage3MinigameScreen save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (isStage3Checkpoint(active.progress.checkpoint_id)) {
      const storyId = stage3StoryForCheckpoint(active.progress.checkpoint_id)
      if (!storyId) throw new Error(`Unknown Stage 3 checkpoint: ${active.progress.checkpoint_id}`)
      return <StoryScreen save={active} content={fixedContent} storyId={storyId}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onEnd={async () => {
          const nextSave = finishStage3Story(active, storyId,
            storyId === 'story.stage3.first' ? Array.from({ length: 9 }, () => Math.random()) : undefined)
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} />
    }
    if ([STAGE4_MINIGAME_CHECKPOINT, STAGE4_MINIGAME_END_CHECKPOINT].includes(active.progress.checkpoint_id)) {
      return <Stage4MinigameScreen save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (isStage4Checkpoint(active.progress.checkpoint_id)) {
      const storyId = stage4StoryForCheckpoint(active.progress.checkpoint_id)
      if (!storyId) throw new Error(`Unknown Stage 4 checkpoint: ${active.progress.checkpoint_id}`)
      return <StoryScreen save={active} content={fixedContent} storyId={storyId}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onEnd={async () => {
          const nextSave = finishStage4Story(active, storyId)
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
      }} />
    }
    if ([STAGE5_MINIGAME_CHECKPOINT, STAGE5_MINIGAME_END_CHECKPOINT].includes(active.progress.checkpoint_id)) {
      return <Stage5MinigameScreen save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (isStage5Checkpoint(active.progress.checkpoint_id)) {
      const storyId = stage5StoryForCheckpoint(active.progress.checkpoint_id)
      if (!storyId) throw new Error(`Unknown Stage 5 checkpoint: ${active.progress.checkpoint_id}`)
      return <StoryScreen save={active} content={fixedContent} storyId={storyId}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onEnd={async () => {
          const nextSave = finishStage5Story(active, storyId)
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
      }} />
    }
    if (isStage6Checkpoint(active.progress.checkpoint_id)) {
      const storyId = stage6StoryForCheckpoint(active.progress.checkpoint_id)
      if (!storyId) throw new Error(`Unknown Stage 6 checkpoint: ${active.progress.checkpoint_id}`)
      return <StoryScreen save={active} content={fixedContent} storyId={storyId}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave); setSaved(nextSave); setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave); setSaved(nextSave); setActive(nextSave)
        }} onEnd={async () => {
          const nextSave = finishStage6Story(active, storyId)
          await game.save.write(nextSave); setSaved(nextSave); setActive(nextSave)
        }} />
    }
    if (isStage7Checkpoint(active.progress.checkpoint_id)) {
      const storyId = stage7StoryForCheckpoint(active.progress.checkpoint_id)
      if (!storyId) throw new Error(`Unknown Stage 7 checkpoint: ${active.progress.checkpoint_id}`)
      return <StoryScreen save={active} content={fixedContent} storyId={storyId}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave); setSaved(nextSave); setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave); setSaved(nextSave); setActive(nextSave)
        }} onEnd={async () => {
          const nextSave = finishStage7Story(active, storyId)
          await game.save.write(nextSave); setSaved(nextSave); setActive(nextSave)
        }} />
    }
    if (isStage2Checkpoint(active.progress.checkpoint_id)) {
      const storyId = stage2StoryForCheckpoint(active.progress.checkpoint_id)
      if (!storyId) throw new Error(`Unknown Stage 2 checkpoint: ${active.progress.checkpoint_id}`)
      return <StoryScreen save={active} content={stage2Content} storyId={storyId}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onEnd={async () => {
          const sceneOrder = storyId === 'story.stage2.recover'
            ? Array.from({ length: STAGE2_MINIGAME_SCENES.length }, (_, index) => index)
            : undefined
          if (sceneOrder) {
            for (let index = sceneOrder.length - 1; index > 0; index--) {
              const swap = Math.floor(Math.random() * (index + 1))
              ;[sceneOrder[index], sceneOrder[swap]] = [sceneOrder[swap]!, sceneOrder[index]!]
            }
          }
          const nextSave = finishStage2Story(active, storyId, sceneOrder)
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} />
    }
    if ([TOWN_CHECKPOINT, TOWN_ENCOUNTER_CHECKPOINT, RANDOM_BATTLE_CHECKPOINT].includes(active.progress.checkpoint_id)) {
      return <RandomBattleScreen save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (active.progress.checkpoint_id === SUBEVENT1_BELKA_CHECKPOINT) {
      return <Subevent1BelkaScreen save={active} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (active.progress.checkpoint_id === JIN_CHECKPOINT || active.progress.checkpoint_id === SUBEVENT1_JIN_CHECKPOINT ||
        active.progress.checkpoint_id === SUBEVENT1_MARCO_CHECKPOINT || active.progress.checkpoint_id === SUBEVENT1_GALD_CHECKPOINT) {
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
      const normalStoryId = normalStoryForCheckpoint(active.progress.checkpoint_id)
      const normal = normalStoryId !== undefined || isFixedCheckpoint(active.progress.checkpoint_id)
      const storyId = normalStoryId ?? (normal ? NORMAL_STORY_ID : MATILDA_STORY_ID)
      return <StoryScreen save={active} content={normal ? normalContent : matildaContent}
        storyId={storyId} onTitle={() => setActive(null)} onSave={async (nextSave) => {
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} onRetry={storyId === 'story.matilda.normal.loss' ? async () => {
        const nextSave = retryFixedBattle(active)
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      } : undefined} onCheckpoint={async (checkpointId) => {
        const nextSave: SaveData = { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
        await game.save.write(nextSave)
        setSaved(nextSave)
        setActive(nextSave)
      }} />
    }
    if (isSubevent1JinStoryCheckpoint(active.progress.checkpoint_id)) {
      return <StoryScreen save={active} content={subevent1JinContent} storyId={SUBEVENT1_JIN_STORY_ID}
        textVariables={active.progress.subevent1_belka_battle?.gold_delta === undefined ? {}
          : { belkaRewardGold: active.progress.subevent1_belka_battle.gold_delta }}
        onTitle={() => setActive(null)} onSave={async (nextSave) => {
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onCheckpoint={async (checkpointId) => {
          let nextSave = checkpointId === SUBEVENT1_JIN_CHECKPOINT
            ? prepareSubevent1Jin(active)
            : checkpointId === SUBEVENT1_MARCO_CHECKPOINT
              ? prepareSubevent1Marco(active)
              : checkpointId === SUBEVENT1_GALD_CHECKPOINT
                ? prepareSubevent1Gald(active)
                : checkpointId === SUBEVENT1_BELKA_CHECKPOINT
                  ? startSubevent1Belka(active)
            : { ...active, progress: { ...active.progress, checkpoint_id: checkpointId } }
          if (checkpointId === SUBEVENT1_BELKA_REPORT_CHECKPOINT && !nextSave.progress.subevent1_belka_battle?.settled) {
            nextSave = settleSubevent1Belka(nextSave, Math.random())
          }
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} onEnd={async () => {
          const nextSave = active.progress.checkpoint_id === SUBEVENT1_BELKA_END_CHECKPOINT
            ? returnSubevent1BelkaToGuild(active)
            : active.progress.checkpoint_id === SUBEVENT1_GALD_END_CHECKPOINT
              ? returnSubevent1GaldToGuild(active) : returnSubevent1JinToGuild(active)
          await game.save.write(nextSave)
          setSaved(nextSave)
          setActive(nextSave)
        }} />
    }
    return <main className="game-screen">
      <div className="checkpoint-panel">
        <p className="eyebrow">Janken Kingdom</p>
        <h1>保存地点</h1>
        <p>この保存地点に対応する画面はありません。タイトルへ戻り、対応済みの保存地点から再開してください。</p>
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
