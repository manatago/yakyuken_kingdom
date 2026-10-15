import source from '../../content/stories/godot-visual-style.json'

const { darken, desaturate, weights } = source.automatic_background_filter
// Godot's shader uses NTSC RGB weights, not CSS grayscale's different weights.
export const originalBackgroundColorMatrix = Array.from({ length: 3 }, (_, row) => [
  ...weights.map((weight, column) => (1 - darken) * (desaturate * weight + (row === column ? 1 - desaturate : 0))),
  0, 0
]).flat().concat([0, 0, 0, 1, 0]).join(' ')
