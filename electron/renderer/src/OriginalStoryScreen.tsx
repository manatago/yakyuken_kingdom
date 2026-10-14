import { useEffect, useLayoutEffect, useRef, useState, type ReactNode } from 'react'
import { executeOriginalCommand, originalPortraitLayout, originalPortraitSlots, originalStory,
  restoreOriginalStoryState, type OriginalCommand, type OriginalStoryState, type OriginalValue } from '../../../packages/story/original'
import { fitViewport } from '../../../packages/story/viewport'
import { originalAsset } from './original-assets'
import { originalMotionFrames } from '../../../packages/story/original-motion'
import { OriginalBackground, useOriginalFade } from './OriginalVisualTransitions'
import layoutContent from '../../../content/stories/matilda-tutorial.json'
import type { ContentPack } from '../../../packages/content/schema'
import { originalEditedPortraitLayout, type MatildaPortraitLayoutId } from '../../../packages/content/layout'
import type { SaveData } from '../../../packages/domain/save'
import { OriginalStoryInventory } from './OriginalStoryInventory'
import { OriginalTerminalEffect } from './OriginalTerminalEffect'

export function OriginalPortrait({ id, value, command, layoutId, layouts = layoutContent, rawLayout = false }: {
  id: string; value: OriginalStoryState['portraits'][string]; command?: OriginalCommand
  layoutId?: MatildaPortraitLayoutId; layouts?: Pick<ContentPack, 'layouts'>
  rawLayout?: boolean
}) {
  const ref = useRef<HTMLDivElement>(null)
  const animationRef = useRef<Animation | null>(null)
  const motionCommand = useRef<OriginalCommand | undefined>(undefined)
  const motionGeometry = useRef('')
  const [exiting, setExiting] = useState(false)
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 })
  const sourcePlacement = originalPortraitLayout(value, dimensions.width, dimensions.height, !rawLayout)
  const placement = layoutId ? originalEditedPortraitLayout(sourcePlacement, layouts, layoutId) : sourcePlacement
  const crossFade = useOriginalFade(ref, String(value.portrait_id), Boolean(value.visible),
    command?.parameters.character_id === id && command.parameters.transition === 'cross_fade'
      ? Number(command.parameters.transition_duration || 0) * 1000 : 0, 'portrait')
  useLayoutEffect(() => {
    const image = ref.current
    if (!image) return
    const matchingCommand = command?.parameters.character_id === id ? command : undefined
    const geometryKey = [placement.x, placement.y, placement.scale, dimensions.width, dimensions.height].join(':')
    const geometryChanged = geometryKey !== motionGeometry.current
    motionGeometry.current = geometryKey
    if (!matchingCommand && !geometryChanged) return
    const activeCommand = matchingCommand ?? motionCommand.current
    if (!activeCommand) return
    const sameMotion = activeCommand === motionCommand.current
    if (sameMotion && !geometryChanged) return
    const elapsed = sameMotion ? Number(animationRef.current?.currentTime ?? 0) : 0
    animationRef.current?.cancel()
    motionCommand.current = activeCommand
    setExiting(false)
    const p = activeCommand.parameters
    if (crossFade.current) { motionCommand.current = undefined; return }
    const leaving = activeCommand.kind === 'hide_character'
    const effect = String(p[leaving ? 'exit_effect' : 'appear_effect'] ?? '')
    const duration = Number(p[leaving ? 'exit_duration' : 'appear_duration']) * 1000
    if (!effect || !duration) { motionCommand.current = undefined; return }
    const side = String(value.side_override)
    const direction = String(p[leaving ? 'exit_to' : 'appear_from'] ||
      (side === 'right' ? 'right' : side === 'left' || leaving ? 'left' : 'top'))
    const distance = Number(p[leaving ? 'exit_distance' : 'appear_distance']) || 200
    const frames = originalMotionFrames(effect, leaving, direction, distance, placement, dimensions.width, dimensions.height)
    const animation = image.animate(frames, { duration, fill: 'both', easing: 'linear' })
    // Loading a differently sized texture changes its center, not the source tween's clock.
    if (sameMotion) animation.currentTime = elapsed
    animationRef.current = animation
    if (leaving) {
      setExiting(true)
      void animation.finished.then(() => { if (animationRef.current === animation) setExiting(false) }).catch(() => {})
    }
  }, [command, id, placement.flipped, placement.x, placement.y, placement.scale, dimensions.width, dimensions.height])
  useEffect(() => () => { animationRef.current?.cancel() }, [])
  if (!value.portrait_id) return null
  return <div ref={ref} data-layout-id={layoutId} style={{ position: 'absolute', left: placement.x, top: placement.y,
    width: dimensions.width || undefined, height: dimensions.height || undefined, transformOrigin: '0 0',
    transform: `scale(${placement.scale})`, display: value.visible || exiting ? 'block' : 'none', pointerEvents: layoutId ? 'auto' : 'none' }}>
    <img data-testid={`original-portrait-${id}`} alt={String(originalStory.cast[id]?.display_name || id)}
    src={originalAsset(String(value.portrait_id))} onLoad={event => setDimensions({
      width: event.currentTarget.naturalWidth, height: event.currentTarget.naturalHeight })}
    style={{ maxWidth: 'none',
      width: dimensions.width || undefined, height: dimensions.height || undefined,
      transform: placement.flipped ? 'scaleX(-1)' : undefined }} />
  </div>
}

