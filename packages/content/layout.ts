import type { ContentPack, LayoutContent } from './schema'
import { originalShowdownGeometry } from '../story/original-showdown'

export const CARD_LAYOUT_DEFAULTS = {
  'layout.cards.box': { id: 'layout.cards.box', x: 1554, y: 190, scale: 1, flipped: false },
  'layout.cards.deck': { id: 'layout.cards.deck', x: 350, y: 884, scale: 1, flipped: false },
  'layout.cards.showdown': { id: 'layout.cards.showdown', x: 350, y: 170, scale: 1, flipped: false }
} as const

export const MATILDA_LAYOUT_IDS = ['layout.matilda.intro', 'layout.matilda.explanation',
  ...Object.keys(CARD_LAYOUT_DEFAULTS)] as readonly string[]

export type MatildaPortraitLayoutId = 'layout.matilda.intro' | 'layout.matilda.explanation'
const PORTRAIT_LAYOUT_DEFAULTS = {
  'layout.matilda.intro': { x: 960, y: 440, scale: .8, flipped: false },
  'layout.matilda.explanation': { x: 960, y: 410, scale: .8, flipped: false }
}

export function originalEditedPortraitLayout(source: { x: number; y: number; scale: number; flipped: boolean },
  pack: Pick<ContentPack, 'layouts'>, id: MatildaPortraitLayoutId) {
  const baseline = PORTRAIT_LAYOUT_DEFAULTS[id]
  const edited = pack.layouts.find(layout => layout.id === id) ?? baseline
  return { ...source, x: source.x + edited.x - baseline.x, y: source.y + edited.y - baseline.y,
    scale: source.scale * edited.scale / baseline.scale, flipped: source.flipped !== Boolean(edited.flipped) }
}

export function cardLayout(pack: Pick<ContentPack, 'layouts'>, id: keyof typeof CARD_LAYOUT_DEFAULTS): LayoutContent {
  return pack.layouts.find((layout) => layout.id === id) ?? CARD_LAYOUT_DEFAULTS[id]
}

export function layoutStyle(layout: LayoutContent) {
  return {
    left: layout.x, top: layout.y, right: 'auto', bottom: 'auto',
    transform: `scale(${layout.flipped ? -layout.scale : layout.scale}, ${layout.scale})`,
    transformOrigin: 'top left'
  } as const
}

// Godot BattleScene anchors, converted to the 1920x1080 reference viewport.
export function originalCardLayout(pack: Pick<ContentPack, 'layouts'>, id: keyof typeof CARD_LAYOUT_DEFAULTS): LayoutContent {
  const source = id === 'layout.cards.box' ? { x: 1497.6, y: 58 }
    : id === 'layout.cards.deck' ? { x: 0, y: 930 }
      : { x: originalShowdownGeometry(1920, 1080).playerEndX, y: originalShowdownGeometry(1920, 1080).y }
  const edited = cardLayout(pack, id)
  const baseline = CARD_LAYOUT_DEFAULTS[id]
  return { ...edited, x: source.x + edited.x - baseline.x, y: source.y + edited.y - baseline.y }
}

export function moveLayout(layout: LayoutContent, dx: number, dy: number, viewportScale: number): LayoutContent {
  if (![dx, dy, viewportScale].every(Number.isFinite) || viewportScale <= 0) throw new Error('Invalid pointer transform')
  return { ...layout, x: layout.x + dx / viewportScale, y: layout.y + dy / viewportScale }
}
