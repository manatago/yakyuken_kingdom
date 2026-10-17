import { useEffect, useMemo, useRef, useState } from 'react'
import { createOriginalStoryState, executeOriginalCommand, originalStory, type OriginalCommand } from '../../../packages/story/original'
import type { StoryEditRecord } from '../../main/story-command-store'
import type { EditorApi } from '../../preload/api'
import { OriginalStoryScreen } from '../../renderer/src/OriginalStoryScreen'
import { setEditorImageCatalog } from './image-resolver'
import { PreviewBoundary } from './PreviewBoundary'

const api = (globalThis as typeof globalThis & { janken: EditorApi }).janken
const names: Record<string, string> = { text: 'セリフ', speaker_id: '話者', portrait_id: '画像', path: '背景画像', character_id: 'キャラ',
  portrait_scale: '画像倍率', position: '画像位置', flip: '左右反転（-1:自動 / 0:なし / 1:反転）', side_override: '表示側',
  appear_effect: '登場効果', appear_from: '登場方向', appear_duration: '登場時間', exit_effect: '退場効果', exit_to: '退場方向', exit_duration: '退場時間' }
const immutable = new Set(['label_name', 'chapter_path', 'edit_source_id'])

export function StoryEditor() {
  const [record, setRecord] = useState<StoryEditRecord>()
  const [id, setId] = useState('prologue')
  const [index, setIndex] = useState(0)
  const [form, setForm] = useState<Record<string, string>>({})
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [images, setImages] = useState<string[]>([])
  const operation = useRef(false)
  const command = record?.sequence.commands[index]
  function resetForm(command?: OriginalCommand) {
    setForm(Object.fromEntries(Object.entries(command?.parameters ?? {}).map(([key, value]) => [key, JSON.stringify(value)])))
  }
  async function load(nextId = id, nextIndex = index) {
    if (operation.current) return
    operation.current = true; setBusy(true); setError(''); setMessage('')
    try {
      const next = await api.content.readStory!(nextId)
      const selected = Math.max(0, Math.min(nextIndex, next.sequence.commands.length - 1))
      setId(nextId); setRecord(next); setIndex(selected); resetForm(next.sequence.commands[selected])
    } catch { setError('原本コンテンツを読み込めませんでした。プロジェクトを確認してください。') }
    finally { operation.current = false; setBusy(false) }
  }
  useEffect(() => { void load('prologue', 0) }, [])
  const parameters = useMemo(() => {
    try { return Object.fromEntries(Object.entries(form).map(([key, value]) => [key, JSON.parse(value)])) as OriginalCommand['parameters'] }
    catch { return undefined }
  }, [form])
  const dirty = !!command && (!parameters || JSON.stringify(parameters) !== JSON.stringify(command.parameters))
  const preview = useMemo(() => {
    if (!record || !parameters) return undefined
    const scene = structuredClone(record.sequence)
    scene.commands[index].parameters = parameters
    const source = { ...originalStory, sequences: [scene] }
    let state = createOriginalStoryState(scene.id, {}, source)
    try {
      for (let cursor = 0; cursor <= index; cursor++) state = executeOriginalCommand(state, source).state
      return state
    } catch { return undefined }
  }, [record, parameters, index])
  function select(next: number) {
    if (dirty || busy || !record) return
    setIndex(next); resetForm(record.sequence.commands[next]); setError(''); setMessage('')
    localStorage.setItem('janken.story.last', JSON.stringify({ version: 1, id, index: next }))
  }
  async function save() {
    if (operation.current || !record || !parameters || !dirty) return
    operation.current = true; setBusy(true); setError(''); setMessage('')
    try {
      await api.content.writeStory!({ sequence: id, index, revision: record.revision, parameters })
      const next = await api.content.readStory!(id)
      setRecord(next); resetForm(next.sequence.commands[index])
      setMessage('保存しました。ゲームを再ビルド・再起動すると反映されます。')
      localStorage.setItem('janken.story.last', JSON.stringify({ version: 1, id, index }))
    } catch { setError('保存できませんでした。入力・画像参照・他の編集との競合を確認してください。未保存の編集は保持しています。') }
    finally { operation.current = false; setBusy(false) }
  }
  function restoreLast() {
    if (busy || dirty) return
    try {
      const previous = JSON.parse(localStorage.getItem('janken.story.last') ?? 'null')
      if (previous?.version === 1 && originalStory.sequences.some(scene => scene.id === previous.id) && Number.isSafeInteger(previous.index) && previous.index >= 0) void load(previous.id, previous.index)
    } catch { setError('前回の編集位置を読み込めませんでした。') }
  }
  return <main className="editor-app">
    <header><h1>Janken Editor</h1><p>全ストーリーの命令編集・プレビュー。保存前はゲームデータを変更しません。</p></header>
    <div className="editor-workspace">
      <section className="editor-tools" aria-label="ストーリー編集">
        <label>シーケンス<select aria-label="シーケンス" value={id} disabled={busy || dirty} onChange={event => void load(event.target.value, 0)}>
          {originalStory.sequences.map(scene => <option key={scene.id} value={scene.id}>{scene.id}</option>)}
        </select></label>
        <button disabled={busy || dirty} onClick={restoreLast}>前回の編集位置</button>
        <button disabled={busy} onClick={() => {
          void api.content.imageCatalog!().then(paths => { setImages(paths); setEditorImageCatalog(paths) })
            .catch(() => setError('画像候補を読み込めませんでした。'))
        }}>画像候補を取得</button>
        <datalist id="story-image-candidates">{images.map(path => <option key={path} value={path} />)}</datalist>
        <label>命令<select aria-label="命令" value={index} disabled={busy || dirty || !record} onChange={event => select(Number(event.target.value))}>
          {record?.sequence.commands.map((command, index) => <option key={index} value={index}>
            {index + 1}: {command.kind} {String(command.parameters.text ?? command.parameters.label_name ?? command.parameters.character_id ?? '').slice(0, 36)}
          </option>)}
        </select></label>
        <div><button disabled={busy || dirty || index === 0} onClick={() => select(index - 1)}>前の命令</button>
          <button disabled={busy || dirty || !record || index >= record.sequence.commands.length - 1} onClick={() => select(index + 1)}>次の命令</button></div>
        {command && Object.entries(command.parameters).map(([key, value]) => <label key={key}>{names[key] ?? key}
          {typeof value === 'string' && ['path', 'portrait_id'].includes(key) ? <input aria-label={`編集 ${key}`} list="story-image-candidates"
            value={(() => { try { return JSON.parse(form[key] ?? '""') } catch { return '' } })()} disabled={busy || immutable.has(key)}
            onChange={event => setForm(current => ({ ...current, [key]: JSON.stringify(event.target.value) }))} />
            : typeof value === 'string' ? <textarea aria-label={`編集 ${key}`} value={(() => { try { return JSON.parse(form[key] ?? '""') } catch { return '' } })()}
            disabled={busy || immutable.has(key)} onChange={event => setForm(current => ({ ...current, [key]: JSON.stringify(event.target.value) }))} />
            : <input aria-label={`編集 ${key}`} value={form[key] ?? ''} disabled={busy || immutable.has(key)}
              onChange={event => setForm(current => ({ ...current, [key]: event.target.value }))} />}
        </label>)}
        <p>数値・真偽値・座標はJSON形式。開始ラベル・戦闘参照・原本ソース参照は変更しません。</p>
        {!parameters && <p role="alert">JSON値が正しくありません。</p>}
        <button disabled={busy || !dirty || !parameters || !preview} onClick={() => void save()}>命令を保存</button>
        <button disabled={busy || !dirty} onClick={() => { resetForm(command); setError(''); setMessage('変更を取り消しました。') }}>命令の変更を取り消す</button>
        <button disabled={busy || dirty} onClick={() => void load()}>原本を再読込</button>
        {error && <p role="alert">{error}</p>}<p role="status">{message}</p>
      </section>
      <div className="editor-preview" data-testid="story-editor-preview">
        {preview && <PreviewBoundary key={JSON.stringify(preview)}><OriginalStoryScreen sequenceId={id} editorState={preview} onExit={() => {}} /></PreviewBoundary>}
      </div>
    </div>
  </main>
}
