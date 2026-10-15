import { useEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { addDeckCard, removeDeckCard, savePreparedDeck, PREPARED_DECK_SIZE } from '../../../packages/domain/deck-editing'
import { validateDeck } from '../../../packages/domain/deck'
import { cardPresentation } from '../../../packages/cards/presentation'
import { CardView } from './CardView'

export function DeckEditor({ save, onSave, onClose }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onClose: () => void
}) {
  const dialog = useRef<HTMLDialogElement>(null)
  const pending = useRef(false)
  const [draft, setDraft] = useState(() => [...(save.player.prepared_deck ?? save.player.deck)])
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  useEffect(() => { dialog.current!.showModal() }, [])
  const valid = validateDeck(save.player.inventory, draft, PREPARED_DECK_SIZE).valid
  async function persist() {
    if (pending.current || !valid) return
    pending.current = true
    setBusy(true)
    setError('')
    try {
      await onSave(savePreparedDeck(save, draft))
      onClose()
    } catch {
      setError('保存に失敗しました。編成の下書きは保持しています。')
    } finally {
      pending.current = false
      setBusy(false)
    }
  }
  return <dialog ref={dialog} className="deck-editor" aria-labelledby="deck-editor-title"
    onCancel={(event) => { event.preventDefault(); if (!pending.current) onClose() }}>
    <h2 id="deck-editor-title">対戦用の編成</h2>
    <p>次の対戦用に9枚を選びます。過去の勝負記録は変更しません。</p>
    <div className="editor-columns">
      <section aria-label="編成用の所持カード"><h3>所持カード（デッキ分を含む）</h3>
        <div className="editor-card-grid">{save.player.inventory.map((card, index) => {
          const view = cardPresentation(card)
          const available = save.player.inventory.filter((c) => c.hand === card.hand && c.grade === card.grade).length
          const used = draft.filter((c) => c.hand === card.hand && c.grade === card.grade).length
          return <button key={index} className="card-button" aria-label={`編成に追加 ${view.handLabel} ${view.gradeLabel}`}
            disabled={busy || draft.length >= 9 || used >= available}
            onClick={() => setDraft(addDeckCard(save.player.inventory, draft, card))}>
            <CardView card={card} /><span className="card-hand">{view.handLabel} {view.gradeLabel}</span>
          </button>
        })}</div>
      </section>
      <section aria-label="編集中の対戦用カード"><h3>選択済み {draft.length}/9</h3>
        <div className="editor-card-grid">{draft.map((card, index) => {
          const view = cardPresentation(card)
          return <button key={index} className="card-button" aria-label={`編成から削除 ${view.handLabel} ${view.gradeLabel}`}
            disabled={busy} onClick={() => setDraft(removeDeckCard(draft, index))}>
            <CardView card={card} /><span className="card-hand">{view.handLabel} {view.gradeLabel}</span>
          </button>
        })}</div>
      </section>
    </div>
    <p role="status">{valid ? '保存できる編成です。' : '所持しているカードで9枚の編成にしてください。'}</p>
    {error && <p role="alert" className="error-message">{error}</p>}
    <div className="editor-actions"><button disabled={busy} onClick={onClose}>キャンセル</button>
      <button disabled={busy || !valid} onClick={() => { void persist() }}>編成を保存</button></div>
  </dialog>
}
