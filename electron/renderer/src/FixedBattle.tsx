import { useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { fixedView, prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle,
  returnFromFixedBattle, retryFixedBattle } from '../../../packages/battle/fixed'
import { cardPresentation } from '../../../packages/cards/presentation'
import { CardView } from './CardView'
import type { ContentPack } from '../../../packages/content/schema'
import { cardLayout, layoutStyle } from '../../../packages/content/layout'

export function FixedBattle({ save, onSave, onBusy, layouts }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onBusy: (busy: boolean) => void
  layouts: ContentPack['layouts']
}) {
  const [selected, setSelected] = useState<number | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const pending = useRef(false)
  const proposal = useRef<SaveData | null>(null)
  const proposalAction = useRef<string | null>(null)
  const ledger = save.progress.fixed_battle
  const deck = ledger?.player_deck ?? save.player.prepared_deck ?? save.player.deck
  const view = ledger ? fixedView(save) : undefined
  const resultPending = !!ledger && ledger.rounds.length > ledger.acknowledged

  const actionDisabled = (action: string) => busy || proposalAction.current !== null && proposalAction.current !== action

  async function commit(action: string, makeSave: () => SaveData) {
    if (pending.current || actionDisabled(action)) return
    pending.current = true
    setBusy(true); onBusy(true); setError('')
    try {
      proposal.current ??= makeSave()
      proposalAction.current = action
      await onSave(proposal.current)
      proposal.current = null
      proposalAction.current = null
      setSelected(null)
    } catch {
      setError('保存に失敗しました。進行は変わっていません。同じ操作で再試行してください。')
    } finally {
      pending.current = false
      setBusy(false); onBusy(false)
    }
  }

  return <>
    <aside className="card-box" aria-label="所持カード" data-testid="card-box"
      style={layoutStyle(cardLayout({ layouts }, 'layout.cards.box'))}>
      <h2>カードボックス</h2><p>所持 {save.player.inventory.length}枚 ・{save.player.money}G</p>
      <div className="card-grid">{save.player.inventory.map((card, index) => <span key={index}><CardView card={card} /></span>)}</div>
    </aside>
    <aside className="deck-panel fixed-deck" aria-label="通常戦デッキ" data-testid="fixed-deck"
      style={{ ...layoutStyle(cardLayout({ layouts }, 'layout.cards.deck')), width: 1220 }}>
      <h2>通常戦 ・残り {deck.length - (view?.usedPlayer.length ?? 0)}枚</h2>
      <div className="deck-grid">{deck.map((card, index) => {
        const presentation = cardPresentation(card)
        return <button key={index} className={`card-button ${selected === index ? 'card-selected' : ''}`}
          aria-label={`選択 ${presentation.handLabel} ${presentation.gradeLabel}`} aria-pressed={selected === index}
          disabled={!ledger || busy || resultPending || !!view?.outcome || !!proposal.current || !!view?.usedPlayer.includes(index)}
          onClick={() => { if (!pending.current && !proposal.current) setSelected(index) }}>
          <CardView card={card} /><span className="card-hand">{presentation.handLabel} {presentation.gradeLabel}</span>
        </button>
      })}</div>
    </aside>
    <section className="tutorial-controls fixed-controls" aria-label="通常戦の進行">
      {!ledger ? <>
        <h2>保存した編成で通常戦を開始</h2><p>双方HP3。カードの移動はありません。</p>
        <button disabled={actionDisabled('start') || deck.length !== 9} onClick={() => { void commit('start', () => prepareFixedBattle(save)) }}>通常戦を開始</button>
      </> : ledger.settled ? <div data-testid="fixed-settled">
        <h2>{view!.outcome === 'win' ? '対戦に勝利' : view!.outcome === 'lose' ? '対戦に敗北' : '対戦は引き分け'}</h2>
        <p>精算済み：{ledger.gold_delta! >= 0 ? '+' : ''}{ledger.gold_delta}G ・所持 {save.player.money}G</p>
        {view!.outcome === 'lose' && <button disabled={actionDisabled('retry')} onClick={() => { void commit('retry', () => retryFixedBattle(save)) }}>再挑戦</button>}{' '}
        <button disabled={actionDisabled('return')} onClick={() => { void commit('return', () => returnFromFixedBattle(save)) }}>会話に戻る</button>
      </div> : resultPending ? <div data-testid="fixed-result">
        <h2>{view!.last!.result === 'win' ? '勝ち' : view!.last!.result === 'lose' ? '負け' : '引き分け'}</h2>
        <p>相手HP {view!.opponentHp}/3 ・あなたのHP {view!.playerHp}/3</p>
        <p>{view!.outcome ? '対戦が終了しました。結果を確定してください。' : view!.last!.result === 'draw' ? 'HPとカードは減りません。' : '使ったカードはこの対戦中、再使用できません。'}</p>
        <button disabled={actionDisabled('result')} onClick={() => { void commit('result', () => view!.outcome
          ? settleFixedBattle(save, Math.random()) : acknowledgeFixedRound(save)) }}>
          {view!.outcome ? '結果を確定' : '次の勝負へ'}</button>
      </div> : <>
        <h2>カードを選択してください</h2>
        <p>相手HP {view!.opponentHp}/3 ・あなたのHP {view!.playerHp}/3</p>
        <button disabled={actionDisabled('round') || selected === null} onClick={() => { void commit('round', () => playFixedRound(save, selected!, Math.random())) }}>勝負！</button>
      </>}
      {error && <p className="error-message" role="alert">{error}</p>}
    </section>
    {ledger && <section className="tutorial-showdown" aria-label="勝負カード"
      style={{ ...layoutStyle(cardLayout({ layouts }, 'layout.cards.showdown')), width: 1180 }}>
      {(resultPending || ledger.settled) && view?.last ? <>
        <div>あなた<CardView card={view.last.player} compact={false} /></div>
        <div>マチルダ<CardView card={view.last.opponent} compact={false} /></div>
      </> : selected !== null && <div>選択中<CardView card={deck[selected]} compact={false} /></div>}
    </section>}
  </>
}
