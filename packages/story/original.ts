import document from '../../content/stories/godot-original.json'

export type OriginalValue = null | boolean | number | string | OriginalValue[] | { [key: string]: OriginalValue }
export interface OriginalCommand { kind: string; parameters: Record<string, OriginalValue> }
export interface OriginalStoryDocument {
  format: 'godot-story-commands'
  version: 1
  cast: Record<string, Record<string, OriginalValue>>
  portrait_layouts: Record<string, { scale: number; position: [number, number] }>
  sequences: { id: string; commands: OriginalCommand[] }[]
}
export const originalStory = document as unknown as OriginalStoryDocument

export interface OriginalStoryState {
  sequenceId: string
  cursor: number
  flags: Record<string, boolean>
  background: string
  backgroundFiltered: boolean
  portraits: Record<string, Record<string, OriginalValue> & { visible: boolean }>
  text: string
  speakerId: string
  bandVisible: boolean
  bandColor: OriginalValue
  skipping?: boolean
  skipCursors?: number[]
  innerBandHidden?: boolean
}

function cleanupOriginalSkip(state: OriginalStoryState) {
  for (const portrait of Object.values(state.portraits)) {
    portrait.visible = false
    portrait.cache_valid = false
  }
  state.innerBandHidden = true
}

/** Execute the original button's cleanup; do not jump the command cursor. */
export function beginOriginalStorySkip(previous: OriginalStoryState): OriginalStoryState {
  const length = originalStory.sequences.find(sequence => sequence.id === previous.sequenceId)?.commands.length
  if (!length || !Number.isSafeInteger(previous.cursor) || previous.cursor < 1 || previous.cursor > length) {
    throw new Error('Invalid original Skip cursor')
  }
  const state = structuredClone(previous)
  state.skipping = true
  const history = state.skipCursors ?? []
  state.skipCursors = history.at(-1) === state.cursor ? history : [...history, state.cursor]
  cleanupOriginalSkip(state)
  return state
}

function originalCommandReturnsSignal(command: OriginalCommand) {
  const p = command.parameters
  if (command.kind === 'battle' || command.kind === 'terminal_effect') return true
  if (command.kind === 'pause') return Number(p.duration) > 0
  if (command.kind === 'line' || command.kind === 'band') return Boolean(p.wait_for_input) && (command.kind === 'line' || p.visible === true)
  if (command.kind === 'hide_character') return Number(p.wait_after) > 0 ||
    Boolean(p.wait_for_exit && ['fade', 'slide', 'fade_slide', 'shrink', 'fade_shrink'].includes(String(p.exit_effect)) && Number(p.exit_duration) > 0)
  return false
}

export function createOriginalStoryState(sequenceId: string, flags: Record<string, boolean> = {}): OriginalStoryState {
  if (!originalStory.sequences.some(s => s.id === sequenceId)) throw new Error(`Unknown original sequence: ${sequenceId}`)
  return { sequenceId, cursor: 0, flags: { ...flags }, background: '', backgroundFiltered: false, portraits: {}, text: '',
    speakerId: '', bandVisible: false, bandColor: null }
}

function showCharacter(state: OriginalStoryState, id: string, p: Record<string, OriginalValue>) {
  const cached = state.portraits[id]?.cache_valid === false ? undefined : state.portraits[id]
  const portrait = p.portrait_id || cached?.portrait_id || originalStory.cast[id]?.default_portrait || ''
  const side = String(p.side_override || cached?.side_override ||
    ['left', 'right', 'center'].find(candidate => !Object.values(state.portraits)
      .some(entry => entry.visible && entry.side_override === candidate)) || 'left')
  if (!portrait) return // Godot does not allocate a visible slot without a resolved texture.
  // Godot has exactly three TextureRects: a new character replaces the slot's occupant.
  for (const entry of Object.values(state.portraits)) {
    if (entry.side_override === side) entry.visible = false
  }
  state.portraits[id] = { ...cached, ...p, portrait_id: portrait, side_override: side, visible: true, cache_valid: true,
    slot_cursor: state.cursor }
}

/** Keep one renderer per Godot TextureRect, including its last hidden occupant. */
export function originalPortraitSlots(state: OriginalStoryState) {
  return ['left', 'right', 'center'].flatMap(side => {
    const entries = Object.entries(state.portraits).filter(([, value]) => value.side_override === side)
    const occupant = entries.find(([, value]) => value.visible) ?? entries.sort((a, b) =>
      Number(b[1].slot_cursor || 0) - Number(a[1].slot_cursor || 0))[0]
    return occupant ? [{ side, id: occupant[0], value: occupant[1] }] : []
  })
}

