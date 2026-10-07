import data from '../../../content/stories/matilda-tutorial.json'
import stage2Data from '../../../content/stories/stage2.json'
import subevent2Data from '../../../content/stories/subevent2.json'
import subevent3Data from '../../../content/stories/subevent3.json'
import subevent4Data from '../../../content/stories/subevent4.json'
import stage3Data from '../../../content/stories/stage3.json'
import stage4Data from '../../../content/stories/stage4.json'
import stage5Data from '../../../content/stories/stage5.json'
import stage6Data from '../../../content/stories/stage6.json'
import stage7Data from '../../../content/stories/stage7.json'
import prologueData from '../../../content/stories/prologue.json'
import type { ContentPack } from '../../../packages/content/schema'
import { validateContent } from '../../../packages/content/validate'
import { fixedContent } from '../../../packages/battle/fixed'
import { subevent1JinContent } from '../../../packages/battle/jin'
import prison from '../../../godot/assets/backgrounds/prologue/bg05_prison_cell.png?url'
import intro from '../../../godot/assets/characters/mob/guard/default/guard_default_024.png?url'
import items from '../../../godot/assets/characters/mob/guard/default/guard_default_007.png?url'
import cards from '../../../godot/assets/characters/mob/guard/default/guard_default_008.png?url'
import deck from '../../../godot/assets/characters/mob/guard/default/guard_default_009.png?url'
import jinArena from '../../../godot/assets/backgrounds/prologue/bg06_prison_arena.png?url'
import guild from '../../../godot/assets/backgrounds/stage1/bg07_st1_001.png?url'
import inn from '../../../godot/assets/backgrounds/stage2/bg_inn_meeting.png?url'
import resting from '../../../godot/assets/backgrounds/stage2/bg_guild_resting.png?url'
import layla from '../../../godot/assets/characters/main/layla/clothed/layla_clothed_001.png?url'
import stage2Hero from '../../../godot/assets/characters/main/satoshi/isekai/satoshi_isekai_004.png?url'
import churchExterior from '../../../godot/assets/backgrounds/subevent2/bg01_church_exterior.png?url'
import churchInterior from '../../../godot/assets/backgrounds/subevent2/bg02_church_interior.png?url'
import churchBackyard from '../../../godot/assets/backgrounds/subevent2/bg03_church_backyard.png?url'
import churchCorridor from '../../../godot/assets/backgrounds/subevent2/bg04_church_corridor.png?url'
import churchPeepRoom from '../../../godot/assets/backgrounds/subevent2/bg05_church_peep_room.png?url'
import sisterHead from '../../../godot/assets/characters/main/sister_head/clothed/sister_head_clothed_001.png?url'
import blacksmith from '../../../godot/assets/backgrounds/subevent3/bg_blacksmith.png?url'
import nobleRoom from '../../../godot/assets/backgrounds/subevent3/bg_noble_room.png?url'
import fiona from '../../../godot/assets/characters/main/fiona/clothed/fiona_clothed_001.png?url'
import receptionist from '../../../godot/assets/characters/main/receptionist/clothed/receptionist_clothed_005.png?url'
import magdalena from '../../../godot/assets/characters/main/magdalena/clothed/magdalena_clothed_001.png?url'
import stage3Inn from '../../../godot/assets/backgrounds/stage3/bg_inn_exterior.png?url'
import stage3Cathedral from '../../../godot/assets/backgrounds/stage3/bg_cathedral_night.png?url'
import seles from '../../../godot/assets/characters/main/seles/clothed/seles_clothed_001.png?url'
import stage4Wall from '../../../godot/assets/backgrounds/stage4/bg_military_back_wall.png?url'
import stage4Dojo from '../../../godot/assets/backgrounds/stage4/bg_dojo_third.png?url'
import stage5Street from '../../../godot/assets/backgrounds/stage5/bg_royal_street.png?url'
import stage5Interview from '../../../godot/assets/backgrounds/stage5/bg_interrogation_room.png?url'
import stage5Training from '../../../godot/assets/backgrounds/stage5/bg_training_ground.png?url'
import feria from '../../../godot/assets/characters/main/feria/clothed/feria_clothed_001.png?url'
import stage6Hall from '../../../godot/assets/backgrounds/stage6/bg_royal_hall.png?url'
import stage6Side from '../../../godot/assets/backgrounds/stage6/bg_side_room.png?url'
import stage7Sunset from '../../../godot/assets/backgrounds/stage7/bg_capital_sunset.png?url'
import princess from '../../../godot/assets/characters/main/princess/clothed/princess_clothed_001.png?url'
import chamberlain from '../../../godot/assets/characters/mob/chamberlain/default/chamberlain_default_001.png?url'
import university from '../../../godot/assets/backgrounds/prologue/bg01_university.png?url'
import lab from '../../../godot/assets/backgrounds/prologue/bg03-1_lab.png?url'
import capital from '../../../godot/assets/backgrounds/stage1/bg06_st1_001.png?url'
import modernHero from '../../../godot/assets/characters/main/satoshi/modern/satoshi_modern_001.png?url'
import modernFriend from '../../../godot/assets/characters/main/minori/modern/minori_modern_001.png?url'

