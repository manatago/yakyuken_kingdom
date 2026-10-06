import thugEncounter from './assets/random-battle/thug_01/001_encounter.png?url'
import thugWin from './assets/random-battle/thug_01/002_farewell_win.png?url'
import thugLose from './assets/random-battle/thug_01/003_farewell_lose.png?url'
import merchant1Encounter from './assets/random-battle/merchant_01/001_encounter.png?url'
import merchant1Win from './assets/random-battle/merchant_01/002_farewell_win.png?url'
import merchant1Lose from './assets/random-battle/merchant_01/003_farewell_lose.png?url'
import merchant2Encounter from './assets/random-battle/merchant_02/001_encounter.png?url'
import merchant2Win from './assets/random-battle/merchant_02/002_farewell_win.png?url'
import merchant2Lose from './assets/random-battle/merchant_02/003_farewell_lose.png?url'
import sailorEncounter from './assets/random-battle/sailor_01/001_encounter.png?url'
import sailorWin from './assets/random-battle/sailor_01/002_farewell_win.png?url'
import sailorLose from './assets/random-battle/sailor_01/003_farewell_lose.png?url'
import adventurer from './assets/random-battle/adventurer_a/adventurer_a_nude_001.png?url'

export type RandomPortraitPhase = 'encounter' | 'battle' | 'farewell_win' | 'farewell_lose'
type RandomPortraits = Record<RandomPortraitPhase, string>

const thug: RandomPortraits = { encounter: thugEncounter, battle: thugEncounter, farewell_win: thugWin, farewell_lose: thugLose }
const drunk: RandomPortraits = { encounter: adventurer, battle: adventurer, farewell_win: adventurer, farewell_lose: adventurer }

export const randomBattlePortraits: Readonly<Record<string, RandomPortraits>> = {
  thug_01: thug,
  adv_a_01: thug,
  drunk_01: drunk,
  merchant_01: { encounter: merchant1Encounter, battle: merchant1Encounter, farewell_win: merchant1Win, farewell_lose: merchant1Lose },
  merchant_02: { encounter: merchant2Encounter, battle: merchant2Encounter, farewell_win: merchant2Win, farewell_lose: merchant2Lose },
  sailor_01: { encounter: sailorEncounter, battle: sailorEncounter, farewell_win: sailorWin, farewell_lose: sailorLose },
  bandit_01: drunk,
}
