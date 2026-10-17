import { useLayoutEffect, useMemo, useRef, useState } from 'react'
import type { BattleTraceCommand } from '../../../packages/story/original-battle'
import { applyOriginalBattleSurface, createOriginalBattleSurface } from '../../../packages/story/original-battle-surface'
import { fitViewport } from '../../../packages/story/viewport'
import type { OriginalStoryState } from '../../../packages/story/original'
import { originalAsset } from '../../renderer/src/original-assets'
import { OriginalPortrait } from '../../renderer/src/OriginalStoryScreen'
import { OriginalBattleBackground } from '../../renderer/src/OriginalBattleBackground'
import { OriginalBattleDialogue } from '../../renderer/src/OriginalBattleDialogue'
import { OriginalBattleBubble } from '../../renderer/src/OriginalBattleBubble'
import { originalBattleTypingText } from '../../../packages/story/original-bubble'

export function TracePreview({ commands, background }: { commands: BattleTraceCommand[]; background: string }) {
  const container = useRef<HTMLElement>(null)
  const [fit, setFit] = useState(() => fitViewport(0, 0))
  useLayoutEffect(() => {
    const node = container.current!, update = () => setFit(fitViewport(node.clientWidth, node.clientHeight))
    update(); const observer = new ResizeObserver(update); observer.observe(node)
    return () => observer.disconnect()
  }, [])
  const scene = useMemo(() => {
    const surface = createOriginalBattleSurface(), portraits: OriginalStoryState['portraits'] = {}
    let path = background
    for (const command of commands) {
      applyOriginalBattleSurface(surface, command)
      const args = command.args
      if (command.kind === 'background') path = String(args[0])
      if (command.kind === 'set_portrait' || command.kind === 'deck') {
        const deck = command.kind === 'deck', id = deck ? 'deck' : String(args[0])
        const options = (args[deck ? 1 : 2] ?? {}) as Record<string, unknown>
        const position = options.position as number[] | undefined
        portraits[id] = { portrait_id: String(args[deck ? 0 : 1]), portrait_scale: Number(options.scale ?? 1),
          side_override: String(options.side ?? 'center'), position_mode: 'offset',
          position: { type: 'Vector2', x: position?.[0] ?? 0, y: position?.[1] ?? 0 },
          flip: typeof options.flip === 'boolean' ? options.flip ? 1 : 0 : Number(options.flip ?? -1), visible: true }
      }
      if (command.kind === 'leave') for (const [id, value] of Object.entries(portraits)) if (id !== 'deck') value.visible = false
    }
    return { surface, portraits, path }
  }, [commands, background])
  return <section ref={container} className="story-viewport" data-testid="trace-preview">
    <div className="story-frame" style={{ width: fit.width, height: fit.height }}><div className="story-stage" style={{ transform: `scale(${fit.scale})` }}>
      {scene.path && (scene.surface.blurred ? <OriginalBattleBackground path={originalAsset(scene.path)} />
        : <img className="story-background" alt="背景" src={originalAsset(scene.path)} />)}
      {Object.entries(scene.portraits).sort(([left], [right]) => Number(left === 'deck') - Number(right === 'deck'))
        .map(([id, value]) => <OriginalPortrait key={id} id={id} value={value} />)}
      {scene.surface.bandVisible && scene.surface.band && <OriginalBattleDialogue text={scene.surface.band.text}
        speaker={scene.surface.band.speaker} onAdvance={() => {}} waitForInput={false} textTestId="trace-preview-text" />}
      {scene.surface.bubble && <OriginalBattleBubble text={scene.surface.bubble.text} side={scene.surface.bubble.side}
        visibleCharacters={originalBattleTypingText(scene.surface.bubble.text, scene.surface.bubble.side, true).length}
        fontSize={scene.surface.bubble.fontSize} revision={scene.surface.bubble.revision} waitForInput={false} editedPreview
        onAdvance={() => {}} textTestId="trace-preview-bubble" />}
    </div></div>
  </section>
}
