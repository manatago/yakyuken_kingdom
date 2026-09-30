import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { belkaContent, belkaBayesProbabilities, belkaView, playBelkaRound, acknowledgeBelkaRound,
  settleBelka, returnBelkaToGuild } from '../../../packages/battle/belka'
import { validateContent } from '../../../packages/content/validate'
import { fitViewport } from '../../../packages/story/viewport'
import { cardPresentation } from '../../../packages/cards/presentation'
import { CardView } from './CardView'
import arena from '../../../godot/assets/backgrounds/prologue/bg06_prison_arena.png?url'

const backgroundPath = 'godot/assets/backgrounds/prologue/bg06_prison_arena.png'
const validation = validateContent(belkaContent, (path) => path === backgroundPath)
if (!validation.valid) throw new Error(`Invalid Belka content: ${JSON.stringify(validation.issues)}`)

export function BelkaScreen({ save, onSave, onTitle }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onTitle: () => void
}) {
  const viewport = useRef<HTMLElement>(null)
  const pending = useRef(false)
  const proposal = useRef<SaveData | null>(null)
  const proposalAction = useRef<string | null>(null)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [selected, setSelected] = useState<number | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const ledger = save.progress.belka_battle!
  const view = belkaView(save)
  const resultPending = ledger.rounds.length > ledger.acknowledged
  const probabilities = belkaBayesProbabilities(save, selected === null ? undefined : ledger.player_deck[selected])
  const actionDisabled = (action: string) => busy || proposalAction.current !== null && proposalAction.current !== action

  useLayoutEffect(() => {
    const element = viewport.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize()
    const observer = new ResizeObserver(resize)
    observer.observe(element)
    return () => observer.disconnect()
  }, [])

  async function commit(action: string, makeSave: () => SaveData) {
    if (pending.current || actionDisabled(action)) return
    pending.current = true
    setBusy(true)
    setError('')
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
      setBusy(false)
    }
  }

  return <main ref={viewport} className="story-viewport" aria-label="ベルカ戦">
    <div className="story-frame" data-testid="belka-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        <img className="story-background" data-testid="belka-background" alt="ベルカ戦の闘技場" src={arena} />
        <header className="story-header">
          <h1>ベルカ戦（確認用）</h1>
          <span>所持金 {save.player.money} G</span>
          <span className="story-checkpoint" data-testid="checkpoint-id">{save.progress.checkpoint_id}</span>
          <button disabled={busy} onClick={onTitle}>タイトルに戻る</button>
        </header>
        <aside className="belka-bayes" data-testid="bayes-eye" aria-label="ベイズアイ">
          <h2>ベイズアイ</h2>
          <p>相手の次の手の目安</p>
          <p>グー {Math.round(probabilities.rock * 100)}% ／ チョキ {Math.round(probabilities.scissors * 100)}% ／ パー {Math.round(probabilities.paper * 100)}%</p>
        </aside>
        <aside className="deck-panel fixed-deck" aria-label="ベルカ戦デッキ" data-testid="belka-deck"
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
          {ledger.settled ? <div data-testid="belka-settled">
            <h2>{view.outcome === 'win' ? 'ベルカに勝利' : view.outcome === 'lose' ? 'ベルカに敗北' : '引き分け'}</h2>
            <p>精算済み：{ledger.gold_delta! >= 0 ? '+' : ''}{ledger.gold_delta}G ・所持 {save.player.money}G</p>
            <button disabled={actionDisabled('return')} onClick={() => { void commit('return', () => returnBelkaToGuild(save)) }}>ギルドホームに戻る</button>
          </div> : resultPending ? <div data-testid="belka-result">
            <h2>{view.last!.result === 'win' ? '勝ち' : view.last!.result === 'lose' ? '負け' : '引き分け'}</h2>
            <p>ベルカHP {view.opponentHp}/3 ・あなたのHP {view.playerHp}/3</p>
            <button disabled={actionDisabled('result')} onClick={() => { void commit('result', () => view.outcome
              ? settleBelka(save, Math.random()) : acknowledgeBelkaRound(save)) }}>
              {view.outcome ? '結果を確定' : '次の勝負へ'}</button>
          </div> : <>
            <h2>カードを選択してください</h2>
            <p>ベルカHP {view.opponentHp}/3 ・あなたのHP {view.playerHp}/3</p>
            <button disabled={actionDisabled('round') || selected === null} onClick={() => { void commit('round', () => playBelkaRound(save, selected!, Math.random())) }}>勝負！</button>
          </>}
          {error && <p role="alert" className="error-message">{error}</p>}
        </section>
        {view.last && (resultPending || ledger.settled) && <section className="belka-showdown" aria-label="勝負カード">
          <div>あなた<CardView card={view.last.player} compact={false} /></div>
          <div>ベルカ<CardView card={view.last.opponent} compact={false} /></div>
        </section>}
      </div>
    </div>
  </main>
}
