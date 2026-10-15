import assert from 'node:assert/strict'
import { ADVENTURER_TUTORIAL_COMPLETE } from '../../packages/battle/adventurer-tutorial'
import { acceptTownEncounter, enterTown, playRandomBattleRound, randomBattleView, returnToGuildFromTown, settleRandomBattle } from '../../packages/battle/random'
import { parseSave } from '../../packages/domain/save'
import type { SaveData } from '../../packages/domain/save'
import { acknowledgeFixedRound, fixedView, playFixedRound, returnFromFixedBattle, settleFixedBattle } from '../../packages/battle/fixed'

/** Drive a fixed battle to a deterministic loss and follow its configured return route. */
export function loseFixedBattleAndReturn(source: SaveData): SaveData {
  let save = source
  while (!fixedView(save).outcome) {
    const view = fixedView(save)
    const ledger = save.progress.fixed_battle!
    let losingRound: SaveData | undefined
    for (let index = 0; index < ledger.player_deck.length && !losingRound; index++) {
      if (view.usedPlayer.includes(index)) continue
      for (let step = 0; step < 1000; step++) {
        const candidate = playFixedRound(save, index, step / 1000)
        if (fixedView(candidate).last?.result === 'lose') {
          losingRound = candidate
          break
        }
      }
    }
    assert.ok(losingRound, 'a losing player/opponent pairing must exist in the battle')
    save = losingRound!
    if (fixedView(save).outcome) save = settleFixedBattle(save, 0)
    else save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  return returnFromFixedBattle(save)
}

/** Earn real card rewards through the ordinary town battle path until the 9-card deck can be rebuilt. */
export function recoverCardsThroughTown(source: SaveData, victories: number): SaveData {
  let save = source
  if (!save.progress.flags.includes(ADVENTURER_TUTORIAL_COMPLETE)) {
    save = parseSave({ ...save, progress: { ...save.progress, flags: [...save.progress.flags, ADVENTURER_TUTORIAL_COMPLETE] } })
  }
  const handRoll: Record<'rock' | 'scissors' | 'paper', number> = { rock: 0, scissors: 0.5, paper: 0.99 }
  const beats: Record<'rock' | 'scissors' | 'paper', 'rock' | 'scissors' | 'paper'> = {
    rock: 'scissors', scissors: 'paper', paper: 'rock'
  }
  for (let count = 0; count < victories; count++) {
    const deck = save.player.inventory.slice(0, 3)
    assert.equal(deck.length, 3, 'a random battle requires three owned cards')
    const playerCard = deck[0]!
    const opponentHand = beats[playerCard.hand]
    const pending = enterTown(save, 'guild_street', { encounter: 0, opponent: 0,
      cards: Array.from({ length: 3 }, () => ({ hand: handRoll[opponentHand], grade: 0 })) as [
        { hand: number; grade: number }, { hand: number; grade: number }, { hand: number; grade: number }
      ], drop: 0 })
    const battle = acceptTownEncounter(pending, deck)
    const terminal = playRandomBattleRound(battle, 0, 0)
    assert.equal(randomBattleView(terminal).outcome, 'win', 'the test recovery encounter should be winnable')
    save = returnToGuildFromTown(settleRandomBattle(terminal, 0))
  }
  return save
}