function cssColor(value: OriginalValue): string {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return 'rgba(80,60,40,.85)'
  return `rgba(${Number(value.r) * 255},${Number(value.g) * 255},${Number(value.b) * 255},${Number(value.a)})`
}

/** Original-data playback surface. Battle commands are explicit suspension points, never skipped. */
export function OriginalStoryScreen({ sequenceId = 'prologue', cursor = 0, initialFlags, incomingScene, completedBattles, completed = false, onExit, onCheckpoint, onBattle, onComplete, ending, layouts, player, debugControls = false }: {
  sequenceId?: string; cursor?: number; onExit: () => void
  initialFlags?: Record<string, boolean>
  completedBattles?: readonly string[]
  completed?: boolean
  incomingScene?: OriginalStoryState
  onCheckpoint?: (state: OriginalStoryState) => Promise<void>
  onBattle?: (command: OriginalCommand, state: OriginalStoryState) => Promise<void>
  onComplete?: (state: OriginalStoryState) => Promise<void>
  ending?: ReactNode
  layouts?: Pick<ContentPack, 'layouts'>
  player?: SaveData['player']
  debugControls?: boolean
}) {
  const container = useRef<HTMLElement>(null)
  const running = useRef(false)
  const alive = useRef(true)
  const [state, setState] = useState(() => restoreOriginalStoryState(sequenceId, cursor, initialFlags, incomingScene))
  const stateRef = useRef(state)
  const [command, setCommand] = useState<OriginalCommand>()
  const [waiting, setWaiting] = useState(false)
  const [ended, setEnded] = useState(completed)
  const [error, setError] = useState('')
  const [visibleChars, setVisibleChars] = useState(0)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  const [terminal, setTerminal] = useState<OriginalCommand>()
  const terminalInput = useRef<(() => void) | null>(null)
  const terminalDone = useRef<(() => void) | null>(null)
  const readyAt = useRef(0)
  const pendingCommit = useRef<{ state: OriginalStoryState; resolve: () => void } | null>(null)

  // Child layout effects start the command's visual effects before this acknowledgement.
  useLayoutEffect(() => {
    const pending = pendingCommit.current
    if (pending?.state === state) {
      pendingCommit.current = null
      pending.resolve()
    }
  })

  useLayoutEffect(() => {
    const element = container.current!
    const resize = () => setFit(fitViewport(element.clientWidth, element.clientHeight))
    resize()
    const observer = new ResizeObserver(resize)
    observer.observe(element)
    return () => observer.disconnect()
  }, [])

  async function run() {
    if (running.current) return
    running.current = true
    setWaiting(false)
    try {
      while (alive.current) {
        const result = executeOriginalCommand(stateRef.current)
        const checkpoint = result.command
        if (!checkpoint || checkpoint.kind === 'battle' ||
            (['band', 'line'].includes(checkpoint.kind) && checkpoint.parameters.wait_for_input)) {
          await onCheckpoint?.(result.state)
        }
        stateRef.current = result.state
        await new Promise<void>(resolve => {
          pendingCommit.current = { state: result.state, resolve }
          setState(result.state); setCommand(result.command)
        })
        if (!alive.current) break
        const c = result.command
        if (!c) { setEnded(true); await onComplete?.(result.state); break }
        if (c.kind === 'battle') {
          if (completedBattles?.includes(`original:${sequenceId}:${result.state.cursor}`)) continue
          await onBattle?.(c, result.state); break
        }
        const p = c.parameters
        if ((c.kind === 'band' || c.kind === 'line') && p.wait_for_input) {
          setVisibleChars(0)
          readyAt.current = Date.now() + Number(p.min_duration || 0) * 1000
          setWaiting(true)
          break
        }
        if (c.kind === 'pause') await new Promise(resolve => setTimeout(resolve, Number(p.duration) * 1000))
        if (c.kind === 'hide_character') {
          const duration = p.wait_for_exit ? Number(p.exit_duration || 0) : 0
          if (duration || p.wait_after) await new Promise(resolve => setTimeout(resolve,
            (duration + Number(p.wait_after || 0)) * 1000))
        }
        if (c.kind === 'terminal_effect') {
          await new Promise<void>(resolve => { terminalDone.current = resolve; setTerminal(c) })
          setTerminal(undefined)
        }
        // Allow nonblocking appearance/background effects to paint before the next command.
        await new Promise(resolve => requestAnimationFrame(resolve))
      }
    } catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)) }
    finally { running.current = false }
  }

  useEffect(() => {
    alive.current = true
    if (completed) return () => { alive.current = false }
    if (cursor && !completedBattles?.includes(`original:${sequenceId}:${cursor}`) && ['line', 'band', 'battle'].includes(originalStory.sequences.find(s => s.id === sequenceId)!.commands[cursor - 1]?.kind)) {
      const c = originalStory.sequences.find(s => s.id === sequenceId)!.commands[cursor - 1]
      setCommand(c); setWaiting(c.kind !== 'battle'); setVisibleChars(stateRef.current.text.length)
      if (c.kind === 'battle' && onBattle) void onBattle(c, stateRef.current).catch(cause =>
        setError(cause instanceof Error ? cause.message : String(cause)))
    } else void run()
    return () => {
      alive.current = false
      pendingCommit.current?.resolve()
      pendingCommit.current = null
      terminalDone.current?.()
      terminalDone.current = null
    }
  }, [])

  useEffect(() => {
    if (!waiting) return
    const timer = setInterval(() => setVisibleChars(n => Math.min(n + 1, state.text.length)), 30)
    return () => clearInterval(timer)
  }, [waiting, state.text])

  const advance = () => {
    if (terminalInput.current) { terminalInput.current(); return }
    if (!waiting || Date.now() < readyAt.current) return
    if (visibleChars < state.text.length) setVisibleChars(state.text.length)
    else void run()
  }
  const side = state.portraits[state.speakerId]?.side_override
  const speaker = originalStory.cast[state.speakerId]?.display_name
  const characterBand = state.speakerId !== 'narrator' && (side === 'left' || side === 'right')
  return <main ref={container} className="story-viewport" data-original-playback={ended ? 'ended' : waiting ? 'waiting' : 'playing'}
    style={{ fontFamily: "Arial, 'Hiragino Kaku Gothic ProN', sans-serif" }} tabIndex={0} onKeyDownCapture={e => {
    if (e.repeat) {
      if (e.code === 'Space' || e.code === 'Enter') e.preventDefault()
      return
    }
    if ((e.code === 'Space' || e.code === 'Enter') && (terminalInput.current || waiting && Date.now() >= readyAt.current)) {
      e.preventDefault(); advance()
    }
  }}>
    <div className="story-frame" style={{ width: fit.width, height: fit.height }}>
      <div className="story-stage" onClick={advance} style={{ transform: `scale(${fit.scale})` }}>
        {state.background && <OriginalBackground path={originalAsset(state.background)} filtered={state.backgroundFiltered}
          trigger={command?.kind === 'background' ? command : undefined}
          duration={command?.kind === 'background' ? Number(command.parameters.fade || 0) * 1000 : 0} />}
        {originalPortraitSlots(state).map(({ side, id, value }) => <OriginalPortrait key={side} id={id} value={value} command={command}
          layoutId={state.sequenceId === 'prologue' && id === 'matilda'
            ? state.cursor < 191 ? 'layout.matilda.intro' : 'layout.matilda.explanation' : undefined} layouts={layouts} />)}
        {state.bandVisible && <section data-testid="original-dialogue" style={{ position: 'absolute', left: 0, right: 0,
          bottom: 0, height: 220, textAlign: 'left', background: 'rgba(20,20,31,.75)' }}>
          {characterBand && speaker && <div style={{ position: 'absolute', left: side === 'left' ? 20 : 1026.4,
            top: 6, color: '#bfcce5', fontSize: 18, lineHeight: '26px' }}>{String(speaker)}</div>}
          <div style={{ position: 'absolute', left: characterBand ? side === 'left' ? 16 : 1006.4 : 480,
            top: characterBand ? 30 : 16, width: characterBand ? 897.6 : 960, height: characterBand ? 154 : 188,
            color: characterBand ? '#261f2e' : 'white',
            boxSizing: 'border-box',
            borderImage: characterBand ? `url(${originalAsset('res://assets/ui/speech_bubble_2_small.png')}) 8 fill / 8px` : undefined }}>
            {!characterBand && speaker && <div style={{ fontSize: 20, lineHeight: '28px', marginBottom: 8 }}>{String(speaker)}</div>}
            <div data-testid="original-text" style={{ fontSize: 24, whiteSpace: 'pre-wrap', lineHeight: '34px',
              ...(characterBand ? { position: 'absolute', left: '4%', top: '10%', right: '4%', bottom: '8%' } as const : {}) }}>{state.text.slice(0, visibleChars)}</div>
          </div>
        </section>}
        {terminal && <OriginalTerminalEffect command={terminal} inputRef={terminalInput} onComplete={() => {
          terminalDone.current?.(); terminalDone.current = null
        }} />}
        <OriginalStoryInventory player={player} menuVisible={state.bandVisible} palette={state.bandColor} />
        <span data-testid="original-cursor" aria-hidden="true" style={{ position: 'absolute', width: 1, height: 1,
          overflow: 'hidden', opacity: 0, pointerEvents: 'none' }}>{state.sequenceId}:{state.cursor}</span>
        {debugControls && <nav style={{ position: 'absolute', right: 16, top: 12, display: 'flex', gap: 8 }} onClick={e => e.stopPropagation()}>
          <span>{state.sequenceId}:{state.cursor}</span>
          <button style={{ background: cssColor(state.bandColor) }} onClick={onExit}>原本再生を終了</button>
          <button style={{ background: cssColor(state.bandColor) }} disabled={!waiting} onClick={advance}>次へ</button>
        </nav>}
        {command?.kind === 'battle' && !onBattle && <aside role="status" className="original-suspension">
          <p>原本の{command.parameters.is_tutorial ? 'チュートリアル' : command.parameters.is_minigame ? 'ミニゲーム' : '通常戦'}開始地点</p>
          <p>{String(command.parameters.chapter_path)}</p><p>この参照プレビューでは、戦闘開始前で停止します。</p>
        </aside>}
        {ended && ending !== undefined && <aside role="status" className="original-suspension">{ending}</aside>}
        {error && <aside role="alert" className="original-suspension">{error}</aside>}
      </div>
    </div>
  </main>
}
