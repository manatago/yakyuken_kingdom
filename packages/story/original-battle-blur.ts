import source from '../../content/stories/godot-battle-highlight.json'

/** Translate the captured Godot nine-tap shader, not a Gaussian approximation. */
export const originalBattleBlurFragment = 'precision highp float;\nuniform sampler2D u_texture;\nuniform vec2 TEXTURE_PIXEL_SIZE;\nvarying vec2 UV;\n' +
  source.blur.shader.replace('shader_type canvas_item;', '').replace(/uniform float blur_amount[^;]*;/,
    `const float blur_amount = ${source.blur.amount.toFixed(1)};`).replace('void fragment()', 'void main()')
    .replaceAll('texture(TEXTURE,', 'texture2D(u_texture,').replace('COLOR =', 'gl_FragColor =')
