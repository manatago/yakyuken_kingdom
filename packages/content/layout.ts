import type { ContentPack, LayoutContent } from './schema'

export const CARD_LAYOUT_DEFAULTS = {
  'layout.cards.box': { id: 'layout.cards.box', x: 1554, y: 190, scale: 1, flipped: false },
  'layout.cards.deck': { id: 'layout.cards.deck', x: 350, y: 884, scale: 1, flipped: false },
  'layout.cards.showdown': { id: 'layout.cards.showdown', x: 350, y: 170, scale: 1, flipped: false }
} as const

export const MATILDA_LAYOUT_IDS = ['layout.matilda.intro', 'layout.matilda.explanation',
  ...Object.keys(CARD_LAYOUT_DEFAULTS)] as readonly string[]

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

export function moveLayout(layout: LayoutContent, dx: number, dy: number, viewportScale: number): LayoutContent {
  if (![dx, dy, viewportScale].every(Number.isFinite) || viewportScale <= 0) throw new Error('Invalid pointer transform')
  return { ...layout, x: layout.x + dx / viewportScale, y: layout.y + dy / viewportScale }
}
