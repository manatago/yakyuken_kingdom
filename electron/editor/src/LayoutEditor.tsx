import { useEffect, useMemo, useRef, useState, type PointerEvent } from 'react'
import type { ContentPack, LayoutContent } from '../../../packages/content/schema'
import { validateContent } from '../../../packages/content/validate'
import { MATILDA_LAYOUT_IDS, moveLayout } from '../../../packages/content/layout'
import { createInitialGameSave } from '../../../packages/domain/new-game'
import { playTutorialRound, prepareTutorial } from '../../../packages/battle/tutorial'
import type { EditorApi } from '../../preload/api'
import { StoryScreen } from '../../renderer/src/StoryScreen'

const api = (globalThis as typeof globalThis & { janken: EditorApi }).janken
const labels: Record<string, string> = {
  'layout.matilda.intro': '立ち絵：導入', 'layout.matilda.explanation': '立ち絵：説明',
  'layout.cards.box': 'カードボックス', 'layout.cards.deck': 'デッキ', 'layout.cards.showdown': '勝負カード'
}
const fields = (layout: LayoutContent) => ({ x: String(layout.x), y: String(layout.y), scale: String(layout.scale) })

export function LayoutEditor() {
  const [saved, setSaved] = useState<ContentPack | null>(null)
  const [draft, setDraft] = useState<ContentPack | null>(null)
  const [selected, setSelected] = useState(MATILDA_LAYOUT_IDS[0])
  const [form, setForm] = useState({ x: '', y: '', scale: '' })
  const [busy, setBusy] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const operation = useRef(false)
  const drag = useRef<{ pointer: number; x: number; y: number; scale: number; layout: LayoutContent } | null>(null)
  const layout = draft?.layouts.find((entry) => entry.id === selected)
  const original = saved?.layouts.find((entry) => entry.id === selected)
  const valid = Object.values(form).every((value) => value.trim() !== '' && Number.isFinite(Number(value))) && Number(form.scale) > 0
  const dirty = !!layout && (!valid || JSON.stringify(layout) !== JSON.stringify(original))

  async function reload(id = selected) {
    if (operation.current) return
    operation.current = true; setBusy(true); setError(''); setMessage('')
    try {
      const document = await api.content.read()
      const validation = validateContent(document, () => true)
      const pack = document as unknown as ContentPack
      if (!validation.valid || MATILDA_LAYOUT_IDS.some((key) => !pack.layouts.some((entry) => entry.id === key))) {
        throw new Error('Invalid Matilda layouts')
      }
      setSaved(pack); setDraft(structuredClone(pack))
      setForm(fields(pack.layouts.find((entry) => entry.id === id)!))
      setMessage('プロジェクトの配置を読み込みました。')
    } catch { setError('読込に失敗しました。プロジェクトとJSONを確認してください。') }
    finally { operation.current = false; setBusy(false) }
  }
  useEffect(() => { void reload() }, [])

  function select(id: string) {
    if (busy || !draft || !MATILDA_LAYOUT_IDS.includes(id)) return
    if (id !== selected && dirty) { setError('別の配置を選ぶ前に保存するか、変更を取り消してください。'); return }
    setSelected(id); setForm(fields(draft.layouts.find((entry) => entry.id === id)!)); setError(''); setMessage('')
  }
  function replace(next: LayoutContent) {
    setDraft((pack) => pack && { ...pack, layouts: pack.layouts.map((entry) => entry.id === next.id ? next : entry) })
  }
  function input(key: keyof typeof form, value: string) {
    const next = { ...form, [key]: value }
    setForm(next); setError(''); setMessage('')
    if (layout && Object.values(next).every((v) => v.trim() !== '' && Number.isFinite(Number(v))) && Number(next.scale) > 0) {
      replace({ ...layout, x: Number(next.x), y: Number(next.y), scale: Number(next.scale) })
    }
  }
  async function save() {
    if (operation.current || !layout || !original || !valid || !dirty || drag.current) return
    operation.current = true; setBusy(true); setError(''); setMessage('')
    try {
      await api.content.write({ expected: original, layout })
      setSaved(structuredClone(draft!))
      setMessage('保存しました。ゲームは再ビルド・再起動すると反映されます。')
    } catch { setError('保存に失敗しました。変更はプレビューに残っています。競合の場合は変更を取り消して再読込してください。') }
    finally { operation.current = false; setBusy(false) }
  }
  function discard() {
    if (!saved || !original || busy) return
    setDraft(structuredClone(saved)); setForm(fields(original)); setError(''); setMessage('変更を取り消しました。')
  }
  function pointerDown(event: PointerEvent<HTMLDivElement>) {
    if (busy || !valid || event.button !== 0 || !draft) return
    const element = (event.target as Element).closest<HTMLElement>('[data-layout-id]')
    const id = element?.dataset.layoutId
    if (!id || !MATILDA_LAYOUT_IDS.includes(id)) return
    event.preventDefault(); event.stopPropagation()
    if (dirty && id !== selected) { select(id); return }
    const current = draft.layouts.find((entry) => entry.id === id)!
    const stage = event.currentTarget.querySelector('.story-stage')!.getBoundingClientRect()
    select(id)
    drag.current = { pointer: event.pointerId, x: event.clientX, y: event.clientY, scale: stage.width / 1920, layout: current }
    event.currentTarget.setPointerCapture(event.pointerId)
  }
  function pointerMove(event: PointerEvent<HTMLDivElement>) {
    const start = drag.current
    if (!start || start.pointer !== event.pointerId) return
    const next = moveLayout(start.layout, event.clientX - start.x, event.clientY - start.y, start.scale)
    replace(next); setForm(fields(next)); setMessage('')
  }
  function pointerEnd(event: PointerEvent<HTMLDivElement>) {
    if (drag.current?.pointer !== event.pointerId) return
    drag.current = null
    if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId)
  }
  const previewSave = useMemo(() => {
    const initial = createInitialGameSave()
    const decked = { ...initial, player: { ...initial.player, deck: initial.player.inventory } }
    if (selected === 'layout.cards.showdown') {
      return playTutorialRound(prepareTutorial({ ...decked, progress: { ...decked.progress, checkpoint_id: 'matilda.await-deck' } }, decked.player.deck), 6, 0)
    }
    return { ...decked, progress: { ...decked.progress,
      checkpoint_id: selected === 'layout.matilda.intro' ? 'matilda.start' : 'matilda.cards.box' } }
  }, [selected])

  return <main className="editor-app">
    <header><h1>Janken Editor</h1><p>マチルダの配置編集 · 1920×1080基準 · 保存先：content/stories/matilda-tutorial.json</p></header>
    <div className="editor-workspace">
      <section className="editor-tools" aria-label="配置編集">
        <label>配置ID<select aria-label="配置ID" value={selected} disabled={busy || dirty || !draft} onChange={(event) => select(event.target.value)}>
          {MATILDA_LAYOUT_IDS.map((id) => <option value={id} key={id}>{labels[id]} — {id}</option>)}
        </select></label>
        {(['x', 'y', 'scale'] as const).map((key) => <label key={key}>
          {key === 'scale' ? '拡大率' : `${key.toUpperCase()}座標`}
          <input aria-label={key === 'scale' ? '拡大率' : `${key.toUpperCase()}座標`} type="number" step="any"
            disabled={busy || !layout} value={form[key]} onChange={(event) => input(key, event.target.value)} />
        </label>)}
        {selected.startsWith('layout.matilda.') && <label><input type="checkbox" aria-label="左右反転" disabled={busy || !layout}
          checked={layout?.flipped ?? false} onChange={(event) => layout && replace({ ...layout, flipped: event.target.checked })} />左右反転</label>}
        {!valid && layout && <p className="error-message">座標は有限の数値、拡大率は0より大きい数値にしてください。</p>}
        <button disabled={busy || !dirty || !valid} onClick={() => { void save() }}>配置を保存</button>
        <button disabled={busy || !dirty} onClick={discard}>変更を取り消す</button>
        <button disabled={busy || dirty} onClick={() => { void reload() }}>再読込</button>
        <p>画像やカード領域をドラッグできます。黄色の枠が編集対象です。未保存中は別の配置へ切り替えられません。</p>
        <p>保存前のJSONは .bak に残ります。保存後は npm run build:game でゲームを再ビルドして再起動してください。</p>
        {error && <p role="alert" className="error-message">{error}</p>}
        <p role="status">{message || (dirty ? '未保存の変更があります。' : '')}</p>
      </section>
      <div className="editor-preview" onPointerDownCapture={pointerDown} onPointerMove={pointerMove}
        onPointerUp={pointerEnd} onPointerCancel={pointerEnd} onClickCapture={(event) => event.stopPropagation()}>
        <style>{`[data-layout-id="${selected}"] { outline: 4px solid #ffdc80; outline-offset: 2px; }`}</style>
        {draft && <StoryScreen content={draft} save={previewSave} onTitle={() => {}} onSave={async () => {}} onCheckpoint={async () => {}} />}
      </div>
    </div>
  </main>
}
