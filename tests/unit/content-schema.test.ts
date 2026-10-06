import assert from 'node:assert/strict'
import { existsSync } from 'node:fs'
import { join } from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'

const root = fileURLToPath(new URL('../..', import.meta.url))
const assetExists = (path: string) => existsSync(join(root, path))

function example(): ContentPack {
  return {
    assets: [
      { id: 'background.prison', path: 'godot/assets/backgrounds/prologue/bg05_prison_cell.png' },
      { id: 'portrait.matilda', path: 'godot/assets/characters/mob/guard/default/guard_default_024.png' }
    ],
    layouts: [{ id: 'layout.matilda', x: 960, y: 420, scale: 0.8, flipped: false }],
    battles: [{
      id: 'battle.matilda', opponent_id: 'matilda', background_asset_id: 'background.prison',
      player_deck_size: 9, opponent_deck_size: 9,
      opponent_card_ids: [
        ...Array(3).fill('rock_normal'),
        ...Array(3).fill('scissors_normal'),
        ...Array(3).fill('paper_normal')
      ],
      gold_reward: { min: 10, max: 30 }, transfer_cards: false,
      phases: [
        { id: 'phase.matilda.first', rules: [{ kind: 'fixed_opponent_hand', hand: 'rock' }] },
        { id: 'phase.matilda.second', rules: [{ kind: 'player_win_rate', value: 0.8 }] }
      ]
    }],
    stories: [{
      id: 'story.matilda', start_id: 'step.background', steps: [
        { id: 'step.background', kind: 'background', asset_id: 'background.prison', next_id: 'step.portrait' },
        { id: 'step.portrait', kind: 'show_portrait', slot_id: 'matilda', asset_id: 'portrait.matilda', layout_id: 'layout.matilda', next_id: 'step.line' },
        { id: 'step.line', kind: 'line', speaker_id: 'matilda', text: 'グー、チョキ、パーの3種類がある。', next_id: 'step.choice' },
        { id: 'step.choice', kind: 'choice', options: [
          { label: '練習する', next_id: 'step.battle' },
          { label: 'もう一度聞く', next_id: 'step.line' }
        ] },
        { id: 'step.battle', kind: 'battle', battle_id: 'battle.matilda', next_id: 'step.hide' },
        { id: 'step.hide', kind: 'hide_portrait', slot_id: 'matilda', next_id: 'step.end' },
        { id: 'step.end', kind: 'end' }
      ]
    }]
  }
}

test('JSON content describes Matilda-like story, battle and layout without mutation', () => {
  const document = example()
  const before = structuredClone(document)
  assert.deepEqual(validateContent(JSON.parse(JSON.stringify(document)), assetExists), {
    valid: true, issues: []
  })
  assert.deepEqual(document, before)
})

test('content validator reports duplicate IDs and broken references', () => {
  const document: any = example()
  document.assets.push({ id: 'background.prison', path: 'godot/assets/backgrounds/prologue/bg05_prison_cell.png' })
  document.stories[0].start_id = 'missing.start'
  document.stories[0].steps[0].next_id = 'missing.step'
  document.stories[0].steps[1].layout_id = 'missing.layout'
  document.stories[0].steps[3].options[0].next_id = 'missing.choice'
  document.stories[0].steps[4].battle_id = 'missing.battle'
  document.battles[0].background_asset_id = 'missing.asset'
  const result = validateContent(document, assetExists)
  assert.equal(result.valid, false)
  assert.ok(result.issues.some((issue) => issue.code === 'duplicate_id' && issue.path.includes('assets')))
  assert.ok(result.issues.some((issue) => issue.code === 'missing_reference' && issue.path.includes('next_id')))
  assert.ok(result.issues.some((issue) => issue.code === 'missing_reference' && issue.path.includes('battle_id')))
  assert.ok(result.issues.some((issue) => issue.code === 'missing_reference' && issue.path.includes('layout_id')))
  assert.ok(result.issues.some((issue) => issue.code === 'missing_reference' && issue.path.includes('start_id')))
  assert.ok(result.issues.some((issue) => issue.code === 'missing_reference' && issue.path.includes('options')))
})

test('battle rules are scoped to ordered phases with unique IDs', () => {
  const document: any = example()
  assert.deepEqual(document.battles[0].phases.map((phase: any) => phase.rules), [
    [{ kind: 'fixed_opponent_hand', hand: 'rock' }],
    [{ kind: 'player_win_rate', value: 0.8 }]
  ])
  document.battles[0].phases[1].rules.push({ kind: 'fixed_opponent_hand', hand: 'paper' })
  assert.equal(validateContent(document, assetExists).valid, true)

  document.battles[0].phases[1].rules.push({ kind: 'fixed_opponent_hand', hand: 'scissors' })
  document.battles[0].phases[1].id = 'phase.matilda.first'
  const result = validateContent(document, assetExists)
  assert.equal(result.valid, false)
  assert.ok(result.issues.some((issue) => issue.code === 'duplicate_id' && issue.path.endsWith('phases[1].id')))
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_value' && issue.path.endsWith('phases[1].rules[2]')))
})

