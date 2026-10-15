import { useId, useLayoutEffect, useRef, type RefObject } from 'react'
import { originalBackgroundColorMatrix } from '../../../packages/story/original-visual-style'

export function useOriginalFade(ref: RefObject<HTMLElement | null>, identity: string, visible: boolean,
  duration: number, kind: 'portrait' | 'background', trigger?: unknown) {
  const previous = useRef<{ identity: string; visible: boolean; node: HTMLElement } | undefined>(undefined)
  const previousTrigger = useRef<unknown>(undefined)
  const started = useRef(false)
  const cleanup = useRef<() => void>(() => {})
  useLayoutEffect(() => {
    const element = ref.current
    if (!element) return
    started.current = false
    const old = previous.current
    if (old && (old.identity !== identity || kind === 'background' && trigger && trigger !== previousTrigger.current)) {
      if (old.visible && visible && duration > 0) {
        const snapshot = old.node.cloneNode(true) as HTMLElement
        // cloneNode does not include Web Animation state; Godot copies the slot's
        // current modulate/position/scale into its outgoing TextureRect.
        const computed = getComputedStyle(element)
        for (const animation of element.getAnimations()) {
          const effect = animation.effect
          if (!(effect instanceof KeyframeEffect) || effect.target !== element) continue
          const frames = effect.getKeyframes()
          for (const property of ['opacity', 'translate', 'transform', 'left', 'top']) {
            if (frames.some(frame => property in frame)) {
              snapshot.style.setProperty(property, computed.getPropertyValue(property))
            }
          }
        }
        cleanup.current()
        snapshot.setAttribute('data-original-snapshot', kind)
        snapshot.setAttribute('aria-hidden', 'true')
        snapshot.removeAttribute('data-testid')
        snapshot.querySelectorAll('[data-testid]').forEach(node => node.removeAttribute('data-testid'))
        element.before(snapshot)
        started.current = true
        element.dataset.originalFade = kind
        const animation = element.animate([{ opacity: 0 }, { opacity: 1 }], { duration, easing: 'linear', fill: 'both' })
        let outgoing: Animation | undefined
        let cancelled = false
        cleanup.current = () => { cancelled = true; animation.cancel(); outgoing?.cancel(); snapshot.remove() }
        void animation.finished.then(async () => {
          if (cancelled) return
          if (kind === 'background') {
            outgoing = snapshot.animate([{ opacity: 1 }, { opacity: 0 }], { duration, easing: 'linear', fill: 'both' })
            await outgoing.finished
          }
          if (!cancelled) { snapshot.remove(); animation.cancel() }
        }).catch(() => {})
      } else cleanup.current()
    }
    previous.current = { identity, visible, node: element.cloneNode(true) as HTMLElement }
    previousTrigger.current = trigger
  })
  useLayoutEffect(() => () => cleanup.current(), [])
  return started
}

export function OriginalBackground({ path, duration, trigger, filtered = false }: { path: string; duration: number; trigger?: unknown; filtered?: boolean }) {
  const ref = useRef<HTMLImageElement>(null)
  const filterId = useId()
  useOriginalFade(ref, path, true, duration, 'background', trigger)
  return <>
    <svg width="0" height="0" aria-hidden="true" style={{ position: 'absolute' }}>
      <defs><filter id={filterId}><feColorMatrix data-testid="original-background-color-matrix"
        type="matrix" colorInterpolationFilters="sRGB" values={originalBackgroundColorMatrix} /></filter></defs>
    </svg>
    <img ref={ref} className="story-background" alt="背景" src={path} style={{ filter: filtered ? `url("#${filterId}")` : undefined }} />
  </>
}
