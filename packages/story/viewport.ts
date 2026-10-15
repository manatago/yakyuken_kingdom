export function fitViewport(width: number, height: number) {
  if (!Number.isFinite(width) || !Number.isFinite(height) || width < 0 || height < 0) {
    throw new RangeError('Viewport dimensions must be finite and non-negative')
  }
  const scale = Math.min(width / 1920, height / 1080)
  const fittedWidth = 1920 * scale
  const fittedHeight = 1080 * scale
  return {
    scale, width: fittedWidth, height: fittedHeight,
    left: (width - fittedWidth) / 2, top: (height - fittedHeight) / 2
  }
}
