import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { leaveGuildHome } from '../../../packages/guild/home'
import { guildHomeContent } from '../../../packages/guild/routes'
import { fitViewport } from '../../../packages/story/viewport'
import guildBackground from '../../../godot/assets/backgrounds/stage1/bg07_st1_001.png?url'
import { CardPanel } from './CardPanel'
import { DeckEditor } from './DeckEditor'

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
