import { createContext, useContext, useState, type ReactNode } from 'react'
import type { SaveData } from '../../../packages/domain/save'

export type StoryViewer = { kind: 'item' | 'equip'; player?: SaveData['player'] } | null
const ViewerContext = createContext<{
  viewer: StoryViewer
  setViewer: React.Dispatch<React.SetStateAction<StoryViewer>>
} | null>(null)

/** StoryScene's read-only modal survives the temporary battle screen replacement. */
export function OriginalStoryViewerProvider({ children }: { children: ReactNode }) {
  const [viewer, setViewer] = useState<StoryViewer>(null)
  return <ViewerContext.Provider value={{ viewer, setViewer }}>{children}</ViewerContext.Provider>
}

export function useOriginalStoryViewer() {
  const shared = useContext(ViewerContext)
  const [viewer, setViewer] = useState<StoryViewer>(null)
  return shared ?? { viewer, setViewer }
}
