import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { continueStage3Minigame } from '../../../packages/battle/stage3'
import { askPisukeForStage3Minigame, chooseStage3Evidence, STAGE3_CHAPTERS, STAGE3_EVIDENCE,
  STAGE3_GAUGE_LIMIT } from '../../../packages/battle/stage3-minigame'
import { fitViewport } from '../../../packages/story/viewport'

export function Stage3MinigameScreen({ save, onSave, onTitle }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onTitle: () => void
}) {
  const ledger = save.progress.stage3_minigame
  const viewport = useRef<HTMLElement>(null)
  const [chapter, setChapter] = useState('')
  const [evidence, setEvidence] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const previous = ledger?.rounds.at(-1)

  useLayoutEffect(() => {
    if (!viewport.current) return
    const element = viewport.current
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize()
    const observer = new ResizeObserver(resize)
    observer.observe(element)
    return () => observer.disconnect()
  }, [])

  async function submit() {
    if (!ledger || !chapter || !evidence || busy || ledger.outcome) return
    setBusy(true); setError('')
    try {
      await onSave(chooseStage3Evidence(save, chapter, evidence, Array.from({ length: 9 }, () => Math.random())))
      setChapter(''); setEvidence('')
    }
    catch { setError('回答を保存できませんでした。記録の状態は変わっていません。') }
    finally { setBusy(false) }
  }

  async function askPisuke() {
    if (!ledger?.offer || busy || ledger.outcome) return
    setBusy(true); setError('')
    try { await onSave(askPisukeForStage3Minigame(save, Array.from({ length: 9 }, () => Math.random()))) }
    catch { setError('助言を保存できませんでした。記録の状態は変わっていません。') }
    finally { setBusy(false) }
  }

  async function continueToRematch() {
    if (!ledger?.outcome || busy) return
    setBusy(true); setError('')
    try { await onSave(continueStage3Minigame(save)) }
    catch { setError('再審査へ進めませんでした。結果は保存されたままです。') }
    finally { setBusy(false) }
  }

  if (!ledger) return <main className="game-screen"><p role="alert">証拠照合の保存データがありません。</p>
    <button onClick={onTitle}>タイトルへ戻る</button></main>

  return <main ref={viewport} className="story-viewport" aria-label="Stage 3 証拠照合">
    <div className="story-frame" data-testid="stage3-minigame-frame" style={{ width: fit.width, height: fit.height }}>
      <section className="story-stage stage3-review" data-testid="stage3-review" style={{ transform: `scale(${fit.scale})` }}>
        <header className="story-header"><div><p className="eyebrow">STAGE 3 · MAGDALENA</p><h1>記録を照合する</h1></div>
          <button onClick={onTitle} disabled={busy}>タイトルへ戻る</button></header>
        <p>記録の章と根拠資料を組み合わせ、審査の矛盾を見つけましょう。</p>
        <div className="stage2-gauge-row"><span>審査の混乱度</span>
          <progress aria-label="審査の混乱度" max={STAGE3_GAUGE_LIMIT} value={ledger.gauge} />
          <output data-testid="stage3-gauge">{ledger.gauge}/{STAGE3_GAUGE_LIMIT}</output></div>
        {ledger.outcome ? <section className="stage2-result" data-testid="stage3-result">
          <h2>{ledger.outcome === 'win' ? '矛盾を示せた' : '記録の照合に失敗した'}</h2>
          <p>どちらの結果でも、約束された再審査は行われます。</p>
          <button disabled={busy} onClick={() => { void continueToRematch() }}>再審査へ進む</button>
        </section> : <>
          <p className="stage2-round">照合 {ledger.rounds.length + 1} 回目 · 成功 {ledger.hits} 回</p>
          <div className="stage3-pairing">
            <fieldset><legend>審査記録の章</legend>{ledger.offer?.chapters.map((id) => <label key={id}>
              <input type="radio" name="stage3-chapter" value={id} checked={chapter === id}
                disabled={busy} onChange={() => setChapter(id)} />{STAGE3_CHAPTERS[id as keyof typeof STAGE3_CHAPTERS]}
            </label>)}</fieldset>
            <span aria-hidden="true">＋</span>
            <fieldset><legend>根拠資料</legend>{ledger.offer?.evidence.map((id) => <label key={id}>
              <input type="radio" name="stage3-evidence" value={id} checked={evidence === id}
                disabled={busy} onChange={() => setEvidence(id)} />{STAGE3_EVIDENCE[id as keyof typeof STAGE3_EVIDENCE]}
            </label>)}</fieldset>
          </div>
          <div className="stage3-review-actions">
            <button disabled={busy || !chapter || !evidence} onClick={() => { void submit() }}>この組み合わせで照合</button>
            <button disabled={busy} onClick={() => { void askPisuke() }}>ピー助に任せる</button>
          </div>
          {previous && <p role="status" data-testid="stage3-feedback">{previous.hit
            ? '一致する記録が見つかった。審査の混乱度が下がった。'
            : '根拠が結びつかない。審査の混乱度が少し上がった。'}</p>}
        </>}
        {error && <p role="alert" className="error-message">{error}</p>}
      </section>
    </div>
  </main>
}