const images: Record<string, string> = {
  'godot/assets/backgrounds/prologue/bg01_university.png': university,
  'godot/assets/backgrounds/prologue/bg03-1_lab.png': lab,
  'godot/assets/backgrounds/stage1/bg06_st1_001.png': capital,
  'godot/assets/characters/main/satoshi/modern/satoshi_modern_001.png': modernHero,
  'godot/assets/characters/main/minori/modern/minori_modern_001.png': modernFriend,
  'godot/assets/backgrounds/prologue/bg05_prison_cell.png': prison,
  'godot/assets/characters/mob/guard/default/guard_default_024.png': intro,
  'godot/assets/characters/mob/guard/default/guard_default_007.png': items,
  'godot/assets/characters/mob/guard/default/guard_default_008.png': cards,
  'godot/assets/characters/mob/guard/default/guard_default_009.png': deck,
  'godot/assets/backgrounds/prologue/bg06_prison_arena.png': jinArena,
  'godot/assets/backgrounds/stage1/bg07_st1_001.png': guild,
  'godot/assets/backgrounds/stage2/bg_inn_meeting.png': inn,
  'godot/assets/backgrounds/stage2/bg_guild_resting.png': resting,
  'godot/assets/characters/main/layla/clothed/layla_clothed_001.png': layla,
  'godot/assets/characters/main/satoshi/isekai/satoshi_isekai_004.png': stage2Hero,
  'godot/assets/backgrounds/subevent2/bg01_church_exterior.png': churchExterior,
  'godot/assets/backgrounds/subevent2/bg02_church_interior.png': churchInterior,
  'godot/assets/backgrounds/subevent2/bg03_church_backyard.png': churchBackyard,
  'godot/assets/backgrounds/subevent2/bg04_church_corridor.png': churchCorridor,
  'godot/assets/backgrounds/subevent2/bg05_church_peep_room.png': churchPeepRoom,
  'godot/assets/characters/main/sister_head/clothed/sister_head_clothed_001.png': sisterHead,
  'godot/assets/backgrounds/subevent3/bg_blacksmith.png': blacksmith,
  'godot/assets/backgrounds/subevent3/bg_noble_room.png': nobleRoom,
  'godot/assets/characters/main/fiona/clothed/fiona_clothed_001.png': fiona,
  'godot/assets/characters/main/receptionist/clothed/receptionist_clothed_005.png': receptionist,
  'godot/assets/characters/main/magdalena/clothed/magdalena_clothed_001.png': magdalena,
  'godot/assets/backgrounds/stage3/bg_inn_exterior.png': stage3Inn,
  'godot/assets/backgrounds/stage3/bg_cathedral_night.png': stage3Cathedral,
  'godot/assets/characters/main/seles/clothed/seles_clothed_001.png': seles,
  'godot/assets/backgrounds/stage4/bg_military_back_wall.png': stage4Wall,
  'godot/assets/backgrounds/stage4/bg_dojo_third.png': stage4Dojo,
  'godot/assets/backgrounds/stage5/bg_royal_street.png': stage5Street,
  'godot/assets/backgrounds/stage5/bg_interrogation_room.png': stage5Interview,
  'godot/assets/backgrounds/stage5/bg_training_ground.png': stage5Training,
  'godot/assets/characters/main/feria/clothed/feria_clothed_001.png': feria,
  'godot/assets/backgrounds/stage6/bg_royal_hall.png': stage6Hall,
  'godot/assets/backgrounds/stage6/bg_side_room.png': stage6Side,
  'godot/assets/backgrounds/stage7/bg_capital_sunset.png': stage7Sunset,
  'godot/assets/characters/main/princess/clothed/princess_clothed_001.png': princess,
  'godot/assets/characters/mob/chamberlain/default/chamberlain_default_001.png': chamberlain
}

export const prologueContent = prologueData as ContentPack
const prologueValidation = validateContent(prologueContent, (path) => Object.hasOwn(images, path))
if (!prologueValidation.valid) throw new Error(`Invalid prologue content: ${JSON.stringify(prologueValidation.issues)}`)

