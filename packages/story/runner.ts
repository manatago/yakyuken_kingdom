import type { ContentPack, StoryStep } from '../content/schema'

export interface StoryFrame {
  step: Extract<StoryStep, { kind: 'line' | 'battle' | 'end' }>
  text: string
  backgroundAssetId?: string
  portraits: Record<string, { assetId: string; layoutId: string }>
}

export type StoryTextVariables = Readonly<Record<string, string | number>>

function interpolateText(text: string, variables: StoryTextVariables, resolveVariables = true): string {
  return text.replace(/\{\{([A-Za-z][A-Za-z0-9_]*)\}\}/g, (_match, name: string) => {
    const value = variables[name]
    if (value === undefined) {
      if (!resolveVariables) return _match
      throw new Error(`Missing story text variable: ${name}`)
    }
    return String(value)
  })
}

// Replay deterministic setup commands to reconstruct visuals and appended text.
// Interactive battle checkpoints are resumed by their separate persisted ledger.
function replayStory(pack: ContentPack, storyId: string, checkpointId: string | undefined,
  variables: StoryTextVariables, resolveVariables: boolean): StoryFrame {
  const story = pack.stories.find((entry) => entry.id === storyId)
  if (!story) throw new Error(`Unknown story: ${storyId}`)
  const steps = new Map(story.steps.map((step) => [step.id, step]))
  if (checkpointId && !steps.has(checkpointId)) throw new Error(`Unknown checkpoint: ${checkpointId}`)
  let id = story.start_id
  let reached = checkpointId === undefined
  let text = ''
  let backgroundAssetId: string | undefined
  const portraits: StoryFrame['portraits'] = {}
  const visited = new Set<string>()
  while (true) {
    if (visited.has(id)) throw new Error(`Automatic story loop at ${id}`)
    visited.add(id)
    const step = steps.get(id)
    if (!step) throw new Error(`Unknown step: ${id}`)
    if (id === checkpointId) reached = true
    switch (step.kind) {
      case 'background': backgroundAssetId = step.asset_id; id = step.next_id; break
      case 'show_portrait':
        portraits[step.slot_id] = { assetId: step.asset_id, layoutId: step.layout_id }
        id = step.next_id
        break
      case 'hide_portrait': delete portraits[step.slot_id]; id = step.next_id; break
      case 'goto': id = step.target_id; break
      case 'line':
        const line = interpolateText(step.text, variables, resolveVariables)
        text = step.append && text ? `${text}\n${line}` : line
        if (reached) return { step, text, backgroundAssetId, portraits }
        id = step.next_id
        break
      case 'end':
        if (!reached) throw new Error(`Unreachable checkpoint: ${checkpointId}`)
        return { step, text: '', backgroundAssetId, portraits }
      case 'battle':
        if (reached) return { step, text: '', backgroundAssetId, portraits }
        text = ''
        id = step.next_id
        break
      default: throw new Error(`Unsupported interactive story command: ${step.kind}`)
    }
  }
}

export function startStory(pack: ContentPack, storyId: string, checkpointId?: string,
  variables: StoryTextVariables = {}): StoryFrame {
  return replayStory(pack, storyId, checkpointId, variables, true)
}

export function nextStoryCheckpoint(pack: ContentPack, storyId: string, frame: StoryFrame): string {
  if (frame.step.kind === 'end') return frame.step.id
  return replayStory(pack, storyId, frame.step.next_id, {}, false).step.id
}

export function advanceStory(pack: ContentPack, storyId: string, frame: StoryFrame, variables: StoryTextVariables = {}): StoryFrame {
  if (frame.step.kind === 'end') return frame
  return startStory(pack, storyId, frame.step.next_id, variables)
}
