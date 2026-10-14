import { useOriginalStoryViewer } from './OriginalStoryViewer'
import type { SaveData } from '../../../packages/domain/save'
import { getItemDefinition } from '../../../packages/domain/item-catalog'
import source from '../../../content/stories/godot-story-menu.json'
import geometry from '../../../content/stories/godot-story-menu-geometry.json'
import inventoryGeometry from '../../../content/stories/godot-story-inventory-geometry.json'
import { originalItemIcon } from './original-assets'
import type { OriginalValue } from '../../../packages/story/original'

const rgba = (color: number[]) => `rgba(${color.slice(0, 3).map(value => value * 255).join(',')},${color[3]})`
const position = (rect: number[], parent: number[] = [0, 0]) => ({ position: 'absolute' as const,
  left: rect[0] - parent[0], top: rect[1] - parent[1], width: rect[2], height: rect[3] })
interface ViewerGeometry {
  rect: number[]; title_rect: number[]; close_rect: number[]
  gold?: { rect: number[]; icon_rect: number[]; text_rect: number[] }
  scroll_rect?: number[]; empty_rect?: number[]
}

/** Godot's story viewers do not consume items or change equipment. */
export function OriginalStoryInventory({ player: currentPlayer, menuVisible = true, palette, menuOffsetY = 0 }: { player?: SaveData['player']; menuVisible?: boolean; palette?: OriginalValue; menuOffsetY?: number }) {
  const { viewer: openViewer, setViewer } = useOriginalStoryViewer()
  const viewer = openViewer?.kind
  const player = openViewer?.player
  const labels = viewer ? source.viewers[viewer] : undefined
  const ids = viewer === 'equip' ? player?.equipment ?? [] : player?.items ?? []
  const counts = new Map<string, number>()
  for (const id of ids) counts.set(id, (counts.get(id) ?? 0) + 1)
  const modal: ViewerGeometry | undefined = viewer ? inventoryGeometry.viewers[counts.size ? viewer : viewer === 'item' ? 'empty_item' : 'empty_equip'] : undefined
  const gold = modal?.gold
  const scrollRect = modal?.scroll_rect
  const emptyRect = modal?.empty_rect
  const color = palette && typeof palette === 'object' && !Array.isArray(palette)
    ? [Number(palette.r), Number(palette.g), Number(palette.b), Number(palette.a)] : undefined
  const normal = color ?? geometry.styles.normal
  const hover = color ? color.map((value, index) => index < 3 ? Math.fround(value + .12) : value) : geometry.styles.hover
  return <>
    {menuVisible && <nav className="original-story-menu" data-testid="original-story-menu" aria-label="所持品の閲覧" onClick={event => event.stopPropagation()}
      style={{ position: 'absolute', zIndex: 3, left: geometry.menu_rect[0], top: geometry.menu_rect[1] + menuOffsetY,
        width: geometry.menu_rect[2], height: geometry.menu_rect[3] }}>
      <style>{`.original-story-menu button { background: ${rgba(normal)}; color: ${rgba(geometry.styles.font)}; }
        .original-story-menu button:hover:not(:disabled) { background: ${rgba(hover)}; color: ${rgba(geometry.styles.font_hover)}; }`}</style>
      {source.buttons.filter(button => button.id !== 'SkipButton').map(button => {
        const rect = geometry.buttons.find(original => original.id === button.id)!.rect
        return <button key={button.id} style={{ position: 'absolute', left: rect[0] - geometry.menu_rect[0],
          top: rect[1] - geometry.menu_rect[1], width: rect[2], height: rect[3],
          fontSize: button.font_size, padding: '3px 10px', border: 0, borderRadius: 4 }}
          onClick={() => {
            if (button.id === 'ItemButton' || button.id === 'EquipButton') {
              setViewer(current => current ? null : { kind: button.id === 'ItemButton' ? 'item' : 'equip',
                player: currentPlayer ? structuredClone(currentPlayer) : undefined })
            }
          }}>{button.label}</button>
      })}
    </nav>}
    {viewer && labels && modal && <section role="dialog" aria-modal="false" aria-label={labels.title}
      onClick={event => event.stopPropagation()}
      style={{ ...position(modal.rect), zIndex: 5, borderRadius: 12, background: 'rgba(15.3,12.75,25.5,.92)', color: 'white', textAlign: 'center' }}>
      <h2 style={{ ...position(modal.title_rect, modal.rect), fontSize: 28, fontWeight: 400, lineHeight: `${modal.title_rect[3]}px`, margin: 0 }}>{labels.title}</h2>
      {gold && <div style={{ ...position(gold.rect, modal.rect), fontSize: 22, color: 'rgb(230,191,77)', textAlign: 'left' }}>
        <img src={originalItemIcon} alt="" style={{ ...position(gold.icon_rect, gold.rect), objectFit: 'contain' }} />
        <span style={{ position: 'absolute', left: gold.text_rect[0] - gold.rect[0], top: 0, lineHeight: `${gold.rect[3]}px` }}>{source.gold_prefix}{player?.money ?? 0}</span></div>}
      {emptyRect ? <p style={{ ...position(emptyRect, modal.rect), margin: 0, fontSize: 18, lineHeight: `${emptyRect[3]}px` }}>{labels.empty}</p>
      : scrollRect && <div style={{ ...position(scrollRect, modal.rect), overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 4,
        textAlign: 'left', fontSize: 20 }}>
        {[...counts].map(([id, count]) => <div key={id} style={{ display: 'flex', alignItems: 'center', gap: 6, minHeight: 28, lineHeight: '28px' }}>
          <img src={originalItemIcon} alt="" style={{ width: 28, height: 28, flexShrink: 0, objectFit: 'contain' }} />
          {getItemDefinition(id)?.name ?? id}{viewer === 'item' && count > 1 && ` × ${count}`}</div>)}
      </div>}
      <button style={{ ...position(modal.close_rect, modal.rect), fontSize: 16, padding: 0 }} onClick={() => setViewer(null)}>{labels.close}</button>
    </section>}
  </>
}
