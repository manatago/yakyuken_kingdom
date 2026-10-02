export const ITEM_CATALOG = [
  { id: 'scissors_attract_white', name: '刃招きの珠・白紋' },
  { id: 'paper_seal_white', name: '紙封じの栞・白紋' }
] as const

export type ItemId = (typeof ITEM_CATALOG)[number]['id']
export type ItemDefinition = (typeof ITEM_CATALOG)[number]

const definitions = new Map<string, ItemDefinition>(ITEM_CATALOG.map((item) => [item.id, item]))

export function getItemDefinition(id: string): ItemDefinition | undefined {
  return definitions.get(id)
}
