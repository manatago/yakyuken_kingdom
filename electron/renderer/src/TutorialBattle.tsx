import { useRef, useState } from 'react'
import type { Card } from '../../../packages/domain/card'
import type { SaveData } from '../../../packages/domain/save'
import { validateDeck } from '../../../packages/domain/deck'
import { acknowledgeTutorial, playTutorialRound, prepareTutorial, tutorialBattle, tutorialView } from '../../../packages/battle/tutorial'
import { cardPresentation } from '../../../packages/cards/presentation'
import { CardView } from './CardView'

export function TutorialBattle({ save, onSave, onBusy }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onBusy: (busy: boolean) => void
}) {
  const [selected, setSelected] = useState<number | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const pending = useRef(false)
  const proposal = useRef<SaveData | null>(null)
  const ledger = save.progress.tutorial
  const deck = save.player.deck
  const view = tutorialView(save)
  const resultPending = ledger && ledger.rounds.length > ledger.acknowledged
  const label = (card: Card) => { const p = cardPresentation(card); return `${p.handLabel} ${p.gradeLabel}` }

  async function commit(makeSave: () => SaveData) {
    if (pending.current) return
    pending.current = true
    setBusy(true); onBusy(true); setError('')
    try {
      await onSave(makeSave())
      proposal.current = null
      setSelected(null)
    } catch {
      setError('保存に失敗しました。進行は変わっていません。もう一度操作してください。')
    } finally {
      pending.current = false
      setBusy(false); onBusy(false)
    }
  }

  function saveDeck(cards: readonly Card[]) {
    return commit(() => {
      if (cards.length > tutorialBattle.player_deck_size || cards.some((card) => card.grade !== 1) ||
          cards.length > 0 && !validateDeck(save.player.inventory, cards, cards.length).valid) throw new Error('Invalid deck')
      return { ...save, player: { ...save.player, deck: [...cards] } }
    })
  }

  // Match duplicate copies by counts, not object identity or catalog ID alone.
  const remaining = [...deck]
  const available = save.player.inventory.map((card) => {
    const index = remaining.findIndex((entry) => entry.hand === card.hand && entry.grade === card.grade)
    if (index >= 0) { remaining.splice(index, 1); return false }
    return card.grade === 1
  })

  return <>
    <aside className="card-box" data-testid="card-box" aria-label="所持カード">
      <h2>カードボックス</h2><p>所持 {save.player.inventory.length}枚（デッキ分を含む）</p>
      <div className="card-grid">{save.player.inventory.map((card, index) => !ledger
        ? <button key={index} className="card-button" aria-label={`追加 ${label(card)}`} disabled={busy || !available[index] || deck.length >= 9}
          onClick={() => { void saveDeck([...deck, card]) }}><CardView card={card} /><span className="card-hand">{label(card)}</span></button>
        : <span key={index}><CardView card={card} /><span className="card-hand">{label(card)}</span></span>)}</div>
    </aside>
    <aside className="deck-panel" data-testid="deck-panel" aria-label="練習デッキ">
      <h2>{ledger ? `練習 ${ledger.acknowledged + 1}/2 ・残り ${deck.length - view.usedPlayer.length}枚` : `デッキ ${deck.length}/9`}</h2>
      <div className="deck-grid">{Array.from({ length: 9 }, (_, index) => deck[index]
        ? <button key={index} className={`card-button ${selected === index ? 'card-selected' : ''}`}
          aria-label={`${ledger ? '選択' : '削除'} ${label(deck[index])}`} aria-pressed={ledger ? selected === index : undefined}
          disabled={busy || !!resultPending || view.usedPlayer.includes(index)}
          onClick={() => { if (ledger) { if (!proposal.current) setSelected(index) } else void saveDeck(deck.filter((_, i) => i !== index)) }}>
          <CardView card={deck[index]} /><span className="card-hand">{label(deck[index])}</span></button>
        : <span key={index} className="empty-deck-slot">{index + 1}</span>)}</div>
    </aside>
    <section className="tutorial-controls" aria-label="練習の進行">
      {!ledger ? <>
        <h2>デッキを9枚セットしてください</h2>
        <p>カードボックスから追加し、デッキのカードを押すと削除できます。</p>
        <button disabled={busy} onClick={() => { void saveDeck(save.player.inventory.filter((card) => card.grade === 1).slice(0, 9)) }}>自動</button>{' '}
        <button disabled={busy || deck.some((card) => card.grade !== 1) || !validateDeck(save.player.inventory, deck, 9).valid}
          onClick={() => { void commit(() => prepareTutorial(save, deck)) }}>準備完了</button>
      </> : resultPending ? <div data-testid="tutorial-result">
        <h2>{view.last!.result === 'win' ? '勝ち' : view.last!.result === 'lose' ? '負け' : '引き分け'}</h2>
        <p>{ledger.rounds.length === 1
          ? view.last!.result === 'win' ? 'ほら、勝っただろ？' : view.last!.result === 'lose' ? '...あんた、パーを出せって言っただろ。まぁいい、次で取り返しな。' : 'あいこか。同じグレードだと引き分けになる。'
          : view.last!.result === 'win' ? '思ったよりやるな。' : '見た目通り弱いな。'}</p>
        <p>相手HP {view.opponentHp}/3 ・あなたのHP {view.playerHp}/3</p>
        <p>勝つと相手のHP、負けると自分のHPが減る。本番では3回負けると敗北、相手を3回倒せば勝ちさ。<br />あいこではHPも残りカードも減らない。今回は2回の練習で終わりだ。</p>
        <button disabled={busy} onClick={() => { void commit(() => acknowledgeTutorial(save)) }}>
          {ledger.rounds.length === 1 ? '次の練習へ' : '練習を終える'}</button>
      </div> : <div data-testid="tutorial-selection">
        <h2>カードを選択してください</h2>
        <p>{ledger.acknowledged === 0 ? '最初は特別にグーを出してやるから、お前はパーを出しな。' : 'もう一回やってみな。今度は好きなカードを選びな。'}</p>
        <p>出したいカードを選んで「勝負！」を押してください。</p>
        <button disabled={busy || selected === null} onClick={() => { void commit(() => {
          proposal.current ??= playTutorialRound(save, selected!, Math.random())
          return proposal.current
        }) }}>勝負！</button>
      </div>}
      {error && <p className="error-message" role="alert">{error}</p>}
    </section>
    {ledger && <section className="tutorial-showdown" aria-label="勝負カード">
      {resultPending ? <>
        <div>あなた<CardView card={view.last!.player} compact={false} /></div>
        <div>マチルダ<CardView card={view.last!.opponent} compact={false} /></div>
      </> : selected !== null ? <div>選択中<CardView card={deck[selected]} compact={false} /></div> : <p>相手HP {view.opponentHp}/3 ・あなたのHP {view.playerHp}/3</p>}
    </section>}
  </>
}
