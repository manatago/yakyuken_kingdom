import { useLayoutEffect, useRef, useState, type RefObject } from 'react'
import type { OriginalCommand } from '../../../packages/story/original'
import source from '../../../content/stories/godot-terminal-effect.json'

/** The original waits for input after typing; hold_time is not used by StoryScene. */
export function OriginalTerminalEffect({ command, inputRef, onComplete }: {
  command: OriginalCommand; inputRef: RefObject<(() => void) | null>; onComplete: () => void
}) {
  const overlay = useRef<HTMLDivElement>(null)
  const label = useRef<HTMLPreElement>(null)
  const done = useRef(onComplete)
  done.current = onComplete
  const [text, setText] = useState('')
  const [phase, setPhase] = useState('fading-in')
  useLayoutEffect(() => {
    let cancelled = false, skipRequested = false
    let close: (() => void) | undefined
    const timers = new Map<ReturnType<typeof setTimeout>, () => void>()
    const animations = new Set<Animation>()
    const wait = (ms: number) => new Promise<void>(resolve => {
      const timer = setTimeout(() => { timers.delete(timer); resolve() }, ms)
      timers.set(timer, resolve)
    })
    const animate = async (element: HTMLElement, frames: Keyframe[], duration: number) => {
      const animation = element.animate(frames, { duration, fill: 'forwards', easing: 'linear' })
      animations.add(animation)
      await animation.finished.catch(() => {})
    }
    inputRef.current = () => {
      if (!skipRequested) skipRequested = true
      else close?.()
    }
    async function play() {
      const p = command.parameters
      const lines = p.lines as string[]
      await animate(overlay.current!, [{ backgroundColor: 'rgba(0,0,0,0)' }, { backgroundColor: 'rgba(0,0,0,.6)' }], source.timings.fade_in)
      if (cancelled) return
      setPhase('glitch')
      overlay.current!.style.backgroundColor = 'rgba(25.5,76.5,25.5,.7)'
      // Remove the filled fade-in effect before the explicit glitch colors.
      for (const animation of animations) animation.cancel()
      await wait(source.timings.glitch)
      if (cancelled) return
      overlay.current!.style.backgroundColor = 'rgba(0,0,0,.6)'
      await wait(source.timings.glitch_after)
      if (cancelled) return
      setPhase('typing')
      let full = ''
      for (let index = 0; index < lines.length; index++) {
        if (skipRequested || cancelled) break
        for (const char of lines[index]) {
          if (skipRequested || cancelled) break
          full += char
          setText(full + '█')
          await wait(Number(p.char_delay) * 1000)
        }
        full += '\n'
        if (!cancelled) setText(full)
        if (!skipRequested && index < lines.length - 1) await wait(Number(p.line_delay) * 1000)
      }
      if (cancelled) return
      if (skipRequested) full = lines.join('\n') + '\n'
      setText(full.replace(/█$/, '') + '█')
      skipRequested = false
      setPhase('waiting')
      await new Promise<void>(resolve => { close = resolve })
      if (cancelled) return
      setPhase('fading-out')
      overlay.current!.style.backgroundColor = 'rgba(51,255,77,.4)'
      await wait(source.timings.flash)
      if (cancelled) return
      await Promise.all([
        animate(overlay.current!, [{ backgroundColor: 'rgba(51,255,76.5,.4)' }, { backgroundColor: 'rgba(51,255,76.5,0)' }], source.timings.fade_out),
        animate(label.current!, [{ opacity: 1 }, { opacity: 0 }], source.timings.text_fade_out)
      ])
      if (!cancelled) done.current()
    }
    void play()
    return () => {
      cancelled = true
      inputRef.current = null
      close?.()
      for (const [timer, resolve] of timers) { clearTimeout(timer); resolve() }
      for (const animation of animations) animation.cancel()
    }
  }, [command, inputRef])
  return <>
    <div ref={overlay} data-terminal-phase={phase} style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }} />
    <pre ref={label} data-testid="original-terminal" style={{ position: 'absolute', left: source.style.rect[0], top: source.style.rect[1],
      width: source.style.rect[2], height: source.style.rect[3], margin: 0,
      fontFamily: 'inherit', fontSize: source.style.font_size, whiteSpace: 'pre-wrap',
      color: `rgba(${source.style.color.slice(0, 3).map(value => value * 255).join(',')},${source.style.color[3]})`, pointerEvents: 'none' }}>{text}</pre>
  </>
}
