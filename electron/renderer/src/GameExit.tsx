import { createContext, useContext, type ReactNode } from 'react'

const GameExitContext = createContext<(() => void) | undefined>(undefined)

/** Kept separate from each StoryScene's inventory viewer, including embedded battles. */
export function GameExitProvider({ onExit, children }: { onExit(): void; children: ReactNode }) {
  return <GameExitContext.Provider value={onExit}>{children}</GameExitContext.Provider>
}

export const useGameExit = () => useContext(GameExitContext)
