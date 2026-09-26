import { HANDS } from '../domain/card'
import { getCardDefinition } from '../domain/card-catalog'

export type ContentIssueCode =
  | 'invalid_value'
  | 'duplicate_id'
  | 'missing_reference'
  | 'missing_asset'
  | 'invalid_deck'

export interface ContentIssue {
  path: string
  code: ContentIssueCode
  message: string
}

export type ContentValidation =
  | { valid: true; issues: [] }
  | { valid: false; issues: ContentIssue[] }

type RecordValue = Record<string, unknown>
type ReferenceKind = 'asset' | 'layout' | 'battle' | 'step'

function isAssetPath(path: string): boolean {
  return path.startsWith('godot/assets/') && !path.includes('\\') && !path.includes('\0') &&
    path.split('/').every((part) => part !== '' && part !== '.' && part !== '..')
}

export function validateContent(value: unknown, assetExists: (path: string) => boolean): ContentValidation {
  const issues: ContentIssue[] = []
  const allIds = new Map<string, string>()
  const known: Record<ReferenceKind, Set<string>> = {
    asset: new Set(), layout: new Set(), battle: new Set(), step: new Set()
  }
  const references: { path: string; id: string; kind: ReferenceKind }[] = []

  const issue = (path: string, code: ContentIssueCode, message: string): void => {
    issues.push({ path, code, message })
  }

  const object = (input: unknown, path: string, required: string[], optional: string[] = []): RecordValue | null => {
    if (input === null || typeof input !== 'object' || Array.isArray(input)) {
      issue(path, 'invalid_value', 'Expected an object')
      return null
    }
    const prototype = Object.getPrototypeOf(input)
    if (prototype !== Object.prototype && prototype !== null) {
      issue(path, 'invalid_value', 'Expected a plain object')
      return null
    }
    const keys = Reflect.ownKeys(input)
    if (keys.some((key) => typeof key !== 'string' || !required.includes(key) && !optional.includes(key)) ||
        required.some((key) => !Object.hasOwn(input, key))) {
      issue(path, 'invalid_value', 'Missing or unknown fields')
    }
    if (keys.some((key) => {
      const descriptor = Object.getOwnPropertyDescriptor(input, key)
      return !descriptor || !('value' in descriptor)
    })) {
      issue(path, 'invalid_value', 'Accessors are not allowed')
      return null
    }
    return input as RecordValue
  }

  const array = (input: unknown, path: string): unknown[] => {
    if (!Array.isArray(input)) {
      issue(path, 'invalid_value', 'Expected an array')
      return []
    }
    return Array.from(input)
  }

  const identifier = (input: unknown, path: string): string | null => {
    if (typeof input !== 'string' || input.trim() === '') {
      issue(path, 'invalid_value', 'Expected a non-empty identifier')
      return null
    }
    return input
  }

  const register = (input: unknown, path: string, kind?: ReferenceKind): void => {
    const id = identifier(input, path)
    if (id === null) return
    const first = allIds.get(id)
    if (first !== undefined) issue(path, 'duplicate_id', `ID already used at ${first}`)
    else allIds.set(id, path)
    if (kind) known[kind].add(id)
  }

  const reference = (input: unknown, path: string, kind: ReferenceKind): void => {
    const id = identifier(input, path)
    if (id !== null) references.push({ path, id, kind })
  }

  const finite = (input: unknown, path: string, positive = false): number | null => {
    if (typeof input !== 'number' || !Number.isFinite(input) || positive && input <= 0) {
      issue(path, 'invalid_value', 'Expected a finite number in range')
      return null
    }
    return input
  }

  const nonnegativeInteger = (input: unknown, path: string, positive = false): number | null => {
    if (!Number.isSafeInteger(input) || (input as number) < (positive ? 1 : 0)) {
      issue(path, 'invalid_value', 'Expected a non-negative safe integer')
      return null
    }
    return input as number
  }

  const root = object(value, '$', ['assets', 'layouts', 'battles', 'stories'])
  if (root === null) return { valid: false, issues }

  array(root.assets, '$.assets').forEach((entry, index) => {
    const path = `$.assets[${index}]`
    const asset = object(entry, path, ['id', 'path'])
    if (asset === null) return
    register(asset.id, `${path}.id`, 'asset')
    if (typeof asset.path !== 'string' || !isAssetPath(asset.path)) {
      issue(`${path}.path`, 'invalid_value', 'Expected a repository-relative godot/assets path')
    } else {
      try {
        if (!assetExists(asset.path)) issue(`${path}.path`, 'missing_asset', 'Image file does not exist')
      } catch {
        issue(`${path}.path`, 'missing_asset', 'Image file could not be checked')
      }
    }
  })

  array(root.layouts, '$.layouts').forEach((entry, index) => {
    const path = `$.layouts[${index}]`
    const layout = object(entry, path, ['id', 'x', 'y', 'scale', 'flipped'])
    if (layout === null) return
    register(layout.id, `${path}.id`, 'layout')
    finite(layout.x, `${path}.x`)
    finite(layout.y, `${path}.y`)
    finite(layout.scale, `${path}.scale`, true)
    if (typeof layout.flipped !== 'boolean') issue(`${path}.flipped`, 'invalid_value', 'Expected a boolean')
  })

  array(root.battles, '$.battles').forEach((entry, index) => {
    const path = `$.battles[${index}]`
    const battle = object(entry, path, [
      'id', 'opponent_id', 'background_asset_id', 'player_deck_size', 'opponent_deck_size',
      'opponent_card_ids', 'gold_reward', 'transfer_cards', 'rules'
    ])
    if (battle === null) return
    register(battle.id, `${path}.id`, 'battle')
    identifier(battle.opponent_id, `${path}.opponent_id`)
    reference(battle.background_asset_id, `${path}.background_asset_id`, 'asset')
    nonnegativeInteger(battle.player_deck_size, `${path}.player_deck_size`, true)
    const opponentDeckSize = nonnegativeInteger(battle.opponent_deck_size, `${path}.opponent_deck_size`, true)
    const cards = array(battle.opponent_card_ids, `${path}.opponent_card_ids`)
    if (cards.length === 0) issue(`${path}.opponent_card_ids`, 'invalid_deck', 'Opponent deck must not be empty')
    if (opponentDeckSize !== null && cards.length !== opponentDeckSize) {
      issue(`${path}.opponent_card_ids`, 'invalid_deck', 'Opponent deck size does not match')
    }
    cards.forEach((cardId, cardIndex) => {
      if (typeof cardId !== 'string' || !getCardDefinition(cardId)) {
        issue(`${path}.opponent_card_ids[${cardIndex}]`, 'invalid_deck', 'Unknown card ID')
      }
    })
    const reward = object(battle.gold_reward, `${path}.gold_reward`, ['min', 'max'])
    if (reward !== null) {
      const min = nonnegativeInteger(reward.min, `${path}.gold_reward.min`)
      const max = nonnegativeInteger(reward.max, `${path}.gold_reward.max`)
      if (min !== null && max !== null && min > max) {
        issue(`${path}.gold_reward`, 'invalid_value', 'Minimum reward exceeds maximum')
      }
    }
    if (typeof battle.transfer_cards !== 'boolean') {
      issue(`${path}.transfer_cards`, 'invalid_value', 'Expected a boolean')
    }
    const seenRules = new Set<string>()
    array(battle.rules, `${path}.rules`).forEach((entry, ruleIndex) => {
      const rulePath = `${path}.rules[${ruleIndex}]`
      const rule = object(entry, rulePath, ['kind'], ['hand', 'value'])
      if (rule === null) return
      if (rule.kind !== 'fixed_opponent_hand' && rule.kind !== 'player_win_rate') {
        issue(`${rulePath}.kind`, 'invalid_value', 'Unknown battle rule')
        return
      }
      if (seenRules.has(rule.kind)) issue(rulePath, 'invalid_value', 'Duplicate battle rule')
      seenRules.add(rule.kind)
      if (rule.kind === 'fixed_opponent_hand') {
        if (Object.hasOwn(rule, 'value') || !HANDS.includes(rule.hand as (typeof HANDS)[number])) {
          issue(rulePath, 'invalid_value', 'Invalid fixed opponent hand')
        }
      } else {
        if (Object.hasOwn(rule, 'hand') || typeof rule.value !== 'number' ||
            !Number.isFinite(rule.value) || rule.value < 0 || rule.value > 1) {
          issue(rulePath, 'invalid_value', 'Player win rate must be between 0 and 1')
        }
      }
    })
  })

  array(root.stories, '$.stories').forEach((entry, index) => {
    const path = `$.stories[${index}]`
    const story = object(entry, path, ['id', 'start_id', 'steps'])
    if (story === null) return
    register(story.id, `${path}.id`)
    reference(story.start_id, `${path}.start_id`, 'step')
    const steps = array(story.steps, `${path}.steps`)
    if (steps.length === 0) issue(`${path}.steps`, 'invalid_value', 'Story must contain a step')
    steps.forEach((entry, stepIndex) => {
      const stepPath = `${path}.steps[${stepIndex}]`
      const step = object(entry, stepPath, ['id', 'kind'], [
        'speaker_id', 'text', 'next_id', 'asset_id', 'slot_id', 'layout_id',
        'options', 'target_id', 'battle_id'
      ])
      if (step === null) return
      register(step.id, `${stepPath}.id`, 'step')
      const next = () => reference(step.next_id, `${stepPath}.next_id`, 'step')
      switch (step.kind) {
        case 'line':
          object(entry, stepPath, ['id', 'kind', 'text', 'next_id'], ['speaker_id'])
          if (typeof step.text !== 'string' || step.text.trim() === '') {
            issue(`${stepPath}.text`, 'invalid_value', 'Line text must not be empty')
          }
          if (Object.hasOwn(step, 'speaker_id')) identifier(step.speaker_id, `${stepPath}.speaker_id`)
          next()
          break
        case 'background':
          object(entry, stepPath, ['id', 'kind', 'asset_id', 'next_id'])
          reference(step.asset_id, `${stepPath}.asset_id`, 'asset')
          next()
          break
        case 'show_portrait':
          object(entry, stepPath, ['id', 'kind', 'slot_id', 'asset_id', 'layout_id', 'next_id'])
          identifier(step.slot_id, `${stepPath}.slot_id`)
          reference(step.asset_id, `${stepPath}.asset_id`, 'asset')
          reference(step.layout_id, `${stepPath}.layout_id`, 'layout')
          next()
          break
        case 'hide_portrait':
          object(entry, stepPath, ['id', 'kind', 'slot_id', 'next_id'])
          identifier(step.slot_id, `${stepPath}.slot_id`)
          next()
          break
        case 'choice': {
          object(entry, stepPath, ['id', 'kind', 'options'])
          const options = array(step.options, `${stepPath}.options`)
          if (options.length < 2) issue(`${stepPath}.options`, 'invalid_value', 'Choice needs at least two options')
          options.forEach((entry, optionIndex) => {
            const optionPath = `${stepPath}.options[${optionIndex}]`
            const option = object(entry, optionPath, ['label', 'next_id'])
            if (option === null) return
            identifier(option.label, `${optionPath}.label`)
            reference(option.next_id, `${optionPath}.next_id`, 'step')
          })
          break
        }
        case 'goto':
          object(entry, stepPath, ['id', 'kind', 'target_id'])
          reference(step.target_id, `${stepPath}.target_id`, 'step')
          break
        case 'battle':
          object(entry, stepPath, ['id', 'kind', 'battle_id', 'next_id'])
          reference(step.battle_id, `${stepPath}.battle_id`, 'battle')
          next()
          break
        case 'end':
          object(entry, stepPath, ['id', 'kind'])
          break
        default:
          issue(`${stepPath}.kind`, 'invalid_value', 'Unknown story step')
      }
    })
  })

  for (const { path, id, kind } of references) {
    if (!known[kind].has(id)) issue(path, 'missing_reference', `Unknown ${kind} ID: ${id}`)
  }
  return issues.length === 0 ? { valid: true, issues: [] } : { valid: false, issues }
}
