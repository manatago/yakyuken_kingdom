import rock from '../../../godot/assets/battle/cards/rock_normal.png?url'
import scissors from '../../../godot/assets/battle/cards/scissors_normal.png?url'
import paper from '../../../godot/assets/battle/cards/paper_normal.png?url'

export const cardImages: Readonly<Record<string, string>> = {
  rock_normal: rock, scissors_normal: scissors, paper_normal: paper,
  ...Object.fromEntries(Object.entries(import.meta.glob('../../../godot/assets/battle/cards/*_*.png',
    { eager: true, query: '?url', import: 'default' })).map(([path, url]) => [path.split('/').pop()!.slice(0, -4), url as string]))
}
