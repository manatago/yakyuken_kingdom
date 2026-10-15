import source from '../../content/stories/godot-showdown.json'
import type { Card } from '../domain/card'

export const originalShowdownSource = source

export function originalShowdownGeometry(viewportWidth: number, viewportHeight: number) {
  const height = Math.min(source.maxHeight, viewportHeight * source.heightRatio)
  const width = height * 2 / 3
  return { width, height, y: (viewportHeight - height) / 2 - 80,
    playerStartX: -width - 50, playerEndX: viewportWidth / 2 - width - 30,
    opponentStartX: viewportWidth + 50, opponentEndX: viewportWidth / 2 + 30 }
}

export function originalShowdownTimeline() {
  const ms = (seconds: number) => Math.round(seconds * 1000)
  const opponentSlide = [0, ms(source.slideSeconds[0])]
  const playerSlide = [opponentSlide[1] + ms(source.pauseSeconds[0]), 0]
  playerSlide[1] = playerSlide[0] + ms(source.slideSeconds[1])
  const playerFlip = [playerSlide[1] + ms(source.pauseSeconds[1]), 0, 0]
  playerFlip[1] = playerFlip[0] + ms(source.flipSeconds[0])
  playerFlip[2] = playerFlip[1] + ms(source.flipSeconds[1])
  const opponentFlip = [playerFlip[2] + ms(source.pauseSeconds[2]), 0, 0]
  opponentFlip[1] = opponentFlip[0] + ms(source.flipSeconds[2])
  opponentFlip[2] = opponentFlip[1] + ms(source.flipSeconds[3])
  return { opponentSlide, playerSlide, playerFlip, opponentFlip,
    resultPop: [ms(source.resultStartsSeconds), ms(source.resultStartsSeconds + source.resultPopSeconds)],
    fade: [ms(source.fadeStartsSeconds), ms(source.totalSeconds)], duration: ms(source.totalSeconds), backOut: source.back_out }
}

export function originalShowdownGradeReason(player: Card, opponent: Card) {
  if (player.hand !== opponent.hand) return ''
  return (source.grade_reasons as Record<string, string>)[`${player.hand}:${player.grade}:${opponent.grade}`] ?? ''
}

export function originalShowdownCardFrames(side: 'player' | 'opponent', front: boolean,
  viewportWidth: number, viewportHeight: number): Keyframe[] {
  const geometry = originalShowdownGeometry(viewportWidth, viewportHeight)
  const timeline = originalShowdownTimeline()
  const slide = side === 'player' ? timeline.playerSlide : timeline.opponentSlide
  const flip = side === 'player' ? timeline.playerFlip : timeline.opponentFlip
  const startX = side === 'player' ? geometry.playerStartX : geometry.opponentStartX
  const endX = side === 'player' ? geometry.playerEndX : geometry.opponentEndX
  const frame = (time: number, x: number, scale: number, opacity: number): Keyframe => ({
    offset: time / timeline.duration, transform: `translateX(${x}px) scaleX(${scale})`, opacity })
  if (front) return [frame(0, endX, 0, 0), frame(flip[1], endX, 0, 0),
    frame(flip[1], endX, 0, 1), frame(flip[2], endX, 1, 1), frame(timeline.duration, endX, 1, 1)]
  const frames = [frame(0, startX, 1, side === 'opponent' ? 1 : 0)]
  if (side === 'player') frames.push(frame(slide[0], startX, 1, 0), frame(slide[0], startX, 1, 1))
  timeline.backOut.forEach((progress, index) => {
    frames.push(frame(slide[0] + (slide[1] - slide[0]) * index / 60,
      index === 60 ? endX : startX + (endX - startX) * progress, 1, 1))
  })
  frames.push(frame(flip[0], endX, 1, 1), frame(flip[1], endX, 0, 1),
    frame(flip[1], endX, 0, 0), frame(timeline.duration, endX, 0, 0))
  return frames
}
