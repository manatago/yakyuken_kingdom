import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { chooseStage5Response, STAGE5_CHOICES } from '../../../packages/battle/stage5-minigame'
import { continueStage5Minigame } from '../../../packages/battle/stage5'
import { fitViewport } from '../../../packages/story/viewport'

const labels = {
  source_record: '珠の反応記録と質問記録を照合する',
  repeat_question: '同じ質問をもう一度してもらう',
  accept_conclusion: '珠の反応だけで嫌疑を認める',
  pisuke: 'ピー助に記録を照合してもらう'
} as const

export function Stage5MinigameScreen({ save, onSave, onTitle }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onTitle: () => void
}) {
  const viewport = useRef<HTMLElement>(null)
  const ledger = save.progress.stage5_minigame
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  useLayoutEffect(() => {
    if (!viewport.current) return
    const element = viewport.current
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize()
    const observer = new ResizeObserver(resize)
    observer.observe(element)
    return () => observer.disconnect()
  }, [])

  async function choose(choice: (typeof STAGE5_CHOICES)[number]) {
    if (!ledger || busy || ledger.outcome) return
    setBusy(true); setError('')
    try { await onSave(chooseStage5Response(save, choice)) }
    catch { setError('照合結果を保存できませんでした。記録は変更されていません。') }
    finally { setBusy(false) }
  }

  async function continueToRematch() {
    if (!ledger?.outcome || busy) return
    setBusy(true); setError('')
    try { await onSave(continueStage5Minigame(save)) }
    catch { setError('再審へ進めませんでした。照合結果は保存されたままです。') }
    finally { setBusy(false) }
  }

  if (!ledger) return <main className="game-screen"><p role="alert">尋問記録の保存データがありません。</p>
    <button onClick={onTitle}>タイトルへ戻る</button></main>
  const last = ledger.rounds.at(-1)
  return <main ref={viewport} className="story-viewport" aria-label="Stage 5 尋問記録の照合">
    <div className="story-frame" data-testid="stage5-minigame-frame" style={{ width: fit.width, height: fit.height }}>
      <section className="story-stage stage3-review" data-testid="stage5-minigame" style={{ transform: `scale(${fit.scale})` }}>
        <header className="story-header"><div><p className="eyebrow">STAGE 5 · FERIA</p><h1>尋問記録を照合する</h1></div>
          <button onClick={onTitle} disabled={busy}>タイトルへ戻る</button></header>
        <p>珠の反応は動揺を示すだけ。質問と反応の記録から、判断の根拠を確かめましょう。</p>
        <div className="stage2-gauge-row"><span>審理の混乱度</span>
          <progress aria-label="審理の混乱度" max={130} value={ledger.gauge} />
          <output data-testid="stage5-gauge">{ledger.gauge}/130</output></div>
        <p className="stage2-round">照合 {ledger.rounds.length + 1} 回目 · 有効記録 {ledger.hits}/3 · 誤認 {ledger.misses}/6</p>
        {ledger.outcome ? <section className="stage2-result" data-testid="stage5-result">
          <h2>{ledger.outcome === 'win' ? '記録の不整合を立証した' : '混乱を収められなかった'}</h2>
          <p>照合結果を添えて、正式な再審を求めます。</p>
          <button disabled={busy} onClick={() => { void continueToRematch() }}>再審へ進む</button>
        </section> : <div className="stage4-choice-grid">{STAGE5_CHOICES.map((choice) => <button key={choice} disabled={busy}
          data-choice={choice} onClick={() => { void choose(choice) }}>{labels[choice]}</button>)}</div>}
        {last && <p role="status" data-testid="stage5-feedback">{last.hit
          ? '記録を裏づけとして確認できた。' : '根拠が確認できず、審理が混乱した。'}</p>}
        {error && <p role="alert" className="error-message">{error}</p>}
      </section>
    </div>
  </main>
}
