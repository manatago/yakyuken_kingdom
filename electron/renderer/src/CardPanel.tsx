import { useState } from 'react'
import type { Card } from '../../../packages/domain/card'
import type { SavePlayer } from '../../../packages/domain/save'
import { cardPresentation } from '../../../packages/cards/presentation'
import { CardView } from './CardView'
import type { ContentPack } from '../../../packages/content/schema'
import { cardLayout, layoutStyle } from '../../../packages/content/layout'

export function CardPanel({ player, layouts = [] }: { player: SavePlayer; layouts?: ContentPack['layouts'] }) {
  const [preview, setPreview] = useState<Card | null>(null)
  const overflow = player.deck.slice(9)
  function cardButton(card: Card, index: number) {
    const view = cardPresentation(card)
    return <button key={index} className="card-button" aria-label={`${view.handLabel} ${view.gradeLabel}`}
      onClick={() => setPreview(card)}><CardView card={card} /><span className="card-hand">{view.handLabel}</span></button>
  }
  return <>
    <aside className="card-box" data-testid="card-box" aria-label="所持カード" data-layout-id="layout.cards.box"
      style={layoutStyle(cardLayout({ layouts }, 'layout.cards.box'))}>
      <h2>カードボックス</h2>
      <p>所持 {player.inventory.length}枚（デッキ分を含む）</p>
      <div className="card-grid">{player.inventory.map(cardButton)}</div>
    </aside>
    <aside className="deck-panel" data-testid="deck-panel" aria-label="デッキ・手札" data-layout-id="layout.cards.deck"
      style={{ ...layoutStyle(cardLayout({ layouts }, 'layout.cards.deck')), width: 1220 }}>
      <h2>デッキ・手札 {overflow.length ? `9枠（保存${player.deck.length}枚）` : `${player.deck.length}/9`} <small>編集・対戦は準備中</small></h2>
      <div className="deck-grid">{Array.from({ length: 9 }, (_, index) =>
        player.deck[index] ? cardButton(player.deck[index], index)
          : <span key={index} className="empty-deck-slot" data-testid="empty-deck-slot">{index + 1}</span>)}</div>
    </aside>
    {overflow.length > 0 && <aside className="deck-overflow" data-testid="deck-overflow" aria-label="デッキ超過カード">
      <h2>超過カード {overflow.length}枚</h2>
      <p>9枠を超える保存内容です。保存データは変更しません。</p>
      <div className="overflow-grid">{overflow.map(cardButton)}</div>
    </aside>}
    <aside className="card-preview" data-testid="card-preview" aria-label="カード拡大表示">
      <h2>カード拡大表示</h2>
      {preview ? <CardView card={preview} compact={false} /> : <p>カードをクリックして確認</p>}
      <small>表示のみ・デッキや進行は変わりません</small>
    </aside>
  </>
}
