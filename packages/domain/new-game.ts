import { HANDS } from './card'
import { createNewSave, type SaveData } from './save'

export const MATILDA_START_CHECKPOINT = 'matilda.start'
export const PROLOGUE_START_CHECKPOINT = 'prologue.university.background'

export function createInitialGameSave(): SaveData {
  return createNewSave(MATILDA_START_CHECKPOINT, {
    inventory: HANDS.flatMap((hand) =>
      Array.from({ length: 3 }, () => ({ hand, grade: 1 as const }))
    ),
    items: [],
    deck: [],
    money: 0
  })
}

/** Title-screen saves begin with the adapted opening; domain fixtures may start at Matilda. */
export function createNewGameSave(): SaveData {
  const save = createInitialGameSave()
  return createNewSave(PROLOGUE_START_CHECKPOINT, save.player)
}