const validation = validateContent(data, (path) => Object.hasOwn(images, path))
if (!validation.valid) throw new Error(`Invalid tutorial content: ${JSON.stringify(validation.issues)}`)
export const matildaContent = data as ContentPack
export const stage2Content = stage2Data as ContentPack
const stage2Validation = validateContent(stage2Content, (path) => Object.hasOwn(images, path))
if (!stage2Validation.valid) throw new Error(`Invalid Stage 2 content: ${JSON.stringify(stage2Validation.issues)}`)
export const subevent2Content = subevent2Data as ContentPack
const subevent2Validation = validateContent(subevent2Content, (path) => Object.hasOwn(images, path))
if (!subevent2Validation.valid) throw new Error(`Invalid Subevent 2 content: ${JSON.stringify(subevent2Validation.issues)}`)
export const subevent3Content = subevent3Data as ContentPack
const subevent3Validation = validateContent(subevent3Content, (path) => Object.hasOwn(images, path))
if (!subevent3Validation.valid) throw new Error(`Invalid Subevent 3 content: ${JSON.stringify(subevent3Validation.issues)}`)
export const subevent4Content = subevent4Data as ContentPack
const subevent4Validation = validateContent(subevent4Content, (path) => Object.hasOwn(images, path))
if (!subevent4Validation.valid) throw new Error(`Invalid Subevent 4 content: ${JSON.stringify(subevent4Validation.issues)}`)
export const stage3Content = stage3Data as ContentPack
const stage3Validation = validateContent(stage3Content, (path) => Object.hasOwn(images, path))
if (!stage3Validation.valid) throw new Error(`Invalid Stage 3 content: ${JSON.stringify(stage3Validation.issues)}`)
export const stage4Content = stage4Data as ContentPack
const stage4Validation = validateContent(stage4Content, (path) => Object.hasOwn(images, path))
if (!stage4Validation.valid) throw new Error(`Invalid Stage 4 content: ${JSON.stringify(stage4Validation.issues)}`)
export const stage5Content = stage5Data as ContentPack
const stage5Validation = validateContent(stage5Content, (path) => Object.hasOwn(images, path))
if (!stage5Validation.valid) throw new Error(`Invalid Stage 5 content: ${JSON.stringify(stage5Validation.issues)}`)
export const stage6Content = stage6Data as ContentPack
const stage6Validation = validateContent(stage6Content, (path) => Object.hasOwn(images, path))
if (!stage6Validation.valid) throw new Error(`Invalid Stage 6 content: ${JSON.stringify(stage6Validation.issues)}`)
export const stage7Content = stage7Data as ContentPack
const stage7Validation = validateContent(stage7Content, (path) => Object.hasOwn(images, path))
if (!stage7Validation.valid) throw new Error(`Invalid Stage 7 content: ${JSON.stringify(stage7Validation.issues)}`)
export const MATILDA_STORY_ID = 'story.matilda'
export const normalContent = fixedContent
export const NORMAL_STORY_ID = 'story.matilda.normal'
export function normalStoryForCheckpoint(id: string): string | undefined {
  return normalContent.stories.find((story) => story.steps.some((step) => step.id === id))?.id
}
const normalValidation = validateContent(normalContent, (path) => Object.hasOwn(images, path))
if (!normalValidation.valid) throw new Error(`Invalid normal content: ${JSON.stringify(normalValidation.issues)}`)

export function tutorialImage(assetId: string): string {
  const asset = [...prologueContent.assets, ...matildaContent.assets, ...fixedContent.assets, ...subevent1JinContent.assets]
    .find((entry) => entry.id === assetId)
  if (!asset || !Object.hasOwn(images, asset.path)) throw new Error(`Unknown tutorial asset: ${assetId}`)
  return images[asset.path]
}

export function isStage2Checkpoint(id: string): boolean {
  return stage2Content.stories.some((story) => story.steps.some((step) => step.id === id))
}

export function isStage3ContentCheckpoint(id: string): boolean {
  return stage3Content.stories.some((story) => story.steps.some((step) => step.id === id))
}

export function isMatildaCheckpoint(id: string): boolean {
  return matildaContent.stories[0].steps.some((step) => step.id === id && (step.kind === 'line' || step.kind === 'battle' || step.kind === 'end')) ||
    normalContent.stories.filter((story) => !story.id.startsWith('story.stage2.') && !story.id.startsWith('story.subevent2.') &&
      !story.id.startsWith('story.stage3.') && !story.id.startsWith('story.stage4.') && !story.id.startsWith('story.stage5.') &&
      !story.id.startsWith('story.stage6.') && !story.id.startsWith('story.stage7.'))
      .some((story) => story.steps.some((step) => step.id === id && (step.kind === 'line' || step.kind === 'battle' || step.kind === 'end')))
}
