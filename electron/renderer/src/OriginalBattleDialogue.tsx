import { useEffect, useRef, type RefObject } from 'react'
import source from '../../../content/stories/godot-battle-dialogue.json'

export function useOriginalDialogueInput(section: RefObject<HTMLElement | null>, onAdvance: () => void, enabled = true) {
  const callback = useRef(onAdvance)
  callback.current = onAdvance
  useEffect(() => {
    if (!enabled) return
    const inScope = (target: EventTarget | null) => target === document.body || !!section.current?.closest('.story-viewport')?.contains(target as Node)
    const key = (event: KeyboardEvent) => {
      if (!inScope(event.target) || !['Enter', 'Space'].includes(event.code)) return
      event.preventDefault(); event.stopPropagation()
      if (!event.repeat) callback.current()
    }
    const pointer = (event: PointerEvent) => {
      if (event.button !== 0 || !inScope(event.target)) return
      if ((event.target as Element)?.closest('button,input,select,textarea,[role="dialog"],[data-original-highlight-target]')) return
      event.preventDefault(); event.stopPropagation(); callback.current()
    }
    window.addEventListener('keydown', key, true)
    window.addEventListener('pointerdown', pointer, true)
    return () => { window.removeEventListener('keydown', key, true); window.removeEventListener('pointerdown', pointer, true) }
  }, [enabled])
}

export function OriginalBattleDialogue({ text, speaker = '', mode = 'battle', testId, textTestId, onAdvance, waitForInput = true, bodyVisible = true }: {
  text: string; speaker?: string; mode?: 'battle' | 'selection' | 'minigame'
  testId?: string; textTestId?: string; onAdvance: () => void; waitForInput?: boolean
  bodyVisible?: boolean
}) {
  const section = useRef<HTMLElement>(null)
  useOriginalDialogueInput(section, onAdvance, waitForInput)
  const geometry = source.cases.find(entry => entry.mode === mode && entry.speaker === (speaker ? 'speaker' : 'narrator'))!
  return <section ref={section} tabIndex={0} data-original-dialogue={waitForInput ? 'active' : 'passive'} data-testid={testId}
    style={{ position: 'absolute', left: geometry.band[0], top: geometry.band[1], width: geometry.band[2], height: geometry.band[3],
      background: `rgba(${geometry.color.slice(0, 3).map(value => value * 255).join(',')},${geometry.color[3]})`, color: 'white', textAlign: 'left' }}>
    {speaker && <div style={{ position: 'absolute', left: geometry.speaker_rect[0], top: geometry.speaker_rect[1] - geometry.band[1],
      width: geometry.speaker_rect[2], fontSize: geometry.speaker_font_size, lineHeight: `${geometry.speaker_rect[3]}px` }}>{speaker}</div>}
    <div data-testid={textTestId} style={{ position: 'absolute', visibility: bodyVisible ? 'visible' : 'hidden', left: geometry.body[0], top: geometry.body[1] - geometry.band[1],
      width: geometry.body[2], fontSize: geometry.font_size, lineHeight: `${geometry.line_height}px`, whiteSpace: 'pre-wrap', overflowWrap: 'break-word' }}>{text}</div>
  </section>
}
