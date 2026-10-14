import { useLayoutEffect, useRef, useState } from 'react'
import { originalBattleHighlightArrow as arrow } from './original-assets'
import { originalHighlightPlacement, originalHighlightPulse } from '../../../packages/story/original-highlight'

export function OriginalBattleHighlight({ target, options }: { target: string; options: Record<string, unknown> }) {
  const image = useRef<HTMLImageElement>(null)
  const [placement, setPlacement] = useState<ReturnType<typeof originalHighlightPlacement>>()
  const optionKey = JSON.stringify(options)
  useLayoutEffect(() => {
    const stage = image.current?.closest('.story-stage')
    const control = stage?.querySelector(`[data-original-highlight-target="${target}"]`)
    if (!stage || !control) { setPlacement(undefined); return }
    const update = () => {
      const parent = stage.getBoundingClientRect(), rect = control.getBoundingClientRect(), scale = parent.width / 1920
      if (!scale || !rect.width || !rect.height) { setPlacement(undefined); return }
      setPlacement(originalHighlightPlacement(target,
        [(rect.left - parent.left) / scale, (rect.top - parent.top) / scale, rect.width / scale, rect.height / scale], JSON.parse(optionKey)))
    }
    update()
    const observer = new ResizeObserver(update)
    observer.observe(control)
    return () => observer.disconnect()
  }, [target, optionKey])
  useLayoutEffect(() => {
    const node = image.current
    if (!node || !placement) return
    const animation = node.animate(Array.from({ length: 81 }, (_, index) => {
      const seconds = index / 100, scale = originalHighlightPulse(seconds <= .4 ? seconds : .8 - seconds)
      return { offset: index / 80, transform: `rotate(${placement.rotation}rad) scale(${placement.flip ? -scale : scale},${scale})` }
    }), { duration: 800, iterations: Infinity })
    return () => animation.cancel()
  }, [placement])
  return <img ref={image} src={arrow} alt="" data-testid="original-battle-highlight" data-highlight-target={target}
    style={{ position: 'absolute', left: placement?.position[0], top: placement?.position[1], width: 192, height: 108,
      transformOrigin: '96px 54px', objectFit: 'contain', pointerEvents: 'none', visibility: placement ? 'visible' : 'hidden' }} />
}
