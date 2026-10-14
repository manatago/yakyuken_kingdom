import { useLayoutEffect, useRef } from 'react'
import type { BattleResult, Card } from '../../../packages/domain/card'
import { cardPresentation } from '../../../packages/cards/presentation'
import { originalShowdownCardFrames, originalShowdownGeometry, originalShowdownGradeReason,
  originalShowdownSource, originalShowdownTimeline } from '../../../packages/story/original-showdown'
import { originalAsset } from './original-assets'
import { cardImages } from './card-images'
import type { ContentPack } from '../../../packages/content/schema'
import { layoutStyle, originalCardLayout } from '../../../packages/content/layout'

const timeline = originalShowdownTimeline()
const geometry = originalShowdownGeometry(1920, 1080)

export function OriginalShowdown({ player, opponent, result, onComplete, onError, preview = false, layouts, cardsTestId }: {
  player: Card; opponent: Card; result: BattleResult; onComplete: () => void; onError: (cause: unknown) => void
  preview?: boolean; layouts?: Pick<ContentPack, 'layouts'>; cardsTestId?: string
}) {
  const root = useRef<HTMLDivElement>(null)
  const complete = useRef(onComplete)
  const failure = useRef(onError)
  useLayoutEffect(() => { complete.current = onComplete; failure.current = onError }, [onComplete, onError])
  useLayoutEffect(() => {
    const element = root.current!
    let alive = true
    const animations: Animation[] = []
    const animate = (target: Element, frames: Keyframe[]) => {
      const animation = target.animate(frames, { duration: timeline.duration, fill: 'both', easing: 'linear' })
      animations.push(animation)
      return animation
    }
    void Promise.all(Array.from(element.querySelectorAll('img')).map(image => image.decode())).then(() => {
      if (!alive) return
      for (const side of ['player', 'opponent'] as const) {
        for (const face of ['back', 'front'] as const) {
          animate(element.querySelector(`[data-showdown-track="${side}-${face}"]`)!,
            originalShowdownCardFrames(side, face === 'front', 1920, 1080))
        }
      }
      const resultStart = timeline.resultPop[0]
      const resultFrames: Keyframe[] = [{ offset: 0, transform: 'scale(.3)', opacity: 0 },
        { offset: resultStart / timeline.duration, transform: 'scale(.3)', opacity: 0 }]
      timeline.backOut.forEach((progress, index) => {
        const time = resultStart + (timeline.resultPop[1] - resultStart) * index / 60
        resultFrames.push({ offset: time / timeline.duration, transform: `scale(${.3 + .7 * progress})`,
          opacity: Math.min(1, (time - resultStart) / (originalShowdownSource.resultAlphaSeconds * 1000)) })
      })
      resultFrames.push({ offset: 1, transform: 'scale(1)', opacity: 1 })
      animate(element.querySelector('[data-showdown-track="result"]')!, resultFrames)
      animate(element.querySelector('[data-showdown-track="reason"]')!, [
        { offset: 0, opacity: 0 }, { offset: resultStart / timeline.duration, opacity: 0 },
        { offset: resultStart / timeline.duration, opacity: 1 }, { offset: 1, opacity: 1 }])
      const fade = animate(element, [{ offset: 0, opacity: 1 },
        { offset: timeline.fade[0] / timeline.duration, opacity: 1 }, { offset: 1, opacity: 0 }])
      if (preview) {
        animations.forEach(animation => { animation.pause(); animation.currentTime = timeline.resultPop[1] })
        return
      }
      return fade.finished.then(() => { if (alive) complete.current() })
    }).catch(cause => { if (alive) failure.current(cause) })
    return () => { alive = false; animations.forEach(animation => animation.cancel()) }
  }, [player.hand, player.grade, opponent.hand, opponent.grade, result, preview])
  const reason = originalShowdownGradeReason(player, opponent)
  return <div ref={root} data-testid="original-showdown" role="status" aria-label="じゃんけんの勝負演出"
    style={{ position: 'absolute', inset: 0, background: `rgba(0,0,0,${originalShowdownSource.dimAlpha})`, zIndex: 100, pointerEvents: 'none' }}>
    <div data-showdown-cards data-testid={cardsTestId} data-layout-id={layouts ? 'layout.cards.showdown' : undefined}
      style={{ position: 'absolute', left: geometry.playerEndX, top: geometry.y,
        width: geometry.opponentEndX - geometry.playerEndX + geometry.width, height: geometry.height,
        pointerEvents: preview ? 'auto' : 'none', ...(layouts ? layoutStyle(originalCardLayout(layouts, 'layout.cards.showdown')) : {}) }}>
    {(['player', 'opponent'] as const).flatMap(side => (['back', 'front'] as const).map(face =>
      <img key={`${side}-${face}`} data-showdown-track={`${side}-${face}`} alt={face === 'back' ? '' : `${side === 'player' ? '自分' : '相手'}のカード`}
        src={face === 'back' ? originalAsset(originalShowdownSource.cardBack) : cardImages[cardPresentation(side === 'player' ? player : opponent).id]}
        style={{ position: 'absolute', left: -geometry.playerEndX, top: 0, width: geometry.width, height: geometry.height,
          objectFit: 'contain', transformOrigin: 'center', opacity: 0 }} />)) }
    </div>
    <img data-showdown-track="result" alt={result === 'win' ? '勝ち' : result === 'lose' ? '負け' : 'あいこ'}
      src={originalAsset(originalShowdownSource.resultTextures[result])}
      style={{ position: 'absolute', left: '20%', top: '25%', width: '60%', height: '40%', objectFit: 'contain', opacity: 0 }} />
    <div data-showdown-track="reason" style={{ position: 'absolute', left: '10%', top: '68%', width: '80%', height: '10%',
      display: 'grid', placeItems: 'center', textAlign: 'center', fontSize: 24, color: 'rgb(255,229.5,114.75)', opacity: 0 }}>{reason}</div>
  </div>
}
