import assert from 'node:assert/strict'
import test from 'node:test'
import { canStartStage2 } from '../../packages/battle/stage2'
import { canStartStage3 } from '../../packages/battle/stage3'
import { canStartStage4 } from '../../packages/battle/stage4'
import { canStartStage5 } from '../../packages/battle/stage5'
import { canStartStage6 } from '../../packages/battle/stage6'
import { canStartSubevent2 } from '../../packages/battle/subevent2'
import { canStartSubevent3 } from '../../packages/battle/subevent3'
import { canStartSubevent4 } from '../../packages/battle/subevent4'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { GUILD_CHECKPOINT } from '../../packages/guild/routes'
import { acknowledgeTutorial, playTutorialRound, prepareTutorial } from '../../packages/battle/tutorial'

function atGuild(flags: readonly string[], hasDeck: boolean, hasReserve = true): SaveData {
  let source = createInitialGameSave()
  source = prepareTutorial({ ...source, progress: { ...source.progress, checkpoint_id: 'matilda.await-deck' } }, source.player.inventory)
  source = acknowledgeTutorial(playTutorialRound(source, 6, 0))
  source = acknowledgeTutorial(playTutorialRound(source, 0, 0))
  const { prepared_deck: _prepared, ...player } = source.player
  const inventory = [...source.player.inventory, ...(hasReserve
    ? Array.from({ length: 3 }, () => ({ hand: 'rock' as const, grade: 2 as const })) : [])]
  return parseSave({ ...source,
    player: { ...player, inventory, deck: hasDeck ? inventory.slice(0, 9).map((card) => ({ ...card })) : [] },
    progress: { ...source.progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: 'matilda.end',
      random_battles_completed: 3, flags: [...source.progress.flags, ...flags] } })
}

test('fixed nine-card stories stay at Guild until the current deck is complete and owned', () => {
  const cases: readonly { name: string; flags: readonly string[]; requiresReserve: boolean; canStart: (save: SaveData) => boolean }[] = [
    { name: 'Subevent 2', flags: ['sub1_cleared'], requiresReserve: false, canStart: canStartSubevent2 },
    { name: 'Subevent 3', flags: ['sub2_cleared'], requiresReserve: false, canStart: canStartSubevent3 },
    { name: 'Subevent 4', flags: ['sub3_cleared'], requiresReserve: false, canStart: canStartSubevent4 },
    { name: 'Stage 2', flags: ['sub2_cleared'], requiresReserve: true, canStart: canStartStage2 },
    { name: 'Stage 3', flags: ['stage2_complete'], requiresReserve: true, canStart: canStartStage3 },
    { name: 'Stage 4', flags: ['stage3_complete'], requiresReserve: true, canStart: canStartStage4 },
    { name: 'Stage 5', flags: ['stage4_complete'], requiresReserve: true, canStart: canStartStage5 },
    { name: 'Stage 6', flags: ['stage5_complete'], requiresReserve: true, canStart: canStartStage6 }
  ]
  for (const entry of cases) {
    assert.equal(entry.canStart(atGuild(entry.flags, false)), false, `${entry.name} should not start without a nine-card deck`)
    assert.equal(entry.canStart(atGuild(entry.flags, true)), true, `${entry.name} should start with an owned deck and any required reserve`)
    if (entry.requiresReserve) {
      assert.equal(entry.canStart(atGuild(entry.flags, true, false)), false,
        `${entry.name} should retain three cards for its scripted first-battle loss`)
    }
  }
})
