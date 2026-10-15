import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'

export function extractOriginalVisualStyle(source) {
  const start = source.indexOf('func _auto_bg_filter(enable: bool):')
  assert.ok(start >= 0, 'Missing original automatic background filter')
  const end = source.indexOf('\nvar _terminal_', start)
  assert.ok(end > start, 'Missing original filter boundary')
  const body = source.slice(start, end)
  const darken = Number(body.match(/uniform float darken[^;]*= ([\d.]+);/)?.[1])
  const desaturate = Number(body.match(/uniform float desaturate[^;]*= ([\d.]+);/)?.[1])
  const weights = body.match(/dot\(tex\.rgb, vec3\(([\d.]+), ([\d.]+), ([\d.]+)\)\)/)?.slice(1).map(Number)
  assert.ok(Number.isFinite(darken) && darken >= 0 && darken <= 1 &&
    Number.isFinite(desaturate) && desaturate >= 0 && desaturate <= 1 && weights?.length === 3, 'Unsupported original filter values')
  assert.ok(body.includes('mix(tex.rgb, vec3(gray), desaturate)') && body.includes('desat * (1.0 - darken)') &&
    body.includes('COLOR = vec4(darkened, tex.a)'), 'Unsupported original filter formula')
  return { format: 'godot-visual-style', version: 1,
    source_hash: createHash('sha256').update(source).digest('hex'), automatic_background_filter: { darken, desaturate, weights } }
}
