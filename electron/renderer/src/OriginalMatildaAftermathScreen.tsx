import { useMemo, useRef, useState } from 'react'
import type { SaveData } from '../../../packages/domain/save'
import { checkpointOriginalMatildaAftermath, chooseOriginalMatildaAftermath,
  originalMatildaAftermathInitialFlags, originalMatildaAftermathIncomingScene } from '../../../packages/story/original-matilda-aftermath-save'
import { originalMatildaFlowChoices } from '../../../packages/story/original-matilda-flow'
import source from '../../../content/stories/godot-main-flow.json'
import { OriginalStoryScreen } from './OriginalStoryScreen'

export function OriginalMatildaAftermathScreen({ save, onSave, onExit }: {
  save: SaveData; onSave: (save: SaveData) => Promise<void>; onExit: () => void
}) {
  const latest = useRef({ save, onSave })
  latest.current = { save, onSave }
  const pending = useRef(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const ledger = save.progress.original_matilda_aftermath!
  const incoming = useMemo(() => originalMatildaAftermathIncomingScene(save), [ledger.actions, ledger.battle, save.progress.original_story_origin])
  const choosing = ledger.flow.phase.endsWith('choice')
  const screen = source.result_screens.find(screen => screen.result === ledger.flow.result)
  async function write(update: (current: SaveData) => SaveData) {
    if (pending.current) return
    pending.current = true; setBusy(true)
    try { await latest.current.onSave(update(latest.current.save)) }
    catch (cause) { setError(cause instanceof Error ? cause.message : String(cause)); throw cause }
    finally { pending.current = false; setBusy(false) }
  }
  return <>
    <OriginalStoryScreen key={`${ledger.flow.phase}:${ledger.actions.length}`}
      sequenceId={ledger.flow.sequenceId} cursor={ledger.cursor} completed={choosing} player={save.player}
      incomingScene={incoming}
      initialFlags={Object.fromEntries(originalMatildaAftermathInitialFlags(ledger).map(flag => [flag, true]))}
      onExit={onExit}
      onCheckpoint={choosing ? undefined : state => write(current => checkpointOriginalMatildaAftermath(current, state.cursor))}
      onComplete={choosing ? undefined : state => write(current => checkpointOriginalMatildaAftermath(current, state.cursor, true))}
      ending={choosing ? <section data-testid="original-matilda-choices">
        {ledger.flow.phase === 'aftermath-choice' && <><h2>{screen?.title}</h2><p>{screen?.message}</p></>}
        {originalMatildaFlowChoices(ledger.flow).map(button => <button key={button.choice} disabled={busy || Boolean(error)}
          onClick={() => { void write(current => chooseOriginalMatildaAftermath(current,
            button.choice as 'retry' | 'home' | 'next' | 'title')).catch(() => {}) }}>{button.label}</button>)}
      </section> : undefined} />
    {error && <aside role="alert" className="original-suspension">{error}</aside>}
  </>
}
