import { HANDS } from './card'
import { createNewSave, type SaveData } from './save'

export const MATILDA_START_CHECKPOINT = 'matilda.start'

export function createInitialGameSave(): SaveData {
  return createNewSave(MATILDA_START_CHECKPOINT, {
    inventory: HANDS.flatMap((hand) =>
      Array.from({ length: 3 }, () => ({ hand, grade: 1 as const }))
    ),
    deck: [],
    money: 0
  })
}
