import { useLayoutEffect, useRef, useState } from 'react'
import { originalBubbleLayout } from '../../../packages/story/original-bubble'
import { originalAsset } from './original-assets'
import { useOriginalDialogueInput } from './OriginalBattleDialogue'

export function OriginalBattleBubble({ text, side, visibleCharacters, testId, textTestId, onAdvance, waitForInput = true, revision = 0, onReady }: {
  text: string; side: string; visibleCharacters: number; testId?: string; textTestId?: string; onAdvance: () => void; waitForInput?: boolean
  revision?: number; onReady?: () => void
}) {
  const section = useRef<HTMLElement>(null)
  const indicator = useRef<HTMLSpanElement>(null)
  const snapshot = useRef<HTMLElement | null>(null)
  const latest = useRef(onReady)
  latest.current = onReady
  const [ready, setReady] = useState(false)
  useOriginalDialogueInput(section, onAdvance, waitForInput && ready)
  const layout = originalBubbleLayout(text, side)
  useLayoutEffect(() => {
    const node = section.current!
    let active = true
    const ghost = snapshot.current?.cloneNode(true) as HTMLElement | undefined
    const animations: Animation[] = []
    setReady(false)
    node.style.opacity = '0'
    if (ghost) {
      ghost.removeAttribute('data-original-dialogue'); ghost.removeAttribute('data-testid'); ghost.removeAttribute('tabindex')
      ghost.querySelectorAll('[data-testid]').forEach(child => child.removeAttribute('data-testid'))
      ghost.setAttribute('aria-hidden', 'true'); ghost.style.pointerEvents = 'none'
      node.parentElement!.appendChild(ghost)
    }
    void (async () => {
      try {
        if (ghost) {
          const fade = ghost.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 150, fill: 'forwards' })
          animations.push(fade); await fade.finished; ghost.remove()
        }
        if (!active) return
        const fade = node.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 200, fill: 'forwards' })
        animations.push(fade); await fade.finished
        if (active) { node.style.opacity = '1'; fade.cancel(); setReady(true); latest.current?.() }
      } catch { /* Cancellation on navigation does not advance the saved game. */ }
    })()
    return () => { active = false; animations.forEach(animation => animation.cancel()); ghost?.remove() }
  }, [text, side, revision])
  useLayoutEffect(() => { snapshot.current = section.current?.cloneNode(true) as HTMLElement }, [text, side, visibleCharacters, ready])
  const complete = ready && visibleCharacters >= layout.wrapped.length
  useLayoutEffect(() => {
    if (!complete || !indicator.current) return
    const pulse = indicator.current.animate([{ opacity: 1 }, { opacity: .35 }, { opacity: 1 }], { duration: 1000, iterations: Infinity })
    return () => pulse.cancel()
  }, [complete])
  return <section ref={section} tabIndex={0} data-original-dialogue={waitForInput ? 'active' : 'passive'} data-testid={testId} data-bubble-side={side} data-bubble-ready={ready}
    style={{ position: 'absolute', left: layout.rect[0], top: layout.rect[1], width: layout.rect[2], height: layout.rect[3],
      borderImage: `url(${originalAsset('res://assets/ui/speech_bubble_2_small.png')}) 8 fill / 8px` }}>
    <div data-testid={textTestId} style={{ position: 'absolute', left: layout.body[0] - layout.rect[0], top: layout.body[1] - layout.rect[1],
      width: layout.body[2], height: layout.body[3], fontSize: layout.font_size, lineHeight: `${layout.line_height}px`,
      color: 'rgb(51,38,26)', whiteSpace: 'pre-wrap', overflowWrap: 'break-word', overflow: 'hidden' }}>{layout.wrapped.slice(0, visibleCharacters)}</div>
    {complete && <span ref={indicator} aria-hidden="true" style={{ position: 'absolute', right: 20, bottom: 18, width: 40, height: 40,
      textAlign: 'right', fontSize: 28, lineHeight: '40px', color: 'rgb(77,56,31)', WebkitTextStroke: '4px rgba(255,242,191,.9)', paintOrder: 'stroke fill', pointerEvents: 'none' }}>▼</span>}
  </section>
}
