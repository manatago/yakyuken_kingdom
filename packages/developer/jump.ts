import document from '../../content/developer-tools.json'
import { originalStory } from '../story/original'
import { createNewGameSave } from '../domain/new-game'
import { parseSave, type SaveData } from '../domain/save'
import { ORIGINAL_QUEST_ROUTES } from '../story/original-quests'
import { ORIGINAL_STAGE1_END } from '../guild/routes'

export const developerTools = document
type Target = { available: true; sequence: string; cursor: number; guild?: boolean }
  | { available: false; reason: string }

/** The original list includes separator rows and special Main handlers, not just story labels. */
export function developerJumpTarget(value: unknown): Target {
  if (typeof value !== 'number' || !Number.isSafeInteger(value) || value < 0 || value >= developerTools.jump_points.length) {
    throw new Error('Unknown original jump point')
  }
  const point = developerTools.jump_points[value]
  if (point.name.startsWith('---')) return { available: false, reason: '章の区切りです。下の場面を選択してください。' }
  let sequence = 'sequence' in point ? String(point.sequence) : 'prologue'
  let label = point.label
  if (label === '_guild_home') return { available: true, sequence: 'stage1', cursor: 0, guild: true }
  if (label === '_matilda_lose') return { available: false, reason: '原本の専用再挑戦／ホーム選択の接続は実装中です。' }
  if (label.startsWith('_result:')) {
    sequence = label === '_result:win' ? 'prologue_battle_win' : 'prologue_battle_lose'; label = ''
  } else if (label.startsWith('_subevent_')) {
    const [part, id] = label.slice(10).split(':')
    const routes: Record<string, Record<string, string>> = {
      subevent1: { pre1: 'subevent1_pre', pre2: 'subevent1_hideout', post: 'subevent1_post' },
      subevent2: { pre1: 'subevent2_pre1', pre2: 'subevent2_pre2', post: 'subevent2_post' },
      subevent3: { pre: 'subevent3_pre', pre2: 'subevent3_blacksmith', pre3: 'subevent3_visit', post: 'subevent3_post' },
      subevent4: { pre: 'subevent4_pre', post: 'subevent4_post' }
    }
    sequence = routes[id]?.[part] ?? ''; label = ''
  } else if (label.startsWith('_minigame:')) {
    const battle = developerTools.battle_targets.find(target => target.id === label.slice(10))
    if (!battle) return { available: false, reason: '原本のミニゲーム対象が見つかりません。' }
    for (const scene of originalStory.sequences) {
      const index = scene.commands.findIndex(command => command.kind === 'battle' && command.parameters.chapter_path === battle.path)
      if (index >= 0) return { available: true, sequence: scene.id, cursor: index + 1 }
    }
    return { available: false, reason: '原本のスモーク専用ミニゲームは通常ストーリーに未接続です。移植未完了。' }
  }
  const scene = originalStory.sequences.find(scene => scene.id === sequence)
  if (!scene) return { available: false, reason: `未対応の原本シーケンス：${sequence}` }
  const index = label ? scene.commands.findIndex(command => command.kind === 'label' && command.parameters.label_name === label) : 0
  if (index < 0) return { available: false, reason: `原本の開始ラベルが見つかりません：${label}` }
  return { available: true, sequence, cursor: label ? index + 1 : 0 }
}

export function createDeveloperJumpSave(index: number): SaveData {
  const target = developerJumpTarget(index)
  if (!target.available) throw new Error(target.reason)
  const point = developerTools.jump_points[index]
  return createJumpSave(target, point.state)
}

export const eventBattleTargets = developerTools.battle_targets.filter(target => target.mode === 'battle')

export function createDeveloperEventSave(id: string): SaveData {
  const event = eventBattleTargets.find(target => target.id === id)
  if (!event) throw new Error('Unknown original event battle')
  for (const scene of originalStory.sequences) {
    const index = scene.commands.findIndex(command => command.kind === 'battle' && command.parameters.chapter_path === event.path &&
      !command.parameters.is_tutorial && !command.parameters.is_minigame)
    if (index >= 0) return createJumpSave({ available: true, sequence: scene.id, cursor: index + 1 },
      { inventory: developerTools.jump_points[0].state.inventory, money: 1000, flags: {} })
  }
  throw new Error('Original event battle is not connected')
}

function createJumpSave(target: Extract<Target, { available: true }>, state: { inventory: { hand: string; grade: number }[]; money: number; flags: Record<string, boolean | undefined> }): SaveData {
  const initial = createNewGameSave()
  const id = Object.keys(ORIGINAL_QUEST_ROUTES).find(id => target.sequence.startsWith(id)) as keyof typeof ORIGINAL_QUEST_ROUTES | undefined
  const quest = id && (ORIGINAL_QUEST_ROUTES[id] as readonly string[]).includes(target.sequence) || target.sequence === 'subevent2_rematch'
  const route = target.sequence === 'subevent2_rematch' ? ['subevent2_rematch', 'subevent2_post'] : id ? [...ORIGINAL_QUEST_ROUTES[id]] : []
  const completed = route.slice(0, route.indexOf(target.sequence) + 1).flatMap(sequence =>
    originalStory.sequences.find(scene => scene.id === sequence)!.commands.flatMap((command, index) =>
      command.kind === 'battle' && (sequence !== target.sequence || index + 1 < target.cursor) ? [`original:${sequence}:${index + 1}`] : []))
  const save = { ...initial,
    player: { ...initial.player, inventory: structuredClone(state.inventory), money: state.money },
    progress: { ...initial.progress,
      flags: Object.entries(state.flags).filter(([, enabled]) => enabled).map(([id]) => id),
      checkpoint_id: target.guild ? 'guild.home' : `original:${target.sequence}:${target.cursor}`,
      ...(target.guild ? { guild_return_checkpoint: ORIGINAL_STAGE1_END } : {}),
      ...(quest ? { original_quest: { id: id ?? 'subevent2', origin_checkpoint: ORIGINAL_STAGE1_END,
        route: target.sequence === 'subevent2_rematch' ? 'rematch' : 'full', completed_battles: completed } } : {}) }
  }
  return parseSave(save)
}
