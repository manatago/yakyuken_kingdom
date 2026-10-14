interface Placement { x: number; y: number; scale: number }

/** Sample Godot SINE/CUBIC curves; opacity uses its separate linear tween. */
export function originalMotionFrames(effect: string, leaving: boolean, direction: string,
  distance: number, placement: Placement, width: number, height: number) {
  const resizing = leaving ? effect.includes('shrink') : effect.includes('grow')
  const dx = direction === 'left' ? -distance : direction === 'right' ? distance : 0
  const dy = ['up', 'top'].includes(direction) ? -distance : ['down', 'bottom'].includes(direction) ? distance : 0
  return Array.from({ length: 61 }, (_, index) => {
    const offset = index / 60
    const progress = index === 0 ? 0 : index === 60 ? 1 : resizing ? leaving ? offset ** 3 : 1 - (1 - offset) ** 3
      : leaving ? 1 - Math.cos(offset * Math.PI / 2) : Math.sin(offset * Math.PI / 2)
    const amount = leaving ? progress : 1 - progress
    const frame: Record<string, string | number> = { offset,
      opacity: effect.includes('fade') ? leaving ? 1 - offset : offset : 1 }
    if (resizing) {
      const scale = leaving ? placement.scale * (1 - progress) : placement.scale * progress
      frame.transform = `scale(${scale})`
      frame.left = `${placement.x + width * placement.scale * .5 * amount}px`
      frame.top = `${placement.y + height * placement.scale * .5 * amount}px`
    } else {
      frame.translate = effect.includes('slide') ? `${dx * amount}px ${dy * amount}px` : '0px 0px'
    }
    // Trigonometric floating-point noise must not leave a residual displacement.
    if (!resizing && index === 60 && !leaving) frame.translate = '0px 0px'
    return frame
  })
}
