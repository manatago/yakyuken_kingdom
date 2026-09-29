import data from '../../../content/stories/matilda-tutorial.json'
import type { ContentPack } from '../../../packages/content/schema'
import { validateContent } from '../../../packages/content/validate'
import { fixedContent, isFixedCheckpoint } from '../../../packages/battle/fixed'
import prison from '../../../godot/assets/backgrounds/prologue/bg05_prison_cell.png?url'
import intro from '../../../godot/assets/characters/mob/guard/default/guard_default_024.png?url'
import items from '../../../godot/assets/characters/mob/guard/default/guard_default_007.png?url'
import cards from '../../../godot/assets/characters/mob/guard/default/guard_default_008.png?url'
import deck from '../../../godot/assets/characters/mob/guard/default/guard_default_009.png?url'

const images: Record<string, string> = {
  'godot/assets/backgrounds/prologue/bg05_prison_cell.png': prison,
  'godot/assets/characters/mob/guard/default/guard_default_024.png': intro,
  'godot/assets/characters/mob/guard/default/guard_default_007.png': items,
  'godot/assets/characters/mob/guard/default/guard_default_008.png': cards,
  'godot/assets/characters/mob/guard/default/guard_default_009.png': deck
}

const validation = validateContent(data, (path) => Object.hasOwn(images, path))
if (!validation.valid) throw new Error(`Invalid tutorial content: ${JSON.stringify(validation.issues)}`)
export const matildaContent = data as ContentPack
export const MATILDA_STORY_ID = 'story.matilda'
export const normalContent = fixedContent
export const NORMAL_STORY_ID = 'story.matilda.normal'
const normalValidation = validateContent(normalContent, (path) => Object.hasOwn(images, path))
if (!normalValidation.valid) throw new Error(`Invalid normal content: ${JSON.stringify(normalValidation.issues)}`)

export function tutorialImage(assetId: string): string {
  const asset = matildaContent.assets.find((entry) => entry.id === assetId)
  if (!asset || !Object.hasOwn(images, asset.path)) throw new Error(`Unknown tutorial asset: ${assetId}`)
  return images[asset.path]
}

export function isMatildaCheckpoint(id: string): boolean {
  return isFixedCheckpoint(id) || matildaContent.stories[0].steps.some((step) => step.id === id && (step.kind === 'line' || step.kind === 'battle' || step.kind === 'end'))
}
