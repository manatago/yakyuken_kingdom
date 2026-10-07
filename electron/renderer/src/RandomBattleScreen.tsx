import { useLayoutEffect, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { fitViewport } from '../../../packages/story/viewport'
import { cardPresentation } from '../../../packages/cards/presentation'
import { getItemDefinition, isBattleUsable, type ItemId } from '../../../packages/domain/item-catalog'
import { CardView } from './CardView'
import { randomBattlePortraits, type RandomPortraitPhase } from './random-battle-portraits'
import guildStreet from '../../../godot/assets/backgrounds/stage1/bg06_st1_001.png?url'
import market from '../../../godot/assets/backgrounds/stage1/bg08_st1_001.png?url'
import tavern from '../../../godot/assets/backgrounds/stage1/bg09_st1_001.png?url'
import slum from '../../../godot/assets/backgrounds/stage1/bg10_st1_001.png?url'
import outside from '../../../godot/assets/backgrounds/stage1/bg11_st1_001.png?url'
import port from '../../../godot/assets/backgrounds/stage1/bg12_st1_001.png?url'
import { townContent, TOWN_CHECKPOINT, TOWN_ENCOUNTER_CHECKPOINT, RANDOM_BATTLE_CHECKPOINT,
  acceptTownEncounter, acknowledgeRandomBattleRound, continueTownAfterBattle, declineTownEncounter,
  enterTown, playRandomBattleRound, randomBattleDialogue, randomBattleProbabilities, randomBattleView,
  returnToGuildFromTown, settleRandomBattle, travelTown } from '../../../packages/battle/random'

const areaBackgrounds: Record<string, string> = {
  'godot/assets/backgrounds/stage1/bg06_st1_001.png': guildStreet,
  'godot/assets/backgrounds/stage1/bg08_st1_001.png': market,
  'godot/assets/backgrounds/stage1/bg09_st1_001.png': tavern,
  'godot/assets/backgrounds/stage1/bg10_st1_001.png': slum,
  'godot/assets/backgrounds/stage1/bg11_st1_001.png': outside,
  'godot/assets/backgrounds/stage1/bg12_st1_001.png': port
}

export function RandomBattleScreen({ save, onSave, onTitle }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onTitle: () => void
}) {
  const viewport = useRef<HTMLElement>(null), pending = useRef(false), proposal = useRef<SaveData | null>(null)
  const proposalAction = useRef<string | null>(null)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [selected, setSelected] = useState<number | null>(null), [selectedItem, setSelectedItem] = useState<ItemId | null>(null)
  const [busy, setBusy] = useState(false), [error, setError] = useState('')
  const [deckDraft, setDeckDraft] = useState<SaveData['player']['inventory']>([])
  const checkpoint = save.progress.checkpoint_id
  const ledger = save.progress.random_battle
  const area = townContent.areas[save.progress.town_area as keyof typeof townContent.areas]
  const background = areaBackgrounds[area?.background ?? '']
  if (!background) throw new Error('Unknown town area background')
  const view = ledger && (checkpoint === RANDOM_BATTLE_CHECKPOINT || ledger.settled) ? randomBattleView(save) : undefined
  const portraitPhase: RandomPortraitPhase | undefined = checkpoint === TOWN_ENCOUNTER_CHECKPOINT ? 'encounter'
    : checkpoint === RANDOM_BATTLE_CHECKPOINT ? 'battle'
      : checkpoint === TOWN_CHECKPOINT && ledger?.settled
        ? view?.outcome === 'win' ? 'farewell_win' : 'farewell_lose' : undefined
  const opponentPortrait = ledger && portraitPhase ? randomBattlePortraits[ledger.opponent_id]?.[portraitPhase] : undefined
  const resultPending = !!ledger && ledger.rounds.length > ledger.acknowledged
  const probabilities = checkpoint === RANDOM_BATTLE_CHECKPOINT && ledger ? randomBattleProbabilities(save,
    selected === null ? undefined : ledger.player_deck[selected], selectedItem ?? undefined)
    : { rock: 0, scissors: 0, paper: 0 }
  const alreadyUsedItems = ledger?.round_item_ids?.filter((id): id is ItemId => id !== null) ?? []
  const usableItems = (save.player.items ?? []).filter((id) => {
    const item = getItemDefinition(id)
    return item?.category === 'consumable' && isBattleUsable(item) &&
      alreadyUsedItems.filter((used) => used === id).length < (ledger?.items_before ?? []).filter((owned) => owned === id).length
  })
  const lastRoundItem = ledger?.round_item_ids?.at(-1)
  const protectsMinimumDeck = !!ledger && ledger.inventory_before.length <= 3
  const protectsLostCardWithItem = getItemDefinition(lastRoundItem ?? '')?.effect === 'protect_card'
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
    try {
      proposal.current ??= makeSave(); proposalAction.current = action
      await onSave(proposal.current)
      proposal.current = null; proposalAction.current = null; setSelected(null)
      if (action === 'play' || action === 'round-result') setSelectedItem(null)
      if (action === 'accept') setDeckDraft([])
    } catch { setError('保存に失敗しました。進行は変わっていません。同じ操作で再試行してください。') }
    finally { pending.current = false; setBusy(false) }
  }

  function rolls() {
    return { encounter: Math.random(), opponent: Math.random(),
      dialogue: [Math.random(), Math.random(), Math.random(), Math.random()] as const,
      cards: Array.from({ length: 3 }, () => ({ hand: Math.random(), grade: Math.random() })) as [
        { hand: number; grade: number }, { hand: number; grade: number }, { hand: number; grade: number }
      ], drop: Math.random() }
  }

  return <main ref={viewport} className="story-viewport" aria-label="街の探索とランダムバトル">
    <div className="story-frame" data-testid="random-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
        <img className="story-background" alt={`${area?.name ?? '街'}の背景`} src={background} />
        {opponentPortrait && ledger && portraitPhase && <img className="random-opponent-portrait"
          data-testid="random-opponent-portrait" data-portrait-phase={portraitPhase}
          alt={`${ledger.opponent_name}の立ち絵`} src={opponentPortrait} />}
        <header className="story-header"><h1>{checkpoint === RANDOM_BATTLE_CHECKPOINT ? `${ledger?.opponent_name ?? '相手'}とのランダム戦`
          : checkpoint === TOWN_ENCOUNTER_CHECKPOINT ? '街で遭遇' : `街：${area?.name ?? ''}`}</h1>
          <span>所持金 {save.player.money} G</span><span className="story-checkpoint" data-testid="checkpoint-id">{checkpoint}</span>
          <button disabled={busy} onClick={onTitle}>タイトルに戻る</button></header>

        {checkpoint === TOWN_ENCOUNTER_CHECKPOINT && ledger && <section className="random-panel" data-testid="random-encounter">
          <h2>{ledger.opponent_name}に呼び止められた</h2>
          <p className="random-dialogue" data-testid="random-dialogue-greeting">「{randomBattleDialogue(save, 'greeting')}」</p>
          <p>{area?.name}でランダム遭遇しました。所持カードから勝負に使う3枚を選んでください。</p>
          <div className="random-deck-builder" aria-label="勝負に使う3枚" data-testid="random-deck-builder">
            <p>選択中 {deckDraft.length}/3</p>
            <div className="deck-grid">{save.player.inventory.map((card, index) => {
              const presentation = cardPresentation(card)
              const selectedCount = deckDraft.filter((item) => item.hand === card.hand && item.grade === card.grade).length
              const inventoryCount = save.player.inventory.filter((item) => item.hand === card.hand && item.grade === card.grade).length
              return <button key={index} type="button" className="card-button" aria-label={`編成 ${presentation.handLabel} ${presentation.gradeLabel}`}
                disabled={busy || deckDraft.length >= 3 || selectedCount >= inventoryCount}
                onClick={() => setDeckDraft((draft) => [...draft, { ...card }])}>
                <CardView card={card} /><span className="card-hand">{presentation.handLabel} {presentation.gradeLabel}</span>
                {selectedCount > 0 && <span className="card-count">選択 {selectedCount}</span>}
              </button>
            })}</div>
            <ol aria-label="選択済みカード">{deckDraft.map((card, index) => <li key={`${card.hand}-${card.grade}-${index}`}>
              {cardPresentation(card).handLabel} {cardPresentation(card).gradeLabel}
              <button type="button" aria-label={`編成から外す ${cardPresentation(card).handLabel} ${cardPresentation(card).gradeLabel}`}
                disabled={busy} onClick={() => setDeckDraft((draft) => draft.filter((_, itemIndex) => itemIndex !== index))}>外す</button>
            </li>)}</ol>
          </div>
          <button disabled={disabled('accept') || deckDraft.length !== 3} onClick={() => { void commit('accept', () => acceptTownEncounter(save, deckDraft)) }}>3枚で勝負する</button>
          <button disabled={disabled('decline')} onClick={() => { void commit('decline', () => declineTownEncounter(save)) }}>今は避ける</button>
        </section>}

        {checkpoint === TOWN_CHECKPOINT && !ledger?.settled && <section className="random-panel" data-testid="town-area">
          <h2>{area?.name}</h2><p>{area?.description}</p>
          <p>ランダム戦はHP各1、3枚デッキです。負けるとカード1枚と所持金の一部を失います。</p>
          <nav aria-label="移動先" className="town-routes">{area?.connections.map((id) => <button key={id} disabled={disabled(`move:${id}`)}
            onClick={() => { void commit(`move:${id}`, () => travelTown(save, id, rolls())) }}>{townContent.areas[id as keyof typeof townContent.areas].name}へ</button>)}</nav>
          <button disabled={disabled('guild')} onClick={() => { void commit('guild', () => returnToGuildFromTown(save)) }}>ギルドホームへ戻る</button>
        </section>}

        {checkpoint === TOWN_CHECKPOINT && ledger?.settled && view && <section className="random-panel" data-testid="random-settlement">
          <h2>{view.outcome === 'win' ? `${ledger.opponent_name}に勝利` : view.outcome === 'lose' ? `${ledger.opponent_name}に敗北` : '引き分け'}</h2>
          <p className="random-dialogue" data-testid="random-dialogue-farewell">「{randomBattleDialogue(save, view.outcome === 'win' ? 'farewell_win' : 'farewell_lose')}」</p>
          <p>精算 {ledger.gold_delta! >= 0 ? '+' : ''}{ledger.gold_delta}G。カード{view.outcome === 'win' ? `を${ledger.bonus_capture_index === undefined ? '1' : '2'}枚獲得` : view.outcome === 'lose'
            ? protectsMinimumDeck ? 'は維持（街の対戦に必要な3枚を保護）'
              : protectsLostCardWithItem ? 'は維持（身代わりカードの効果）' : 'を1枚喪失' : 'の移動なし'}。</p>
          {view.outcome === 'win' && ledger.item_reward_id && <p data-testid="random-item-reward">{getItemDefinition(ledger.item_reward_id)?.name ?? ledger.item_reward_id}を獲得。</p>}
          <button disabled={disabled('continue')} onClick={() => { void commit('continue', () => continueTownAfterBattle(save)) }}>街の探索を続ける</button>
          <button disabled={disabled('guild')} onClick={() => { void commit('guild', () => returnToGuildFromTown(save)) }}>ギルドホームへ戻る</button>
        </section>}

        {checkpoint === RANDOM_BATTLE_CHECKPOINT && ledger && view && <>
          <aside className="belka-bayes" aria-label="相手の手の傾向"><h2>相手の手の目安</h2>
            <p>グー {Math.round(probabilities.rock * 100)}% ／ チョキ {Math.round(probabilities.scissors * 100)}% ／ パー {Math.round(probabilities.paper * 100)}%</p></aside>
          <aside className="deck-panel fixed-deck" aria-label="ランダム戦デッキ" data-testid="random-deck"
            style={{ left: 350, top: 800, right: 'auto', bottom: 'auto', width: 1220 }}>
            <h2>選択カード・残り {ledger.player_deck.length - view.usedPlayer.length}枚</h2>
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
          <section className="belka-controls" aria-label="ランダム戦の進行">
            {ledger.rounds.length === 0 && <p className="random-dialogue" data-testid="random-dialogue-start">「{randomBattleDialogue(save, 'battle_start')}」</p>}
            {!resultPending && !view.outcome && <div className="random-items">
              <label htmlFor="random-battle-item">この勝負で使うアイテム</label>
              <select id="random-battle-item" aria-label="この勝負で使うアイテム" value={selectedItem ?? ''}
                disabled={busy} onChange={(event) => setSelectedItem(event.target.value ? event.target.value as ItemId : null)}>
                <option value="">使わない</option>
                {usableItems.map((id, index) => <option key={`${id}-${index}`} value={id}>{getItemDefinition(id)?.name ?? id}</option>)}
              </select>
            </div>}
            {resultPending ? <div data-testid="random-result"><h2>{view.last!.result === 'win' ? '勝ち' : view.last!.result === 'lose' ? '負け' : '引き分け'}</h2>
              <p>あなたのHP {view.playerHp}/1 ・相手HP {view.opponentHp}/1</p>
              <button disabled={disabled('round-result')} onClick={() => { void commit('round-result', () => view.outcome
                ? settleRandomBattle(save, Math.random(), Math.random()) : acknowledgeRandomBattleRound(save)) }}>
                {view.outcome ? '結果を確定' : '引き分け・次のカードへ'}</button></div>
              : <><h2>カードを選択してください</h2><p>あなたのHP {view.playerHp}/1 ・相手HP {view.opponentHp}/1</p>
                <button disabled={disabled('play') || selected === null} onClick={() => { void commit('play', () => playRandomBattleRound(save, selected!, Math.random(), selectedItem ?? undefined)) }}>勝負！</button></>}
            {error && <p role="alert" className="error-message">{error}</p>}
          </section>
          {view.last && (resultPending || ledger.settled) && <section className="belka-showdown" aria-label="勝負カード">
            <div>あなた<CardView card={view.last.player} compact={false} /></div><div>{ledger.opponent_name}<CardView card={view.last.opponent} compact={false} /></div>
          </section>}
        </>}
        {error && checkpoint !== RANDOM_BATTLE_CHECKPOINT && <p role="alert" className="guild-error error-message">{error}</p>}
      </div>
    </div>
  </main>
}