test('battle requires phases and rejects unscoped rules', () => {
  const document: any = example()
  document.battles[0].rules = document.battles[0].phases[0].rules
  document.battles[0].phases = []
  const result = validateContent(document, assetExists)
  assert.equal(result.valid, false)
  assert.ok(result.issues.some((issue) => issue.path === '$.battles[0]' && issue.code === 'invalid_value'))
  assert.ok(result.issues.some((issue) => issue.path === '$.battles[0].phases' && issue.code === 'invalid_value'))
})

test('content validator rejects missing or unsafe assets and invalid layouts', () => {
  const document: any = example()
  document.assets[1].path = 'godot/assets/characters/missing.png'
  document.assets[0].path = '../outside.png'
  document.layouts[0].scale = 0
  const result = validateContent(document, assetExists)
  assert.equal(result.valid, false)
  assert.ok(result.issues.some((issue) => issue.code === 'missing_asset'))
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_value' && issue.path.includes('assets')))
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_value' && issue.path.includes('scale')))
})

test('content validator rejects invalid decks, rewards and special rules', () => {
  const document: any = example()
  document.battles[0].opponent_card_ids[0] = 'unknown_card'
  document.battles[0].opponent_card_ids.pop()
  document.battles[0].gold_reward.min = 50
  document.battles[0].phases[1].rules[0].value = 1.5
  const result = validateContent(document, assetExists)
  assert.equal(result.valid, false)
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_deck'))
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_value' && issue.path.includes('gold_reward')))
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_value' && issue.path.includes('rules')))
})

test('malformed JSON-shaped data yields issues instead of throwing', () => {
  for (const value of [null, {}, { ...example(), stories: [null] }, { ...example(), assets: 'invalid' }]) {
    const result = validateContent(value, assetExists)
    assert.equal(result.valid, false)
    assert.ok(result.issues.length > 0)
  }
})

test('content validation covers optional battle rules and unusual object shapes', () => {
  const document: any = example()
  const battle = document.battles[0]
  battle.round_limit = 10
  battle.item_reward_ids = ['healing_potion', 'healing_potion', 'unknown-item']
  battle.card_reward = { hand: 'lizard', grade: 8 }
  battle.hp = { player: 0, opponent: 0, grade_effect_passes: 3, lose_gold: -1,
    first_hand: 'lizard', forced_outcome: 'maybe', extra: true }
  battle.opponent_tendency = { rock: 0.5, lizard: 1, scissors: 3 }
  battle.bayes_eye = 'yes'
  battle.result_route = 'unknown'
  battle.lose_checkpoint_id = 'step.choice'
  battle.phases[0].rules = [
    { kind: 'fixed_opponent_hand', hand: 'lizard', value: 1 },
    { kind: 'player_win_rate', hand: 'rock', value: -1 },
    { kind: 'unsupported' }
  ]
  document.assets.push({ id: 'asset.invalid', path: 'godot/assets//bad.png' })
  document.layouts[0].flipped = 'false'
  document.stories[0].steps.push({ id: 'step.unknown', kind: 'teleport' })
  const result = validateContent(document, () => { throw new Error('asset check failed') })
  assert.equal(result.valid, false)
  assert.ok(result.issues.some((issue) => issue.code === 'missing_asset'))
  assert.ok(result.issues.some((issue) => issue.path.endsWith('lose_checkpoint_id')))
  assert.ok(result.issues.some((issue) => issue.path.endsWith('forced_outcome')))
  assert.ok(result.issues.some((issue) => issue.path.endsWith('card_reward.hand')))
  assert.ok(result.issues.some((issue) => issue.path.endsWith('opponent_tendency.lizard')))
  assert.ok(result.issues.some((issue) => issue.path.endsWith('rules[2].kind')))

  const accessor = example() as any
  Object.defineProperty(accessor.stories[0].steps[0], 'next_id', { enumerable: true, get: () => 'step.end' })
  assert.ok(validateContent(accessor, assetExists).issues.some((issue) => issue.message === 'Accessors are not allowed'))
  assert.equal(validateContent(Object.create({ assets: [], layouts: [], battles: [], stories: [] }), assetExists).valid, false)
  const emptyIdentifier: any = example()
  emptyIdentifier.assets[0].id = '  '
  assert.ok(validateContent(emptyIdentifier, assetExists).issues.some((issue) => issue.path === '$.assets[0].id'))
  const underspecifiedChoice: any = example()
  underspecifiedChoice.stories[0].steps[3].options.pop()
  assert.ok(validateContent(underspecifiedChoice, assetExists).issues.some((issue) => issue.path.endsWith('.options')))
})
