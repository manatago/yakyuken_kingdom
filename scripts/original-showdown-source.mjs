import assert from 'node:assert/strict'

function body(source, name) {
  const start = source.indexOf(`func ${name}(`)
  assert.ok(start >= 0, `Missing original function ${name}`)
  const end = source.indexOf('\nfunc ', start + 1)
  return source.slice(start, end < 0 ? source.length : end)
}

function node(scene, name) {
  const start = scene.indexOf(`[node name="${name}" type=`)
  assert.ok(start >= 0, `Missing original node ${name}`)
  const end = scene.indexOf('\n[node ', start + 1)
  return scene.slice(start, end < 0 ? scene.length : end)
}

function one(source, pattern, description) {
  const match = source.match(pattern)
  assert.ok(match, `Unsupported original showdown ${description}`)
  return match.slice(1)
}

const rounded = value => Math.round(value * 1e9) / 1e9

// Fail closed when the source no longer has the supported ordering/geometry.
// A non-awaited Godot coroutine starts the result pop alongside the hold timer.
export function extractOriginalShowdown(source, scene, base) {
  const overlay = body(source, '_play_janken_overlay')
  const pop = body(source, '_show_overlay_result')
  assert.match(overlay, /\n\t_show_overlay_result\(result, grade_reason\)/, 'Result pop must remain unawaited')
  const ordering = [...overlay.matchAll(/tween_property\(overlay_(opponent|player)_card, "(position:x|scale:x)", ([^,]+), [\d.]+\)|create_timer\([\d.]+\)|\n\t_show_overlay_result\(result, grade_reason\)|tween_property\(janken_overlay,/g)].map(match => {
    if (match[1]) return match[2] === 'position:x' ? `slide:${match[1]}` : `flip:${match[1]}:${Number(match[3])}`
    if (match[0].startsWith('create_timer')) return 'wait'
    if (match[0].includes('_show_overlay_result')) return 'result'
    return 'fade'
  })
  assert.deepEqual(ordering, ['slide:opponent', 'wait', 'slide:player', 'wait', 'flip:player:0', 'flip:player:1',
    'wait', 'flip:opponent:0', 'flip:opponent:1', 'result', 'wait', 'fade'], 'Unsupported original showdown ordering')
  for (const expression of ['card_h * 2.0 / 3.0', '(vp_size.y - card_h) / 2.0 - 80.0',
    'vp_size.x / 2.0 - card_w - 30.0', 'vp_size.x / 2.0 + 30.0',
    'Vector2(-card_w - 50, center_y)', 'Vector2(vp_size.x + 50, center_y)']) {
    assert.ok(overlay.includes(expression), `Unsupported original showdown geometry: ${expression}`)
  }
  const [maxHeight, heightRatio] = one(overlay, /minf\(([\d.]+), vp_size.y \* ([\d.]+)\)/, 'height').map(Number)
  const slides = [...overlay.matchAll(/tween_property\(overlay_(opponent|player)_card, "position:x", (\w+), ([\d.]+)\)/g)]
  assert.deepEqual(slides.map(m => [m[1], m[2]]), [['opponent', 'opponent_end_x'], ['player', 'player_end_x']])
  const flips = [...overlay.matchAll(/tween_property\(overlay_(player|opponent)_card, "scale:x", ([\d.]+), ([\d.]+)\)/g)]
  assert.deepEqual(flips.map(m => [m[1], Number(m[2])]), [['player', 0], ['player', 1], ['opponent', 0], ['opponent', 1]])
  const pauseSeconds = [...overlay.matchAll(/create_timer\(([\d.]+)\)/g)].map(m => Number(m[1]))
  assert.equal(pauseSeconds.length, 4)
  const slideSeconds = slides.map(m => Number(m[3]))
  const flipSeconds = flips.map(m => Number(m[3]))
  const [fadeSeconds] = one(overlay, /tween_property\(janken_overlay, "modulate:a", 0.0, ([\d.]+)\)/, 'fade').map(Number)
  const resultStartsSeconds = rounded(slideSeconds.reduce((a, b) => a + b, 0) +
    flipSeconds.reduce((a, b) => a + b, 0) + pauseSeconds.slice(0, 3).reduce((a, b) => a + b, 0))
  const fadeStartsSeconds = rounded(resultStartsSeconds + pauseSeconds[3])
  const [resultPopSeconds] = one(pop, /tween_property\(overlay_result_image, "scale", Vector2.ONE, ([\d.]+)\)/, 'result pop').map(Number)
  const [resultAlphaSeconds] = one(pop, /tween_property\(overlay_result_image, "modulate:a", 1.0, ([\d.]+)\)/, 'result alpha').map(Number)
  assert.equal((overlay.match(/set_trans\(Tween.TRANS_BACK\).set_ease\(Tween.EASE_OUT\)/g) ?? []).length, 2)
  assert.match(pop, /set_trans\(Tween.TRANS_BACK\).set_ease\(Tween.EASE_OUT\)/)
  const [dimAlpha] = one(node(scene, 'DimBG'), /color = Color\(0.0, 0.0, 0.0, ([\d.]+)\)/, 'dim alpha').map(Number)
  const resultAnchors = ['left', 'top', 'right', 'bottom'].map(edge =>
    Number(one(node(scene, 'ResultImage'), new RegExp(`anchor_${edge} = ([\\d.]+)`), 'result anchors')[0]))
  const [cardBack] = one(body(base, 'get_card_back'), /return "(res:\/\/[^"\n]+)"/, 'card back')
  const resultTextures = Object.fromEntries(['win', 'lose', 'draw'].map(result => [result,
    one(source, new RegExp(`"${result}": preload\\("(res:\\/\\/[^"\\n]+)"\\)`), 'result texture')[0]]))
  return { maxHeight, heightRatio, slideSeconds, flipSeconds, pauseSeconds, fadeSeconds,
    resultPopSeconds, resultAlphaSeconds, resultStartsSeconds, fadeStartsSeconds,
    totalSeconds: rounded(fadeStartsSeconds + fadeSeconds), dimAlpha, resultAnchors, cardBack, resultTextures }
}
