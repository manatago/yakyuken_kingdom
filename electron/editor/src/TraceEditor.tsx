import { useEffect, useMemo, useRef, useState } from 'react'
import type { EditorApi } from '../../preload/api'
import type { TraceCatalogEntry, TraceEditRecord } from '../../main/trace-command-store'
import { TracePreview } from './TracePreview'
import { PreviewBoundary } from './PreviewBoundary'
import { TraceFields } from './TraceFields'

const api = (globalThis as typeof globalThis & { janken: EditorApi }).janken
const visual = new Set(['set_portrait', 'deck', 'background', 'band', 'narrator_band', 'bubble', 'wait',
  'set_bubble_side', 'set_battle_ui_visible', 'highlight', 'unhighlight', 'leave'])

export function TraceEditor({ slides = false }: { slides?: boolean }) {
  const [catalog, setCatalog] = useState<TraceCatalogEntry[]>([])
  const [selected, setSelected] = useState(0)
  const [record, setRecord] = useState<TraceEditRecord>()
  const [index, setIndex] = useState(0)
  const [form, setForm] = useState('[]')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const operation = useRef(false)
  const indices = record?.commands.flatMap((command, index) => !slides || ['background', 'bubble'].includes(command.kind) ? [index] : []) ?? []
  const command = record?.commands[index]
  const args = useMemo(() => { try { const value = JSON.parse(form); return Array.isArray(value) ? value : undefined } catch { return undefined } }, [form])
  const dirty = !!command && (!args || JSON.stringify(args) !== JSON.stringify(command.args))
  async function load(entry: TraceCatalogEntry, selectedIndex: number) {
    if (operation.current) return
    operation.current = true; setBusy(true); setError(''); setMessage('')
    try {
      const next = await api.content.readTrace!(entry.document, entry.target)
      const index = slides ? next.commands.findIndex(command => ['background', 'bubble'].includes(command.kind)) : 0
      setRecord(next); setSelected(selectedIndex); setIndex(index); setForm(JSON.stringify(next.commands[index].args, null, 2))
    } catch { setError('戦闘データを読み込めませんでした。プロジェクトを確認してください。') }
    finally { operation.current = false; setBusy(false) }
  }
  useEffect(() => {
    let active = true
    void api.content.traceCatalog!().then(async entries => {
      if (!active) return
      const targets = slides ? entries.filter(entry => entry.hasSlides) : entries
      setCatalog(targets)
      if (targets[0]) await load(targets[0], 0)
    }).catch(() => { if (active) setError('戦闘の対象一覧を読み込めませんでした。') })
    return () => { active = false }
  }, [])
  function selectCommand(next: number) {
    if (busy || dirty || !record || !indices.includes(next)) return
    setIndex(next); setForm(JSON.stringify(record.commands[next].args, null, 2)); setMessage(''); setError('')
  }
  async function save() {
    if (operation.current || !record || !args || !dirty || !command || !visual.has(command.kind)) return
    operation.current = true; setBusy(true); setError(''); setMessage('')
    try {
      const target = catalog[selected]
      const result = await api.content.writeTrace!({ document: target.document, target: target.target, index, args, revision: record.revision })
      const next = await api.content.readTrace!(target.document, target.target)
      setRecord(next); setForm(JSON.stringify(next.commands[index].args, null, 2))
      setMessage(`保存しました。共通する${result.affected}分岐へ反映しました。ゲームは再ビルド・再起動で反映されます。`)
    } catch { setError('保存できませんでした。入力・画像参照・競合を確認してください。下書きは保持しています。') }
    finally { operation.current = false; setBusy(false) }
  }
  const preview = useMemo(() => {
    if (!record || !args) return undefined
    const commands = structuredClone(record.commands.slice(0, index + 1))
    commands[index].args = args
    return [...record.setup, ...commands]
  }, [record, args, index])
  const position = indices.indexOf(index)
  return <main className="editor-app" aria-label={slides ? '紙芝居編集画面' : '戦闘表示編集画面'}>
    <header><h1>Janken Editor</h1><p>{slides ? '紙芝居：既存ページ・吹き出しの編集' : '戦闘・ミニゲーム：既存立ち絵・表示命令の編集'}</p></header>
    <div className="editor-workspace"><section className="editor-tools">
      <label>戦闘の対象<select aria-label="戦闘の対象" value={selected} disabled={busy || dirty || !catalog.length}
        onChange={event => void load(catalog[Number(event.target.value)], Number(event.target.value))}>
        {catalog.map((target, index) => <option key={`${target.document}:${target.target}`} value={index}>{target.label}</option>)}
      </select></label>
      <label>{slides ? 'ページ／吹き出し' : '表示命令'}<select aria-label="表示命令" value={index} disabled={busy || dirty || !record}
        onChange={event => selectCommand(Number(event.target.value))}>
        {indices.map(index => <option key={index} value={index}>{index + 1}: {record!.commands[index].kind}</option>)}
      </select></label>
      <button disabled={busy || dirty || position <= 0} onClick={() => selectCommand(indices[position - 1])}>前の表示</button>
      <button disabled={busy || dirty || position < 0 || position >= indices.length - 1} onClick={() => selectCommand(indices[position + 1])}>次の表示</button>
      {args && <TraceFields value={args} disabled={busy || !command || !visual.has(command.kind)} onChange={value => setForm(JSON.stringify(value, null, 2))} />}
      <details><summary>詳細設定（JSON）</summary><label>引数（JSON）<textarea aria-label="表示引数" value={form} disabled={busy || !command || !visual.has(command.kind)} onChange={event => setForm(event.target.value)} /></label></details>
      {!args && <p role="alert">JSON配列として入力してください。</p>}
      {command && !visual.has(command.kind) && <p>勝負・手選択などのゲーム処理はここでは変更しません。</p>}
      <button disabled={busy || !dirty || !args || !command || !visual.has(command.kind)} onClick={() => void save()}>表示を保存</button>
      <button disabled={busy || !dirty} onClick={() => { setForm(JSON.stringify(command!.args, null, 2)); setError(''); setMessage('変更を取り消しました。') }}>表示の変更を取り消す</button>
      <button disabled={busy || dirty || !record} onClick={() => void load(catalog[selected], selected)}>表示を再読込</button>
      <p>共通する勝敗分岐へ同じ編集を適用します。章をまたいだ変更や勝敗処理の変更は行いません。</p>
      {error && <p role="alert">{error}</p>}<p role="status">{message}</p>
    </section><div className="editor-preview">{preview && record && <PreviewBoundary key={`${selected}:${JSON.stringify(preview)}`}>
      <TracePreview commands={preview} background={record.background} /></PreviewBoundary>}</div></div>
  </main>
}
