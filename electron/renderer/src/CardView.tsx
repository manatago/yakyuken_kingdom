import type { Card } from '../../../packages/domain/card'
import { cardPresentation, COMPACT_CROP } from '../../../packages/cards/presentation'
import { cardImages } from './card-images'

export function CardView({ card, compact = true }: { card: Card; compact?: boolean }) {
  const view = cardPresentation(card)
  const src = cardImages[view.id]
  const crop = COMPACT_CROP
  const imageStyle = compact ? {
    width: `${crop.sourceWidth / crop.width * 100}%`,
    height: `${crop.sourceHeight / crop.height * 100}%`,
    left: `${-crop.x / crop.width * 100}%`, top: `${-crop.y / crop.height * 100}%`
  } : undefined
  return <span className={`card-view ${compact ? 'card-compact' : 'card-full'}`} data-card-id={view.id}>
    {src ? <img src={src} alt={`${view.handLabel} ${view.gradeLabel}`} style={imageStyle} />
      : <span className="card-unavailable">{view.handLabel}<br />画像は未対応</span>}
    <span className="card-grade" aria-label={`グレード ${view.gradeLabel}`}>{view.gradeLabel}</span>
  </span>
}
