import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { enterGuildHome } from '../../../packages/guild/home'
import { continueSubevent3ToBattle } from '../../../packages/battle/subevent3'
import { chooseSubevent3Option, SUBEVENT3_CHOICES, type Subevent3ChoiceId } from '../../../packages/battle/subevent3-minigame'
import { fitViewport } from '../../../packages/story/viewport'
import nobleRoom from '../../../godot/assets/backgrounds/subevent3/bg_noble_room.png?url'
import fiona from '../../../godot/assets/characters/main/fiona/clothed/fiona_clothed_001.png?url'

const labels = new Map<Subevent3ChoiceId, string>(SUBEVENT3_CHOICES.map(({ id, label }) => [id, label]))
labels.set('pisuke', 'ピー助に任せる')

export function Subevent3MinigameScreen({ save, onSave, onTitle }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onTitle: () => void
}) {
  const viewport = useRef<HTMLElement>(null)
  const ledger = save.progress.subevent3_minigame
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  useLayoutEffect(() => {
    const element = viewport.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize()
    const observer = new ResizeObserver(resize)
    observer.observe(element)
    return () => observer.disconnect()
  }, [])

  async function act(operation: () => SaveData, failure: string) {
    if (busy) return
    setBusy(true); setError('')
    try { await onSave(operation()) }
    catch { setError(failure) }
    finally { setBusy(false) }
  }

  if (!ledger) return <main className="stage2-minigame"><p role="alert">ミニゲームの保存データがありません。</p>
    <button onClick={onTitle}>タイトルへ戻る</button></main>

  const complete = !!ledger.outcome
  const previous = ledger.rounds.at(-1)
  return <main ref={viewport} className="story-viewport" aria-label="フィオナの呪いを弱める">
    <div className="story-frame" data-testid="subevent3-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage stage2-minigame" style={{ transform: `scale(${fit.scale})` }}>
        <header className="stage2-minigame-header">
          <div><p className="eyebrow">SUBEVENT 3 · FIONA</p><h1>呪いの鎧を弱める</h1></div>
          <button onClick={onTitle} disabled={busy}>タイトルへ戻る</button>
        </header>
        <section className="stage2-minigame-panel" data-testid="subevent3-minigame">
          <div className="stage2-gauge-row"><span>鎧の加護</span><progress aria-label="鎧の加護" max={130} value={ledger.gauge} />
            <output data-testid="subevent3-gauge">{ledger.gauge}/130</output></div>
          <div className="subevent3-minigame-scene" style={{ backgroundImage: `url(${nobleRoom})` }}>
            <img src={fiona} alt="鎧を着たフィオナ" />
          </div>
          {complete ? <div className="stage2-result" data-testid="subevent3-result">
            <h2>{ledger.outcome === 'win' ? '呪いの加護が弱まった' : '鎧の加護が強まった'}</h2>
            <p>{ledger.outcome === 'win' ? 'フィオナの同意を得て、最後の試練へ進みます。' : '一度ギルドへ戻り、準備を整えて再挑戦できます。'}</p>
            {ledger.outcome === 'win'
              ? <button disabled={busy} onClick={() => { void act(() => continueSubevent3ToBattle(save), '保存に失敗しました。戦闘へ進んでいません。') }}>フィオナとの勝負へ</button>
              : <button disabled={busy} onClick={() => { void act(() => enterGuildHome(save), '保存に失敗しました。ギルドへ戻っていません。') }}>ギルドへ戻る</button>}
          </div> : <>
            <p className="stage2-round">対話 {ledger.rounds.length + 1}回目</p>
            <p className="stage2-prompt" data-testid="subevent3-prompt">真言の水晶に、鎧が反応している。</p>
            {previous && <p role="status">前の言葉に、鎧の加護が{previous.delta > 0 ? '強く反応した' : previous.delta < 0 ? '弱まった' : '反応しなかった'}。</p>}
            <div className="stage2-expression-choices" aria-label="フィオナへの言葉">
              {ledger.choices?.map((choice) => <button key={choice} disabled={busy} onClick={() => {
                void act(() => chooseSubevent3Option(save, choice, Array.from({ length: 4 }, () => Math.random())), '保存に失敗しました。選択は確定していません。')
              }}>{labels.get(choice)}</button>)}
            </div>
          </>}
          {error && <p className="error-message" role="alert">{error}</p>}
        </section>
      </div>
    </div>
  </main>
}
