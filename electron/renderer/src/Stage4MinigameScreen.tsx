import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { chooseStage4Option, STAGE4_CHOICES, stage4Zone } from '../../../packages/battle/stage4-minigame'
import { continueStage4Minigame } from '../../../packages/battle/stage4'
import { fitViewport } from '../../../packages/story/viewport'

const labels = {
  calm: '落ち着いた声で短く指示する',
  challenge: '明確な課題を提示する',
  neutral: '演習の手順を尋ねる',
  pisuke: 'ピー助に適切な強度を選んでもらう'
} as const

export function Stage4MinigameScreen({ save, onSave, onTitle }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onTitle: () => void
}) {
  const viewport = useRef<HTMLElement>(null)
  const ledger = save.progress.stage4_minigame
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

  async function choose(choice: (typeof STAGE4_CHOICES)[number]) {
    if (!ledger || busy || ledger.outcome) return
    setBusy(true); setError('')
    try { await onSave(chooseStage4Option(save, choice)) }
    catch { setError('選択を保存できませんでした。魔力ゲージは変わっていません。') }
    finally { setBusy(false) }
  }

  async function continueBattle() {
    if (!ledger?.outcome || busy) return
    setBusy(true); setError('')
    try { await onSave(continueStage4Minigame(save)) }
    catch { setError('再戦へ進めませんでした。訓練結果は保存されたままです。') }
    finally { setBusy(false) }
  }

  if (!ledger) return <main className="game-screen"><p role="alert">魔力調整の保存データがありません。</p>
    <button onClick={onTitle}>タイトルへ戻る</button></main>
  const zone = stage4Zone(ledger.gauge)
  const last = ledger.rounds.at(-1)
  return <main ref={viewport} className="story-viewport" aria-label="Stage 4 魔力調整">
    <div className="story-frame" data-testid="stage4-minigame-frame" style={{ width: fit.width, height: fit.height }}>
      <section className="story-stage stage3-review" data-testid="stage4-minigame" style={{ transform: `scale(${fit.scale})` }}>
        <header className="story-header"><div><p className="eyebrow">STAGE 4 · SELES</p><h1>魔力の強度を調整する</h1></div>
          <button onClick={onTitle} disabled={busy}>タイトルへ戻る</button></header>
        <p>相手の集中度を見て、演習の強度を合わせましょう。</p>
        <div className="stage2-gauge-row"><span>魔力集中度（{zone === 'red' ? '高' : zone === 'yellow' ? '中' : '低'}）</span>
          <progress aria-label="セレスの魔力集中度" max={130} value={ledger.gauge} />
          <output data-testid="stage4-gauge">{ledger.gauge}/130</output></div>
        {ledger.outcome ? <section className="stage2-result" data-testid="stage4-result">
          <h2>{ledger.outcome === 'win' ? '魔力の流れを安定させた' : '魔法の集中を止められなかった'}</h2>
          <p>訓練の結果にかかわらず、約束された再戦へ進みます。</p>
          <button disabled={busy} onClick={() => { void continueBattle() }}>再戦へ進む</button>
        </section> : <>
          <p className="stage2-round">調整 {ledger.rounds.length + 1} 回目</p>
          <div className="stage4-choice-grid">{STAGE4_CHOICES.map((choice) => <button key={choice} disabled={busy}
            data-choice={choice} onClick={() => { void choose(choice) }}>{labels[choice]}</button>)}</div>
          {last && <p role="status" data-testid="stage4-feedback">{last.delta < 0
            ? '強度が合った。魔力集中度が下がった。' : '強度が合わなかった。魔力集中度が少し上がった。'}</p>}
        </>}
        {error && <p role="alert" className="error-message">{error}</p>}
      </section>
    </div>
  </main>
}
