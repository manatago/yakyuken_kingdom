import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { hasValidNineCardDeck } from '../../../packages/domain/deck'
import { leaveGuildHome } from '../../../packages/guild/home'
import { canStartBelka, startBelka } from '../../../packages/battle/belka'
import { guildHomeContent } from '../../../packages/guild/routes'
import { fitViewport } from '../../../packages/story/viewport'
import guildBackground from '../../../godot/assets/backgrounds/stage1/bg07_st1_001.png?url'
import { CardPanel } from './CardPanel'
import { CardView } from './CardView'
import { DeckEditor } from './DeckEditor'
import { canStartJin, canStartSubevent1Jin, setJinDraft, startJin, startSubevent1JinStory } from '../../../packages/battle/jin'
import { cardPresentation } from '../../../packages/cards/presentation'
import { getItemDefinition } from '../../../packages/domain/item-catalog'
import { equipItem, unequipItem } from '../../../packages/domain/equipment'
import { canEnterTown, enterTown, townContent } from '../../../packages/battle/random'
import { ADVENTURER_TUTORIAL_COMPLETE, advanceAdventurerTutorial, buildAdventurerTutorialDeck,
  canStartAdventurerTutorial, completeAdventurerTutorial, playAdventurerTutorialBattle,
  startAdventurerTutorial } from '../../../packages/battle/adventurer-tutorial'
import { getSubeventUnlockState, SUBEVENT_COMPLETION_FLAGS, SUBEVENT_RANDOM_BATTLE_REQUIREMENT, type SubeventId } from '../../../packages/domain/progression'
import { canRetryStage2Battle, canStartStage2, startStage2 } from '../../../packages/battle/stage2'
import { canRetryStage3Battle, canStartStage3, startStage3 } from '../../../packages/battle/stage3'
import { canRetryStage4Battle, canStartStage4, startStage4 } from '../../../packages/battle/stage4'
import { canRetryStage5Battle, canStartStage5, startStage5 } from '../../../packages/battle/stage5'
import { canRetryStage6Battle, canStartStage6, startStage6 } from '../../../packages/battle/stage6'
import { canStartStage7, startStage7 } from '../../../packages/battle/stage7'
import { canRetrySubevent2, canStartSubevent2, startSubevent2 } from '../../../packages/battle/subevent2'
import { retryFixedBattle } from '../../../packages/battle/fixed'
import { canRetrySubevent3Battle, canRetrySubevent3Minigame, canStartSubevent3, retrySubevent3Minigame, startSubevent3 } from '../../../packages/battle/subevent3'
import { canStartSubevent4, startSubevent4 } from '../../../packages/battle/subevent4'

const subeventBoard: readonly { id: SubeventId; title: string }[] = [
  { id: 'subevent1', title: '盗賊団を解体せよ！' },
  { id: 'subevent2', title: '教会の不正を暴け！' },
  { id: 'subevent3', title: '呪われた鎧を脱がせ！' },
  { id: 'subevent4', title: '次の依頼' }
]

const backgrounds: Record<string, string> = {
  'godot/assets/backgrounds/stage1/bg07_st1_001.png': guildBackground
}
const background = backgrounds[guildHomeContent.background]
if (!background) throw new Error('Unknown guild home background')