export function restoreOriginalStoryState(sequenceId: string, cursor: number,
  initialFlags: Record<string, boolean> = {}, incoming?: OriginalStoryState, skipCursors: readonly number[] = []): OriginalStoryState {
  let state = createOriginalStoryState(sequenceId, initialFlags)
  if (incoming) {
    state = { ...structuredClone(incoming), sequenceId, cursor: 0, flags: { ...initialFlags } }
    // Skip belongs to a Sequence; reused StoryScene visuals do not carry its mode/history.
    delete state.skipping
    delete state.skipCursors
  }
  const length = originalStory.sequences.find(s => s.id === sequenceId)!.commands.length
  if (!Number.isInteger(cursor) || cursor < 0 || cursor > length) throw new Error('Invalid original story cursor')
  if (skipCursors.some((value, index) => !Number.isSafeInteger(value) || value < 1 || value > cursor ||
      index > 0 && value <= skipCursors[index - 1])) throw new Error('Invalid original Skip history')
  while (state.cursor < cursor) {
    if (skipCursors.includes(state.cursor)) state = beginOriginalStorySkip(state)
    state = executeOriginalCommand(state).state
  }
  if (skipCursors.includes(cursor)) state = beginOriginalStorySkip(state)
  return state
}

export function originalPortraitLayout(portrait: Record<string, OriginalValue>, width: number, height: number, useSourceOverrides = true) {
  const source = useSourceOverrides ? originalStory.portrait_layouts[String(portrait.portrait_id)] : undefined
  const scale = source?.scale ?? (Number(portrait.portrait_scale) > 0 ? Number(portrait.portrait_scale) : 1)
  const side = String(portrait.side_override)
  const base = { x: side === 'right' ? 1920 - width * scale - 100
    : side === 'center' ? (1920 - width * scale) / 2 : 100, y: 1080 - height * scale }
  let x = base.x, y = base.y
  if (source) { x += source.position[0]; y += source.position[1] }
  else if (portrait.position && typeof portrait.position === 'object' && !Array.isArray(portrait.position)) {
    const p = portrait.position
    if (portrait.position_mode === 'absolute') { x = Number(p.x); y = Number(p.y) }
    else if (portrait.position_mode === 'normalized') { x = Number(p.x) * 1920; y = Number(p.y) * 1080 }
    else { x += Number(p.x); y += Number(p.y) }
  }
  const flipped = Number(portrait.flip) >= 0 ? portrait.flip === 1 : side === 'right'
  return { x, y, scale, flipped }
}

// One source command per call: UI must await its effects before requesting the next.
// In particular, battle/terminal/pause commands must never be collapsed on replay.
export function executeOriginalCommand(previous: OriginalStoryState): { state: OriginalStoryState; command?: OriginalCommand } {
  const sequence = originalStory.sequences.find(s => s.id === previous.sequenceId)
  if (!sequence) throw new Error(`Unknown original sequence: ${previous.sequenceId}`)
  if (!Number.isInteger(previous.cursor) || previous.cursor < 0 || previous.cursor > sequence.commands.length) {
    throw new Error('Invalid original story cursor')
  }
  const state = structuredClone(previous)
  const command = sequence.commands[state.cursor]
  if (!command) return { state }
  if (state.skipping && command.kind === 'background') state.skipping = false
  state.cursor++
  const p = command.parameters
  switch (command.kind) {
    case 'background': state.background = String(p.path); break
    case 'show_character': {
      const id = String(p.character_id)
      showCharacter(state, id, p)
      break
    }
    case 'hide_character': {
      const id = String(p.character_id)
      const cached = state.portraits[id]?.cache_valid === false ? undefined : state.portraits[id]
      const side = p.side_override || cached?.side_override ||
        ['left', 'right', 'center'].find(candidate => !Object.values(state.portraits)
          .some(entry => entry.visible && entry.side_override === candidate)) || 'left'
      for (const portrait of Object.values(state.portraits)) {
        if (portrait.side_override === side) portrait.visible = false
      }
      // Keep the outgoing image for its renderer animation, but invalidate the
      // character caches exactly as Godot _hide_character_control does.
      if (state.portraits[id]) state.portraits[id].cache_valid = false
      break
    }
    case 'line':
    case 'band': {
      state.bandVisible = command.kind === 'line' || p.visible === true
      if (!state.bandVisible) break
      if (state.innerBandHidden !== undefined) state.innerBandHidden = false
      const text = p.retry_flag_key && state.flags[String(p.retry_flag_key)] && p.retry_text ? p.retry_text : p.text
      // Godot apply_band_command replaces text, even when append is set.
      if (p.clear_text || text) state.text = String(text ?? '')
      state.speakerId = String(p.speaker_id ?? '')
      if (state.speakerId && state.speakerId !== 'narrator' && originalStory.cast[state.speakerId]) {
        showCharacter(state, state.speakerId, { portrait_id: p.portrait_id, side_override: p.side_override })
      }
      const side = state.portraits[state.speakerId]?.side_override
      state.backgroundFiltered = state.speakerId !== 'narrator' && Boolean(originalStory.cast[state.speakerId]) && (side === 'left' || side === 'right')
      break
    }
    case 'band_color': state.bandColor = p.color; break
    case 'hide_dialogue': state.bandVisible = false; break
    case 'set_flag': state.flags[String(p.flag_key)] = p.value === true; break
    case 'label': case 'battle': case 'pause': case 'terminal_effect': case 'bg_filter':
    case 'animate_portrait': case 'stop_portrait_animation': case 'micro_motion':
      break // Returned verbatim for the renderer/battle adapter to execute.
    default: throw new Error(`Unsupported original command: ${command.kind}`)
  }
  if (state.skipping && originalCommandReturnsSignal(command)) cleanupOriginalSkip(state)
  return { state, command: structuredClone(command) }
}
