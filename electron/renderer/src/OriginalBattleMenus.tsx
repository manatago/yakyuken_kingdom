import type { SaveData } from '../../../packages/domain/save'
import { OriginalStoryInventory } from './OriginalStoryInventory'
import { OriginalStoryViewerProvider } from './OriginalStoryViewer'

/** BattleScene owns a separate embedded StoryScene, including its transient viewers. */
export function OriginalBattleMenus({ player, visible, minigame = false }: {
  player: SaveData['player']; visible: boolean; minigame?: boolean
}) {
  return <OriginalStoryViewerProvider><OriginalStoryInventory player={player} menuVisible={visible}
    menuOffsetY={minigame ? 0 : -150} /></OriginalStoryViewerProvider>
}
