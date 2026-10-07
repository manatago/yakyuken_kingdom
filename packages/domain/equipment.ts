import { getItemDefinition, type ItemId } from './item-catalog'
import { parseSave, type SaveData } from './save'

export function equipItem(save: SaveData, id: ItemId): SaveData {
  if (getItemDefinition(id)?.category !== 'equipment') throw new Error('Only equipment can be equipped')
  if ((save.player.equipment ?? []).includes(id)) throw new Error('Equipment is already equipped')
  const items = [...(save.player.items ?? [])]
  const ownedIndex = items.indexOf(id)
  if (ownedIndex < 0) throw new Error('Equipment is not in the item inventory')
  items.splice(ownedIndex, 1)
  return parseSave({ ...save, player: { ...save.player, items, equipment: [...(save.player.equipment ?? []), id] } })
}

export function unequipItem(save: SaveData, id: ItemId): SaveData {
  const equipment = [...(save.player.equipment ?? [])]
  const equippedIndex = equipment.indexOf(id)
  if (equippedIndex < 0) throw new Error('Equipment is not equipped')
  equipment.splice(equippedIndex, 1)
  return parseSave({ ...save, player: { ...save.player, items: [...(save.player.items ?? []), id], equipment } })
}
