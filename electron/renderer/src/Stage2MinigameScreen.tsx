import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { askPisukeForStage2Minigame, chooseStage2Expression, continueToStage2Rematch, STAGE2_EXPRESSIONS,
  isStage2PickCorrect, STAGE2_MINIGAME_SCENES } from '../../../packages/battle/stage2-minigame'
import { fitViewport } from '../../../packages/story/viewport'
import layla from '../../../godot/assets/characters/main/layla/clothed/layla_clothed_001.png?url'

const labels = {
  shake: '手が震えている',
  blush: '顔が赤くなっている',
  sweat: '汗をかいている',
  panic: '全体的に取り乱している'
} as const

const prompts = [
  '周囲の視線に気づいたようです。どこに動揺が出ていますか？',
  '服装のことを話題にしました。相手の反応を見てください。',
  '相手の手元に変化がありました。どんな反応でしょう？',
  '緊張を誘う質問をしました。表情の変化を選んでください。',
  '後ろから見られているかもしれない、と伝えました。',
  '予想外の話題に、相手の反応が変わりました。',
  '聞き慣れない言葉を出しました。どこに動揺が表れていますか？',
  '思いがけない質問です。相手の表情をよく見てください。',
  '少し踏み込んだ話題を出しました。反応を見抜きましょう。',
  '最後の質問です。相手の動揺を指摘してください。'
] as const

const expressionClues = {
  shake: '手元にかすかな震えが見える。',
  blush: '頬が少し赤くなり、顔に動揺が出ている。',
  sweat: '額に汗がにじみ、緊張しているようだ。',
  panic: '視線が泳ぎ、全体的に落ち着きを失っている。'
} as const

export function Stage2MinigameScreen({ save, onSave, onTitle }: {
  save: SaveData
  onSave: (save: SaveData) => Promise<void>
  onTitle: () => void
}) {
  const viewport = useRef<HTMLElement>(null)
  const ledger = save.progress.stage2_minigame
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const sceneIndex = ledger?.scene_order[ledger.current_scene]
  const expression = sceneIndex === undefined ? undefined : STAGE2_MINIGAME_SCENES[sceneIndex]
  const complete = !!ledger?.outcome
  const previousPick = ledger?.picks.at(-1)
  const previousWasCorrect = ledger && previousPick
    ? isStage2PickCorrect(ledger.scene_order[ledger.current_scene - 1]!, previousPick) : undefined

  useLayoutEffect(() => {
    const element = viewport.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize()
    const observer = new ResizeObserver(resize)
    observer.observe(element)
    return () => observer.disconnect()
  }, [])

  async function answer(expression: typeof STAGE2_EXPRESSIONS[number]) {
    if (!ledger || busy || complete) return
    setBusy(true); setError('')
    try { await onSave(chooseStage2Expression(save, expression)) }
    catch { setError('保存に失敗しました。回答は確定していません。') }
    finally { setBusy(false) }
  }

  async function askPisuke() {
    if (!ledger || busy || complete) return
    setBusy(true); setError('')
    try { await onSave(askPisukeForStage2Minigame(save)) }
    catch { setError('保存に失敗しました。回答は確定していません。') }
    finally { setBusy(false) }
  }

  async function rematch() {
    if (!complete || busy) return
    setBusy(true); setError('')
    try { await onSave(continueToStage2Rematch(save)) }
    catch { setError('保存に失敗しました。再戦には進んでいません。') }
    finally { setBusy(false) }
  }

  if (!ledger) return <main className="stage2-minigame"><p role="alert">ミニゲームの保存データがありません。</p>
    <button onClick={onTitle}>タイトルへ戻る</button></main>

  return <main ref={viewport} className="story-viewport" aria-label="レイラの表情読み">
    <div className="story-frame" data-testid="stage2-frame" style={{ width: fit.width, height: fit.height }}>
    <div className="story-stage stage2-minigame" style={{ transform: `scale(${fit.scale})` }}>
    <header className="stage2-minigame-header">
      <div><p className="eyebrow">STAGE 2 · LAYLA</p><h1>相手の動揺を見抜け</h1></div>
      <button onClick={onTitle} disabled={busy}>タイトルへ戻る</button>
    </header>
    <section className="stage2-minigame-panel" data-testid="stage2-minigame">
      <div className="stage2-gauge-row"><span>冷静度</span><progress aria-label="レイラの冷静度" max={130} value={ledger.gauge} />
        <output data-testid="stage2-gauge">{ledger.gauge}/130</output></div>
      <img className="stage2-layla" src={layla} alt="検証中のレイラ" />
      {complete ? <div className="stage2-result" data-testid="stage2-result">
        <h2>{ledger.outcome === 'win' ? 'レイラの動揺を見抜いた' : 'レイラの冷静さを崩せなかった'}</h2>
        <p>初戦後の再検証は続きます。結果にかかわらず、再戦へ進みます。</p>
        <button disabled={busy} onClick={() => { void rematch() }}>再戦へ進む</button>
      </div> : <>
        <p className="stage2-round">質問 {ledger.current_scene + 1} / {ledger.scene_order.length}</p>
        <p className="stage2-prompt" data-testid="stage2-prompt">{prompts[ledger.current_scene]}</p>
        <p className="stage2-expression" aria-label="相手の表情" data-testid="stage2-expression">
          {expression ? expressionClues[expression] : 'レイラは質問を聞き、わずかに表情を変えた。'}
        </p>
        {previousPick && <p role="status" data-testid="stage2-feedback">前の回答：{previousWasCorrect ? '正解。冷静度が下がった。' : '違うようだ。冷静度が少し上がった。'}</p>}
        <div className="stage2-expression-choices" aria-label="表情の選択肢">
          {STAGE2_EXPRESSIONS.map((expression) => <button key={expression} disabled={busy}
            onClick={() => { void answer(expression) }}>{labels[expression]}</button>)}
          <button className="stage2-pisuke-choice" disabled={busy}
            onClick={() => { void askPisuke() }}>ピー助に任せる</button>
        </div>
      </>}
      {error && <p className="error-message" role="alert">{error}</p>}
    </section>
    </div>
    </div>
  </main>
}
