import { useState } from 'react'
import { developerTools, developerJumpTarget } from '../../../packages/developer/jump'
import type { EditorApi } from '../../preload/api'
import { LayoutEditor } from './LayoutEditor'
import { StoryEditor } from './StoryEditor'
import { TraceEditor } from './TraceEditor'

const api = (globalThis as typeof globalThis & { janken: EditorApi }).janken

export function DeveloperTools() {
  const initial = new URLSearchParams(location.search).get('editor')
  const initialTab = initial === 'story' || initial === 'battle' || initial === 'slides' ? initial : 'jump'
  const [tab, setTab] = useState<'jump' | 'matilda' | 'story' | 'battle' | 'slides'>(initialTab)
  const [visited, setVisited] = useState({ battle: initialTab === 'battle', slides: initialTab === 'slides' })
  const [selected, setSelected] = useState(0)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  const point = developerTools.jump_points[selected]
  const target = developerJumpTarget(selected)
  async function launch() {
    if (busy || !target.available) return
    setBusy(true); setError(''); setMessage('')
    try {
      const result = await api.content.launchJump!(selected)
      setMessage(`別ウィンドウを開きました。選択した地点から開始します。開始地点：${result.checkpoint}`)
    } catch { setError('起動できませんでした。ゲームのビルドがあることと、開発プレイを開きすぎていないことを確認してください。') }
    finally { setBusy(false) }
  }
  return <div className="developer-shell">
    <nav aria-label="開発機能" className="developer-tabs">
      <button aria-pressed={tab === 'jump'} onClick={() => setTab('jump')}>途中から始める</button>
      <button aria-pressed={tab === 'matilda'} onClick={() => setTab('matilda')}>マチルダ配置編集</button>
      <button aria-pressed={tab === 'story'} onClick={() => setTab('story')}>ストーリー編集</button>
      <button aria-pressed={tab === 'battle'} onClick={() => { setVisited(current => ({ ...current, battle: true })); setTab('battle') }}>戦闘表示編集</button>
      <button aria-pressed={tab === 'slides'} onClick={() => { setVisited(current => ({ ...current, slides: true })); setTab('slides') }}>紙芝居編集</button>
    </nav>
    {/* Keep the editor mounted so switching the launcher never discards an unsaved draft. */}
    <div hidden={tab !== 'matilda'}><LayoutEditor /></div>
    <div hidden={tab !== 'story'}><StoryEditor /></div>
    {visited.battle && <div hidden={tab !== 'battle'}><TraceEditor /></div>}
    {visited.slides && <div hidden={tab !== 'slides'}><TraceEditor slides /></div>}
    {tab === 'jump' && <main className="editor-app">
      <header><h1>Janken Editor</h1><p>Godotの開始地点から実プレイ・通常セーブとは別の一時保存領域</p></header>
      <section className="developer-jump">
        <label>開始地点<select aria-label="開始地点" disabled={busy} value={selected} onChange={event => {
          setSelected(Number(event.target.value)); setMessage(''); setError('')
        }}>{developerTools.jump_points.map((point, index) => {
          const target = developerJumpTarget(index)
          return <option key={index} value={index} disabled={!target.available}>{point.name}{target.available ? '' : `（${target.reason}）`}</option>
        })}</select></label>
        <dl><dt>開始ラベル</dt><dd>{point.label}</dd><dt>所持金</dt><dd>{point.state.money}G</dd>
          <dt>所持カード</dt><dd>{point.state.inventory.length}枚</dd><dt>初期フラグ</dt>
          <dd>{Object.entries(point.state.flags).filter(([, enabled]) => enabled).map(([key]) => key).join('、') || 'なし'}</dd></dl>
        {!target.available && <p>{target.reason}</p>}
        <button disabled={busy || !target.available} onClick={() => void launch()}>この場面から実プレイ</button>
        <p>通常のプレイ記録は変更しません。開発プレイを終了すると、この一時セーブは削除されます。</p>
        <p role="status">{message}</p>{error && <p role="alert">{error}</p>}
      </section>
    </main>}
  </div>
}
