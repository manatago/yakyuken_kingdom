import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { leaveGuildHome } from '../../../packages/guild/home'
import { canStartBelka, startBelka } from '../../../packages/battle/belka'
import { guildHomeContent } from '../../../packages/guild/routes'
import { fitViewport } from '../../../packages/story/viewport'
import guildBackground from '../../../godot/assets/backgrounds/stage1/bg07_st1_001.png?url'
import { CardPanel } from './CardPanel'
import { DeckEditor } from './DeckEditor'
import { canStartJin, canStartSubevent1Jin, setJinDraft, startJin, startSubevent1JinStory } from '../../../packages/battle/jin'
import { cardPresentation } from '../../../packages/cards/presentation'
import { getItemDefinition } from '../../../packages/domain/item-catalog'

const backgrounds: Record<string, string> = {
  'godot/assets/backgrounds/stage1/bg07_st1_001.png': guildBackground
}
const background = backgrounds[guildHomeContent.background]
if (!background) throw new Error('Unknown guild home background')

export function GuildHome({ save, onSave, onTitle }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onTitle: () => void
}) {
  const viewport = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [cardsOpen, setCardsOpen] = useState(false)
  const [editing, setEditing] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const jinDraft = save.progress.jin_draft ?? []
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
        </> : <section className="guild-notice">
          <p>ギルドホーム移植の確認用画面です。</p>
          <p>カードの確認・編成編集ができます。クエスト・街・次の章などは未移植です。</p>
          {canStartBelka(save) && <button disabled={busy} onClick={() => { void openBelka() }}>ベルカ戦を確認</button>}
          {(save.player.items ?? []).length > 0 && <section aria-label="所持アイテム" data-testid="item-inventory">
            <h2>所持アイテム</h2>
            <ul>{(save.player.items ?? []).map((id, index) => <li key={`${id}-${index}`}>{getItemDefinition(id)?.name ?? id}</li>)}</ul>
          </section>}
          {canStartJin(save) && <section aria-label="ジン戦カード選択" data-testid="jin-draft">
            <h2>ジン戦（確認用）</h2>
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
            <button disabled={busy || jinDraft.length !== 3} onClick={() => { void launchJin() }}>3枚でジン戦を開始</button>
            <button disabled={busy || jinDraft.length !== 3 || !canStartSubevent1Jin(save)}
              onClick={() => { void launchSubevent1() }}>サブイベント1を開始（解放条件なし）</button>
          </section>}
          {save.progress.belka_battle?.settled && <p>ベルカ戦の結果は保存済みです。本編と再戦は後続段階で接続します。</p>}
        </section>}
        {error && <p role="alert" className="guild-error error-message">{error}</p>}
        <nav className="guild-menu" aria-label="ギルドメニュー">
          {guildHomeContent.menu.map((entry) => {
            const available = entry.action === 'cards' || entry.action === 'title'
            return <button key={entry.action} aria-label={entry.label} disabled={!available || busy || editing}
              onClick={() => {
                if (pending.current) return
                if (entry.action === 'cards') setCardsOpen(true)
                if (entry.action === 'title') onTitle()
              }}>{entry.label}{!available && <small>未移植</small>}</button>
          })}
        </nav>
      </div>
    </div>
    {editing && <DeckEditor save={save} onSave={onSave} onClose={() => setEditing(false)} />}
  </main>
}