export function GuildHome({ save, onSave, onTitle }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onTitle: () => void
}) {
  const viewport = useRef<HTMLElement>(null)
  const guildNotice = useRef<HTMLElement>(null)
  const questBoard = useRef<HTMLElement>(null)
  const itemInventory = useRef<HTMLElement>(null)
  const equipmentInventory = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [cardsOpen, setCardsOpen] = useState(false)
  const [editing, setEditing] = useState(false)
  const [townSelectionOpen, setTownSelectionOpen] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const jinDraft = save.progress.jin_draft ?? []
  const retryDeck = save.player.prepared_deck ?? save.player.deck
  const retryDeckIsValid = hasValidNineCardDeck(save.player.inventory, retryDeck)
  const fixedChapterReady = retryDeckIsValid && save.player.inventory.length >= 12
  useLayoutEffect(() => {
    const element = viewport.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize()
    const observer = new ResizeObserver(resize)
    observer.observe(element)
    return () => observer.disconnect()
  }, [])

  async function returnToConfirmation() {
    if (pending.current || editing) return
    pending.current = true
    setBusy(true)
    setError('')
    try { await onSave(leaveGuildHome(save)) }
    catch { setError('保存に失敗しました。ギルドホームに留まっています。') }
    finally { pending.current = false; setBusy(false) }
  }

  async function openBelka() {
    if (pending.current || editing || !canStartBelka(save)) return
    pending.current = true
    setBusy(true)
    setError('')
    try { await onSave(startBelka(save)) }
    catch { setError('保存に失敗しました。ベルカ戦は開始していません。') }
    finally { pending.current = false; setBusy(false) }
  }

  async function saveJinDraft(nextDraft: typeof jinDraft) {
    if (pending.current || busy || editing) return
    pending.current = true; setBusy(true); setError('')
    try { await onSave(setJinDraft(save, nextDraft)) }
    catch { setError('保存に失敗しました。カード選択は変更されていません。') }
    finally { pending.current = false; setBusy(false) }
  }

  async function updateEquipment(operation: () => SaveData) {
    if (pending.current || editing) return
    pending.current = true; setBusy(true); setError('')
    try { await onSave(operation()) }
    catch { setError('保存に失敗しました。装備は変更されていません。') }
    finally { pending.current = false; setBusy(false) }
  }

  async function addJinCard(card: (typeof save.player.inventory)[number]) {
    if (jinDraft.length >= 3) return
    const key = `${card.hand}:${card.grade}`
    const selectedCount = jinDraft.filter((entry) => `${entry.hand}:${entry.grade}` === key).length
    const ownedCount = save.player.inventory.filter((entry) => `${entry.hand}:${entry.grade}` === key).length
    if (selectedCount >= ownedCount) return
    await saveJinDraft([...jinDraft, card])
  }

  async function launchJin() {
    if (pending.current || editing || jinDraft.length !== 3) return
    pending.current = true; setBusy(true); setError('')
    try { await onSave(startJin(save)) }
    catch { setError('保存に失敗しました。ジン戦は開始していません。') }
    finally { pending.current = false; setBusy(false) }
  }

  async function launchSubevent1() {
    if (pending.current || editing || jinDraft.length !== 3 || !canStartSubevent1Jin(save)) return
    pending.current = true; setBusy(true); setError('')
    try { await onSave(startSubevent1JinStory(save, jinDraft)) }
    catch { setError('保存に失敗しました。サブイベント1は開始していません。') }
    finally { pending.current = false; setBusy(false) }
  }

  async function exploreTown(areaId: string) {
    if (pending.current || editing || !canEnterTown(save)) return
    pending.current = true; setBusy(true); setError('')
    try { await onSave(enterTown(save, areaId, { encounter: Math.random(), opponent: Math.random(), dialogue: [Math.random(), Math.random(), Math.random(), Math.random()],
      cards: Array.from({ length: 3 }, () => ({ hand: Math.random(), grade: Math.random() })) as [
        { hand: number; grade: number }, { hand: number; grade: number }, { hand: number; grade: number }
      ], drop: Math.random() })) }
    catch { setError('保存に失敗しました。街へは移動していません。') }
    finally { pending.current = false; setBusy(false) }
  }

  async function tutorialAction(operation: () => SaveData) {
    if (pending.current || editing) return
    pending.current = true; setBusy(true); setError('')
    try { await onSave(operation()) }
    catch { setError('チュートリアルを保存できませんでした。進行状況は変わっていません。') }
    finally { pending.current = false; setBusy(false) }
  }

  function scrollGuildTo(target: { current: HTMLElement | null }) {
    if (guildNotice.current && target.current) target.current.scrollIntoView({ block: 'start', behavior: 'smooth' })
  }

  return <main ref={viewport} className="story-viewport" aria-label="ギルドホーム">
    <div className="story-frame" data-testid="guild-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage guild-stage" style={{ transform: `scale(${fit.scale})` }}>
        <img className="story-background" data-testid="guild-background" alt="ギルド内の背景" src={background} />
        <header className="story-header">
          <h1>{guildHomeContent.title}</h1>
          <span>所持金 {save.player.money} G</span>
          <span className="story-checkpoint" data-testid="checkpoint-id">{save.progress.checkpoint_id}</span>
          <button disabled={busy || editing} onClick={() => { void returnToConfirmation() }}>確認画面へ戻る</button>
        </header>
        {cardsOpen ? <>
          <CardPanel player={save.player} layouts={guildHomeContent.layouts} onEdit={() => setEditing(true)} editDisabled={busy || editing} />
          <button className="guild-close-cards" disabled={busy || editing} onClick={() => setCardsOpen(false)}>カード表示を閉じる</button>
        </> : <section ref={guildNotice} className="guild-notice">
          <p>冒険者ギルドのホームです。カード編成や所持品を整え、依頼を進めます。</p>
          <p>クエストボードで解放条件を確認できます。現在の仮設定では、冒険者チュートリアル後にランダム戦を累計{SUBEVENT_RANDOM_BATTLE_REQUIREMENT}回経験するとサブイベント1が解放されます。</p>
          {canStartAdventurerTutorial(save) && <button disabled={busy} onClick={() => { void tutorialAction(() => startAdventurerTutorial(save)) }}>冒険者チュートリアルを始める</button>}
          {save.progress.adventurer_tutorial && <section aria-label="冒険者チュートリアル" data-testid="adventurer-tutorial">
            <h2>冒険者チュートリアル {save.progress.adventurer_tutorial.step + 1}/4</h2>
            {save.progress.adventurer_tutorial.step === 0 ? <>
              <p>冒険者Aとのランダム戦を通して、HP1・3枚デッキ・ベイズ・アイによる予測勝ちを学びます。1敗で終了し、3回引き分けても決着がつかなければドローです。</p>
              <button disabled={busy} onClick={() => { void tutorialAction(() => advanceAdventurerTutorial(save)) }}>ルールを確認した</button>
            </> : save.progress.adventurer_tutorial.step === 1 ? <>
              <p>練習用デッキはグー・チョキ・パーのNormalカード各1枚です。現在のデッキは書き換えず、画面上の練習だけで使用します。</p>
              <div className="adventurer-practice-deck" aria-label="練習用の3枚">
                <CardView card={{ hand: 'rock', grade: 1 }} />
                <CardView card={{ hand: 'scissors', grade: 1 }} />
                <CardView card={{ hand: 'paper', grade: 1 }} />
              </div>
              <button disabled={busy} onClick={() => { void tutorialAction(() => buildAdventurerTutorialDeck(save)) }}>練習デッキを組む</button>
            </> : save.progress.adventurer_tutorial.step === 2 ? <>
              <p>冒険者AはNormalのグー2枚・パー1枚。グーを出しやすい相手です。相手の初手はグーに固定されます。パーを選ぶと勝ちます。</p>
              <div className="tutorial-showdown" aria-label="冒険者チュートリアルの勝負カード">
                <div>あなた<CardView card={{ hand: 'paper', grade: 1 }} compact={false} /></div>
                <div>冒険者A<CardView card={{ hand: 'rock', grade: 1 }} compact={false} /></div>
              </div>
              <button disabled={busy} onClick={() => { void tutorialAction(() => playAdventurerTutorialBattle(save)) }}>パーでグーに勝負</button>
            </> : <>
              <p>勝利！ 相手のデッキ情報と傾向を見て、最も確率の高い手に勝つカードを選ぶのが「予測勝ち」です。</p>
              <button disabled={busy} onClick={() => { void tutorialAction(() => completeAdventurerTutorial(save)) }}>チュートリアルを終える</button>
            </>}
          </section>}
          {save.progress.flags.includes(ADVENTURER_TUTORIAL_COMPLETE) && <p data-testid="adventurer-tutorial-complete">冒険者チュートリアル完了</p>}
          {save.progress.flags.includes(ADVENTURER_TUTORIAL_COMPLETE) && <p data-testid="random-battle-count">ランダム戦の経験 {save.progress.random_battles_completed ?? 0}/{SUBEVENT_RANDOM_BATTLE_REQUIREMENT}</p>}
          <section ref={questBoard} aria-label="クエストボード" data-testid="subevent-board">
            <h2>クエストボード</h2>
            {!retryDeckIsValid && <p data-testid="nine-card-deck-required">固定戦のある依頼・本編には、所持カードから有効な9枚のデッキが必要です。カードが足りない場合は、街のランダム戦で集めてください。</p>}
            <ol>{subeventBoard.map(({ id, title }) => {
              const state = getSubeventUnlockState(id, save.progress.flags, save.progress.random_battles_completed ?? 0)
              const completed = save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS[id])
              const implemented = id === 'subevent1' || id === 'subevent2' || id === 'subevent3' || id === 'subevent4'
              const needsNineCards = id !== 'subevent1'
              const status = completed ? '完了' : !state.unlocked ? `未解放：${state.reasons.join('、')}`
                : needsNineCards && !retryDeckIsValid ? '解放済み：所持カードから9枚のデッキが必要'
                  : implemented ? '受注可能' : '解放条件達成・本編未移植'
              return <li key={id} data-testid={`quest-${id}`} data-unlocked={state.unlocked}>
                <span>{title}</span><span>{status}</span>
                {id === 'subevent2' && canStartSubevent2(save) && <button disabled={busy}
                  onClick={() => { void tutorialAction(() => startSubevent2(save)) }}>教会編を開始</button>}
                {id === 'subevent2' && canRetrySubevent2(save) && <button disabled={busy || !retryDeckIsValid}
                  onClick={() => { void tutorialAction(() => retryFixedBattle(save)) }}>教会編を再開</button>}
                {id === 'subevent2' && canRetrySubevent2(save) && !retryDeckIsValid &&
                  <span>再戦には所持カードから9枚のデッキを編成してください。</span>}
                {id === 'subevent3' && canStartSubevent3(save) && <button disabled={busy}
                  onClick={() => { void tutorialAction(() => startSubevent3(save)) }}>フィオナ編を開始</button>}
                {id === 'subevent3' && canRetrySubevent3Minigame(save) && <button disabled={busy}
                  onClick={() => { void tutorialAction(() => retrySubevent3Minigame(save, Array.from({ length: 4 }, () => Math.random()))) }}>水晶調査を再開</button>}
                {id === 'subevent3' && canRetrySubevent3Battle(save) && <button disabled={busy || !retryDeckIsValid}
                  onClick={() => { void tutorialAction(() => retryFixedBattle(save)) }}>フィオナ戦を再開</button>}
                {id === 'subevent3' && canRetrySubevent3Battle(save) && !retryDeckIsValid &&
                  <span>再戦には所持カードから9枚のデッキを編成してください。</span>}
                {id === 'subevent4' && canStartSubevent4(save) && <button disabled={busy}
                  onClick={() => { void tutorialAction(() => startSubevent4(save)) }}>審査を開始</button>}
              </li>
            })}</ol>
          </section>
          <section aria-label="本編" data-testid="main-story-board">
            <h2>本編</h2>
            {save.player.inventory.length < 12 && <p data-testid="chapter-card-reserve-required">本編の初戦は物語上の敗北となりカードを3枚失います。開始には9枚のデッキに加えて予備カード3枚が必要です。街のランダム戦でカードを集めてください。</p>}
            {save.progress.flags.includes('stage2_complete') ? <p data-testid="stage2-complete">レイラ編：完了</p>
              : canStartStage2(save) ? <button disabled={busy} onClick={() => { void tutorialAction(() => startStage2(save)) }}>レイラ編を始める</button>
                : save.progress.flags.includes('stage2.started') ? <p>レイラ編：進行中。検証に敗北し、ギルドへ戻りました。</p>
                  : save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent2) && !fixedChapterReady
                    ? <p>レイラ編：開始には有効な9枚の対戦用デッキと予備カード3枚が必要です。</p>
                  : <p>レイラ編：サブイベント2を完了すると開始できます。</p>}
            {canRetryStage2Battle(save) && <button disabled={busy || !retryDeckIsValid}
              onClick={() => { void tutorialAction(() => retryFixedBattle(save)) }}>レイラとの再戦を再開</button>}
            {canRetryStage2Battle(save) && !retryDeckIsValid &&
              <span>再戦には所持カードから9枚のデッキを編成してください。</span>}
            {save.progress.flags.includes('stage3_complete') ? <p data-testid="stage3-complete">Stage 3：完了</p>
              : canStartStage3(save) ? <button disabled={busy} onClick={() => { void tutorialAction(() => startStage3(save)) }}>Stage 3・公開審査を始める</button>
                : save.progress.flags.includes('stage3.started') ? <p>Stage 3：公開審査を進行中です。</p>
                  : save.progress.flags.includes('stage2_complete') && !fixedChapterReady
                    ? <p>Stage 3：開始には有効な9枚の対戦用デッキと予備カード3枚が必要です。</p>
                  : null}
            {canRetryStage3Battle(save) && <button disabled={busy || !retryDeckIsValid}
              onClick={() => { void tutorialAction(() => retryFixedBattle(save)) }}>マグダレナ戦を再開</button>}
            {canRetryStage3Battle(save) && !retryDeckIsValid &&
              <span>再戦には所持カードから9枚のデッキを編成してください。</span>}
            {save.progress.flags.includes('stage4_complete') ? <p data-testid="stage4-complete">Stage 4：完了</p>
              : canStartStage4(save) ? <button disabled={busy} onClick={() => { void tutorialAction(() => startStage4(save)) }}>Stage 4・魔法師団の検証を始める</button>
                : save.progress.flags.includes('stage4.started') ? <p>Stage 4：魔法師団の検証を進行中です。</p>
                  : save.progress.flags.includes('stage3_complete') && !fixedChapterReady
                    ? <p>Stage 4：開始には有効な9枚の対戦用デッキと予備カード3枚が必要です。</p>
                  : null}
            {canRetryStage4Battle(save) && <button disabled={busy || !retryDeckIsValid}
              onClick={() => { void tutorialAction(() => retryFixedBattle(save)) }}>セレス戦を再開</button>}
            {canRetryStage4Battle(save) && !retryDeckIsValid &&
              <span>再戦には所持カードから9枚のデッキを編成してください。</span>}
            {save.progress.flags.includes('stage5_complete') ? <p data-testid="stage5-complete">Stage 5：完了</p>
              : canStartStage5(save) ? <button disabled={busy} onClick={() => { void tutorialAction(() => startStage5(save)) }}>Stage 5・フェリアの事情聴取へ</button>
                : save.progress.flags.includes('stage5.started') ? <p>Stage 5：再審の手続き中です。</p>
                  : save.progress.flags.includes('stage4_complete') && !fixedChapterReady
                    ? <p>Stage 5：開始には有効な9枚の対戦用デッキと予備カード3枚が必要です。</p>
                  : null}
            {canRetryStage5Battle(save) && <button disabled={busy || !retryDeckIsValid}
              onClick={() => { void tutorialAction(() => retryFixedBattle(save)) }}>フェリア戦を再開</button>}
            {canRetryStage5Battle(save) && !retryDeckIsValid &&
              <span>再戦には所持カードから9枚のデッキを編成してください。</span>}
            {save.progress.flags.includes('stage6_complete') ? <p data-testid="stage6-complete">Stage 6：完了</p>
              : canStartStage6(save) ? <button disabled={busy} onClick={() => { void tutorialAction(() => startStage6(save)) }}>Stage 6・王宮晩餐会へ</button>
                : save.progress.flags.includes('stage6.started') ? <p>Stage 6：公開審査を進行中です。</p>
                  : save.progress.flags.includes('stage5_complete') && !fixedChapterReady
                    ? <p>Stage 6：開始には有効な9枚の対戦用デッキと予備カード3枚が必要です。</p>
                  : null}
            {canRetryStage6Battle(save) && <button disabled={busy || !retryDeckIsValid}
              onClick={() => { void tutorialAction(() => retryFixedBattle(save)) }}>アレクシア戦を再開</button>}
            {canRetryStage6Battle(save) && !retryDeckIsValid &&
              <span>再戦には所持カードから9枚のデッキを編成してください。</span>}
            {save.progress.flags.includes('game_complete') ? <p data-testid="game-complete">ゲームクリア：王位継承とエピローグ完了</p>
              : canStartStage7(save) && <button disabled={busy} onClick={() => { void tutorialAction(() => startStage7(save)) }}>最終章・エピローグを見る</button>}
          </section>
          {canStartBelka(save) && <details className="guild-verification" data-testid="belka-verification-disclosure">
            <summary>開発用のベルカ検証戦</summary>
            <button disabled={busy} onClick={() => { void openBelka() }}>ベルカ戦を確認</button>
          </details>}
          {canEnterTown(save) && <button disabled={busy} onClick={() => setTownSelectionOpen(true)}>ランダム戦の街へ</button>}
          <section ref={itemInventory} aria-label="所持アイテム" data-testid="item-inventory">
            <h2>所持アイテム</h2>
            {(save.player.items ?? []).length === 0 ? <p>所持アイテムはありません。</p> : <ul>{(save.player.items ?? []).map((id, index) => {
              const item = getItemDefinition(id)
              return <li key={`${id}-${index}`}>{item?.name ?? id} — {item?.description}
                {item?.category === 'equipment' && <button disabled={busy} aria-label={`装備 ${item.name}`}
                  onClick={() => { void updateEquipment(() => equipItem(save, id)) }}>装備する</button>}
              </li>
            })}</ul>}
          </section>
          <section ref={equipmentInventory} aria-label="装備中アイテム" data-testid="equipment-inventory">
            <h2>装備中</h2>
            {(save.player.equipment ?? []).length === 0 ? <p>装備中のアイテムはありません。</p> : <ul>{(save.player.equipment ?? []).map((id, index) => {
              const item = getItemDefinition(id)
              return <li key={`${id}-${index}`}>{item?.name ?? id} — {item?.description}
                <button disabled={busy} aria-label={`外す ${item?.name ?? id}`}
                  onClick={() => { void updateEquipment(() => unequipItem(save, id)) }}>装備を外す</button>
              </li>
            })}</ul>}
          </section>
          {(canStartJin(save) || canStartSubevent1Jin(save)) && <details className="guild-verification" open={canStartSubevent1Jin(save)}
            data-testid="jin-draft-disclosure">
            <summary>{canStartSubevent1Jin(save) ? 'サブイベント1の受注・デッキ準備' : '開発用の検証戦'}</summary>
            <section aria-label="ジン戦カード選択" data-testid="jin-draft">
            <h2>{canStartJin(save) ? 'ジン戦（確認用）' : 'サブイベント1・ジン戦'}</h2>
            <p>所持カードから3枚を選び、順番を決めます。選択済み {jinDraft.length}/3</p>
            <div className="deck-grid">{save.player.inventory.map((card, index) => {
              const presentation = cardPresentation(card)
              const same = jinDraft.filter((entry) => entry.hand === card.hand && entry.grade === card.grade).length
              const countThrough = save.player.inventory.slice(0, index + 1).filter((entry) => entry.hand === card.hand && entry.grade === card.grade).length
              return <button key={index} disabled={busy || jinDraft.length >= 3 || countThrough <= same}
                aria-label={`ジン戦に追加 ${presentation.handLabel} ${presentation.gradeLabel} ${index + 1}`}
                onClick={() => { void addJinCard(card) }}>{presentation.handLabel} {presentation.gradeLabel}</button>
            })}</div>
            <button disabled={busy || jinDraft.length === 0} onClick={() => { void saveJinDraft(jinDraft.slice(0, -1)) }}>最後のカードを外す</button>
            {canStartJin(save) && <button disabled={busy || jinDraft.length !== 3} onClick={() => { void launchJin() }}>3枚でジン戦を開始</button>}
            <button disabled={busy || jinDraft.length !== 3 || !canStartSubevent1Jin(save)}
              onClick={() => { void launchSubevent1() }}>サブイベント1を開始</button>
            </section>
          </details>}
          {save.progress.belka_battle?.settled && <p data-testid="belka-verification-settled">検証用ベルカ戦の結果は保存済みです。物語本編のベルカ戦はサブイベント1から開始できます。</p>}
        </section>}
        {townSelectionOpen && canEnterTown(save) && <section className="town-destination-picker" role="dialog" aria-modal="true"
          aria-label="街の行き先" data-testid="town-destination-picker">
          <h2>どこに行く？</h2>
          <div>{townContent.homeConnections.map((areaId) => {
            const destination = townContent.areas[areaId as keyof typeof townContent.areas]
            return <button key={areaId} disabled={busy} onClick={() => { void exploreTown(areaId) }}>{destination.name}へ出る</button>
          })}</div>
          <button disabled={busy} onClick={() => setTownSelectionOpen(false)}>戻る</button>
        </section>}
        {error && <p role="alert" className="guild-error error-message">{error}</p>}
        <nav className="guild-menu" aria-label="ギルドメニュー">
          {guildHomeContent.menu.map((entry) => {
            const available = ['cards', 'title', 'quests', 'items', 'equipment'].includes(entry.action) || entry.action === 'town' && canEnterTown(save)
            return <button key={entry.action} aria-label={entry.label} disabled={!available || busy || editing}
              onClick={() => {
                if (pending.current) return
                if (entry.action === 'cards') setCardsOpen(true)
                if (entry.action === 'title') onTitle()
                if (entry.action === 'town' && canEnterTown(save)) setTownSelectionOpen(true)
                if (entry.action === 'quests') scrollGuildTo(questBoard)
                if (entry.action === 'items') scrollGuildTo(itemInventory)
                if (entry.action === 'equipment') scrollGuildTo(equipmentInventory)
              }}>{entry.label}{!available && <small>未移植</small>}</button>
          })}
        </nav>
      </div>
    </div>
    {editing && <DeckEditor save={save} onSave={onSave} onClose={() => setEditing(false)} />}
  </main>
}
