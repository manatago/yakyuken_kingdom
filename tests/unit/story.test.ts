import assert from 'node:assert/strict'
import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'
import { advanceStory, nextStoryCheckpoint, startStory } from '../../packages/story/runner'
import { fitViewport } from '../../packages/story/viewport'

const root = fileURLToPath(new URL('../..', import.meta.url))
const fixture = (): ContentPack => ({
  assets: [{ id: 'bg', path: 'godot/assets/bg.png' }, { id: 'face', path: 'godot/assets/face.png' }],
  layouts: [{ id: 'layout', x: 960, y: 440, scale: .8, flipped: false }], battles: [],
  stories: [{ id: 'story', start_id: 'bg-step', steps: [
    { id: 'bg-step', kind: 'background', asset_id: 'bg', next_id: 'show' },
    { id: 'show', kind: 'show_portrait', slot_id: 'matilda', asset_id: 'face', layout_id: 'layout', next_id: 'one' },
    { id: 'one', kind: 'line', text: '最初', next_id: 'two' },
    { id: 'two', kind: 'line', text: '追記', append: true, next_id: 'hide' },
    { id: 'hide', kind: 'hide_portrait', slot_id: 'matilda', next_id: 'three' },
    { id: 'three', kind: 'line', text: '新しい文章', next_id: 'end' },
    { id: 'end', kind: 'end' }
  ] }]
})

test('story advances visual commands and restores accumulated text without mutation', () => {
  const pack = fixture()
  const before = structuredClone(pack)
  const one = startStory(pack, 'story')
  assert.equal(one.step.id, 'one')
  assert.equal(one.backgroundAssetId, 'bg')
  assert.deepEqual(one.portraits.matilda, { assetId: 'face', layoutId: 'layout' })
  const two = advanceStory(pack, 'story', one)
  assert.equal(two.text, '最初\n追記')
  assert.deepEqual(startStory(pack, 'story', 'two'), two)
  const three = advanceStory(pack, 'story', two)
  assert.equal(three.text, '新しい文章')
  assert.deepEqual(three.portraits, {})
  assert.equal(advanceStory(pack, 'story', three).step.kind, 'end')
  assert.deepEqual(pack, before)
  assert.equal(one.text, '最初')
})

test('story text variables are interpolated on resume and advancement', () => {
  const pack = fixture()
  pack.stories[0]!.steps[3] = { id: 'two', kind: 'line', text: '報酬は金貨{{rewardGold}}枚', append: true, next_id: 'hide' }
  const variables = { rewardGold: 58 }
  const one = startStory(pack, 'story')
  assert.equal(nextStoryCheckpoint(pack, 'story', one), 'two')
  const two = advanceStory(pack, 'story', one, variables)
  assert.equal(two.text, '最初\n報酬は金貨58枚')
  assert.equal(startStory(pack, 'story', 'two', variables).text, two.text)
  assert.throws(() => advanceStory(pack, 'story', one), /Missing story text variable: rewardGold/)
  assert.equal(advanceStory(pack, 'story', two, variables).text, '新しい文章')
})

test('invalid checkpoints and automatic-command loops fail instead of hanging', () => {
  const pack = fixture()
  assert.throws(() => startStory(pack, 'missing'))
  assert.throws(() => startStory(pack, 'story', 'missing'))
  pack.stories[0].steps[0] = { id: 'bg-step', kind: 'goto', target_id: 'bg-step' }
  assert.throws(() => startStory(pack, 'story'), /loop/i)
})

test('disconnected legacy terminal checkpoints remain resumable result screens', () => {
  const pack = fixture()
  pack.stories[0]!.steps[5] = { id: 'three', kind: 'line', text: '金貨{{rewardGold}}枚', next_id: 'end' }
  pack.stories[0]!.steps.push({ id: 'legacy-end', kind: 'end' })
  const frame = startStory(pack, 'story', 'legacy-end')
  assert.equal(frame.step.id, 'legacy-end')
  assert.equal(frame.step.kind, 'end')
  assert.equal(frame.backgroundAssetId, undefined)
  assert.deepEqual(frame.portraits, {})
  assert.equal(nextStoryCheckpoint(pack, 'story', frame), 'legacy-end')
  pack.stories[0]!.steps.push({ id: 'orphan-line', kind: 'line', text: '古い会話', next_id: 'legacy-end' })
  assert.throws(() => startStory(pack, 'story', 'orphan-line', { rewardGold: 0 }), /Unreachable checkpoint: orphan-line/)
})

test('append is a validated optional boolean', () => {
  const pack = fixture()
  assert.equal(validateContent(pack, () => true).valid, true)
  const invalid: any = structuredClone(pack)
  invalid.stories[0].steps[2].append = 'true'
  assert.equal(validateContent(invalid, () => true).valid, false)
})

test('Matilda tutorial JSON reaches its practice battle and closing dialogue', () => {
  const pack = JSON.parse(readFileSync(join(root, 'content/stories/matilda-tutorial.json'), 'utf8')) as ContentPack
  assert.deepEqual(validateContent(pack, (path) => existsSync(join(root, path))), { valid: true, issues: [] })
  let frame = startStory(pack, 'story.matilda', 'matilda.start')
  assert.match(frame.text, /周りの風景/)
  const text: string[] = []
  while (frame.step.kind === 'line') {
    text.push(frame.text)
    frame = advanceStory(pack, 'story.matilda', frame)
  }
  assert.ok(text.some((line) => line.includes('Nはノーマル、Bはブロンズ、Sはシルバー、Gはゴールド、Pはプラチナだ。')))
  assert.ok(text.some((line) => line.includes('今回は練習だから、互いにNのカードだけを使う。')))
  assert.equal(frame.step.id, 'matilda.await-deck')
  assert.equal(frame.step.kind, 'battle')
  assert.match(advanceStory(pack, 'story.matilda', frame).text, /これがじゃんけんバトルの基本/)
  assert.equal(startStory(pack, 'story.matilda', 'matilda.complete').backgroundAssetId, 'background.prison')
})

test('FHD viewport scales uniformly and centers margins', () => {
  assert.deepEqual(fitViewport(1920, 1080), { scale: 1, width: 1920, height: 1080, left: 0, top: 0 })
  assert.deepEqual(fitViewport(1024, 768), { scale: 1024 / 1920, width: 1024, height: 576, left: 0, top: 96 })
  const tall = fitViewport(600, 1000)
  assert.equal(tall.height, 337.5)
  assert.equal(tall.top, 331.25)
  assert.throws(() => fitViewport(-1, 1080))
})
