import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { acknowledgeSubevent1BelkaRound, continueSubevent1Belka, playSubevent1BelkaRound,
  settleSubevent1Belka, returnSubevent1BelkaToGuild, subevent1BelkaProbabilities, subevent1BelkaView } from '../../../packages/battle/subevent1-belka'
import { fitViewport } from '../../../packages/story/viewport'
import { cardPresentation } from '../../../packages/cards/presentation'
import { CardView } from './CardView'
import { getItemDefinition, isBattleUsable, type ItemId } from '../../../packages/domain/item-catalog'
import arena from '../../../godot/assets/backgrounds/prologue/bg06_prison_arena.png?url'

export function Subevent1BelkaScreen({ save, onSave, onTitle }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onTitle: () => void
}) {
  const viewport = useRef<HTMLElement>(null), pending = useRef(false), proposal = useRef<SaveData | null>(null)
  const proposalAction = useRef<string | null>(null)
  const [fit, setFit] = useState(() => fitViewport(0, 0)), [selected, setSelected] = useState<number | null>(null)
  const [selectedItem, setSelectedItem] = useState<ItemId | null>(null)
  const [busy, setBusy] = useState(false), [error, setError] = useState('')
  const ledger = save.progress.subevent1_belka_battle!, view = subevent1BelkaView(save)
  const resultPending = ledger.rounds.length > ledger.acknowledged
  const probabilities = subevent1BelkaProbabilities(save, selected === null ? undefined : ledger.player_deck[selected])
  const disabled = (action: string) => busy || proposalAction.current !== null && proposalAction.current !== action

  useLayoutEffect(() => {
    const element = viewport.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize(); const observer = new ResizeObserver(resize); observer.observe(element)
    return () => observer.disconnect()
  }, [])

  async function commit(action: string, makeSave: () => SaveData) {
    if (pending.current || disabled(action)) return
    pending.current = true; setBusy(true); setError('')
    try { proposal.current ??= makeSave(); proposalAction.current = action; await onSave(proposal.current)
      proposal.current = null; proposalAction.current = null; setSelected(null)
      setSelectedItem(null)
    } catch { setError('保存に失敗しました。進行は変わっていません。同じ操作で再試行してください。') }
    finally { pending.current = false; setBusy(false) }
  }

  return <main ref={viewport} className="story-viewport" aria-label="サブイベント1 ベルカ戦">
    <div className="story-frame" data-testid="subevent1-belka-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        <img className="story-background" alt="ベルカ戦の闘技場" src={arena} />
        <header className="story-header"><h1>サブイベント1：ベルカ戦</h1><span>所持金 {save.player.money} G</span>
          <span className="story-checkpoint" data-testid="checkpoint-id">{save.progress.checkpoint_id}</span>
          <button disabled={busy} onClick={onTitle}>タイトルに戻る</button></header>
        <aside className="belka-bayes" data-testid="bayes-eye" aria-label="ベイズアイ"><h2>ベイズアイ</h2>
          <p>相手の次の手の目安</p><p>グー {Math.round(probabilities.rock * 100)}% ／ チョキ {Math.round(probabilities.scissors * 100)}% ／ パー {Math.round(probabilities.paper * 100)}%</p></aside>
        <aside className="deck-panel fixed-deck" aria-label="ベルカ戦デッキ" data-testid="subevent1-belka-deck"
          style={{ left: 350, top: 800, right: 'auto', bottom: 'auto', width: 1220 }}>
          <h2>デッキ ・残り {ledger.player_deck.length - view.usedPlayer.length}枚</h2>
          <div className="deck-grid">{ledger.player_deck.map((card, index) => {
            const presentation = cardPresentation(card)
            return <button key={index} className={`card-button ${selected === index ? 'card-selected' : ''}`}
              aria-label={`選択 ${presentation.handLabel} ${presentation.gradeLabel}`} aria-pressed={selected === index}
              disabled={busy || resultPending || !!view.outcome || !!proposal.current || view.usedPlayer.includes(index)}
              onClick={() => { if (!pending.current && !proposal.current) setSelected(index) }}>
              <CardView card={card} /><span className="card-hand">{presentation.handLabel} {presentation.gradeLabel}</span>
            </button>
          })}</div>
        </aside>
        <section className="belka-controls" aria-label="ベルカ戦の進行">
          {ledger.settled ? <div data-testid="subevent1-belka-settled">
            <h2>{view.outcome === 'win' ? 'ベルカに勝利' : view.outcome === 'lose' ? 'ベルカに敗北' : '引き分け'}</h2>
            {view.outcome === 'win'
              ? <><p>依頼報酬は精算済み：{ledger.gold_delta! >= 0 ? '+' : ''}{ledger.gold_delta}G。受付へ報告に向かいます。</p>
                {ledger.item_rewards?.length ? <div data-testid="subevent1-belka-rewards" aria-label="勝利報酬">
                  {ledger.item_rewards.map((id, index) => <p key={`${id}-${index}`}>{getItemDefinition(id)?.name ?? id}を獲得。</p>)}
                </div> : null}</>
              : <><p>サトシはベルカに敗北した。盗賊団のアジトから撤退するしかない...</p>
                <p>ベルカ「ゲハハ！ ボクに勝てると思ったのかよ？ 出直してきな！」</p>
                <p>精算済み：{ledger.gold_delta! >= 0 ? '+' : ''}{ledger.gold_delta}G ・所持 {save.player.money}G</p></>}
            <button disabled={disabled('return')} onClick={() => { void commit('return', () => view.outcome === 'win'
              ? continueSubevent1Belka(save) : returnSubevent1BelkaToGuild(save)) }}>
              {view.outcome === 'win' ? '物語を続ける' : 'ギルドホームに戻る'}</button>
          </div> : resultPending ? <div data-testid="subevent1-belka-result">
            <h2>{view.last!.result === 'win' ? '勝ち' : view.last!.result === 'lose' ? '負け' : '引き分け'}</h2>
            <p>ベルカHP {view.opponentHp}/3 ・あなたのHP {view.playerHp}/3</p>
            <button disabled={disabled('result')} onClick={() => { void commit('result', () => view.outcome === 'win'
              ? continueSubevent1Belka(save) : view.outcome ? settleSubevent1Belka(save, Math.random()) : acknowledgeSubevent1BelkaRound(save)) }}>
              {view.outcome === 'win' ? '物語を続ける' : view.outcome ? '結果を確定' : '次の勝負へ'}</button>
          </div> : <>
            <h2>カードを選択してください</h2><p>ベルカHP {view.opponentHp}/3 ・あなたのHP {view.playerHp}/3</p>
            <label htmlFor="subevent1-belka-battle-item">この勝負で使うアイテム</label>{' '}
            <select id="subevent1-belka-battle-item" aria-label="この勝負で使うアイテム" value={selectedItem ?? ''}
              disabled={busy} onChange={(event) => setSelectedItem(event.target.value ? event.target.value as ItemId : null)}>
              <option value="">使わない</option>
              {Array.from(new Set(save.player.items ?? [])).map((id) => {
                const item = getItemDefinition(id)
                const used = (ledger.round_item_ids ?? []).filter((entry) => entry === id).length
                const owned = ledger.items_before.filter((entry) => entry === id).length
                return item?.category === 'consumable' && isBattleUsable(item) && used < owned
                  ? <option key={id} value={id}>{item.name}</option> : null
              })}
            </select>{' '}
            <button disabled={disabled('round') || selected === null}
              onClick={() => { void commit('round', () => playSubevent1BelkaRound(save, selected!, Math.random(), selectedItem ?? undefined, Math.random())) }}>勝負！</button>
          </>}
          {error && <p role="alert" className="error-message">{error}</p>}
        </section>
        {view.last && (resultPending || ledger.settled) && <section className="belka-showdown" aria-label="勝負カード">
          <div>あなた<CardView card={view.last.player} compact={false} /></div><div>ベルカ<CardView card={view.last.opponent} compact={false} /></div>
        </section>}
      </div>
    </div>
  </main>
}
