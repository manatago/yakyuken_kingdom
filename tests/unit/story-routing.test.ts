import assert from 'node:assert/strict'
import test from 'node:test'
import prologue from '../../content/stories/prologue.json'
import matildaTutorial from '../../content/stories/matilda-tutorial.json'
import matildaNormal from '../../content/stories/matilda-normal.json'
import subevent1 from '../../content/stories/subevent1-jin.json'
import subevent2 from '../../content/stories/subevent2.json'
import subevent3 from '../../content/stories/subevent3.json'
import subevent4 from '../../content/stories/subevent4.json'
import stage2 from '../../content/stories/stage2.json'
import stage3 from '../../content/stories/stage3.json'
import stage4 from '../../content/stories/stage4.json'
import stage5 from '../../content/stories/stage5.json'
import stage6 from '../../content/stories/stage6.json'
import stage7 from '../../content/stories/stage7.json'
import { isPrologueCheckpoint } from '../../packages/story/prologue'
import { fixedContent } from '../../packages/battle/fixed'
import { SUBEVENT1_JIN_STORY_ID, isSubevent1JinStoryCheckpoint } from '../../packages/battle/jin'
import { stage2StoryForCheckpoint } from '../../packages/battle/stage2'
import { subevent2StoryForCheckpoint } from '../../packages/battle/subevent2'
import { subevent3StoryForCheckpoint } from '../../packages/battle/subevent3'
import { subevent4StoryForCheckpoint } from '../../packages/battle/subevent4'
import { stage3StoryForCheckpoint } from '../../packages/battle/stage3'
import { stage4StoryForCheckpoint } from '../../packages/battle/stage4'
import { stage5StoryForCheckpoint } from '../../packages/battle/stage5'
import { stage6StoryForCheckpoint } from '../../packages/battle/stage6'
import { stage7StoryForCheckpoint } from '../../packages/battle/stage7'
import { startStory } from '../../packages/story/runner'
import type { ContentPack } from '../../packages/content/schema'

type RoutedStoryPack = ContentPack

function asContentPack(content: unknown): ContentPack {
  return content as ContentPack
}

const routes: readonly { label: string; content: RoutedStoryPack; resolve: (checkpoint: string) => string | undefined }[] = [
  { label: 'Prologue', content: asContentPack(prologue), resolve: (checkpoint) =>
    isPrologueCheckpoint(checkpoint) ? prologue.stories.find((story) => story.steps.some((step) => step.id === checkpoint))?.id : undefined },
  { label: 'Matilda tutorial', content: asContentPack(matildaTutorial), resolve: (checkpoint) =>
    matildaTutorial.stories.find((story) => story.steps.some((step) => step.id === checkpoint))?.id },
  { label: 'Matilda normal battle', content: asContentPack(matildaNormal), resolve: (checkpoint) =>
    fixedContent.stories.find((story) => story.steps.some((step) => step.id === checkpoint))?.id },
  { label: 'Subevent 1', content: asContentPack(subevent1), resolve: (checkpoint) =>
    isSubevent1JinStoryCheckpoint(checkpoint) ? SUBEVENT1_JIN_STORY_ID : undefined },
  { label: 'Subevent 2', content: asContentPack(subevent2), resolve: subevent2StoryForCheckpoint },
  { label: 'Subevent 3', content: asContentPack(subevent3), resolve: subevent3StoryForCheckpoint },
  { label: 'Subevent 4', content: asContentPack(subevent4), resolve: subevent4StoryForCheckpoint },
  { label: 'Stage 2', content: asContentPack(stage2), resolve: stage2StoryForCheckpoint },
  { label: 'Stage 3', content: asContentPack(stage3), resolve: stage3StoryForCheckpoint },
  { label: 'Stage 4', content: asContentPack(stage4), resolve: stage4StoryForCheckpoint },
  { label: 'Stage 5', content: asContentPack(stage5), resolve: stage5StoryForCheckpoint },
  { label: 'Stage 6', content: asContentPack(stage6), resolve: stage6StoryForCheckpoint },
  { label: 'Stage 7', content: asContentPack(stage7), resolve: stage7StoryForCheckpoint }
]

for (const route of routes) {
  test(`${route.label} resumes every saved checkpoint and has no orphan scene nodes`, () => {
    const ids = new Set<string>()
    const allStepIds = new Set(route.content.stories.flatMap((story) => story.steps.map((step) => step.id)))
    for (const story of route.content.stories) {
      const stepsById = new Map(story.steps.map((step) => [step.id, step]))
      const reachable = new Set<string>()
      const pending = [story.start_id]
      while (pending.length) {
        const id = pending.pop()!
        if (reachable.has(id)) continue
        const step = stepsById.get(id)
        if (!step) {
          assert.ok(allStepIds.has(id), `cross-story handoff points to missing step ${id} in ${story.id}`)
          continue
        }
        reachable.add(id)
        if (step.kind === 'line' || step.kind === 'background' || step.kind === 'show_portrait' ||
            step.kind === 'hide_portrait' || step.kind === 'battle') pending.push(step.next_id)
        else if (step.kind === 'goto') pending.push(step.target_id)
        else if (step.kind === 'choice') pending.push(...step.options.map((option) => option.next_id))
      }
      for (const step of story.steps.filter(({ kind }) => kind === 'line' || kind === 'battle' || kind === 'end')) {
        assert.ok(!ids.has(step.id), `duplicate checkpoint ${step.id}`)
        ids.add(step.id)
        assert.equal(route.resolve(step.id), story.id, `checkpoint ${step.id}`)
        const variables = Object.fromEntries(story.steps.flatMap((candidate) => candidate.kind === 'line'
          ? [...candidate.text.matchAll(/\{\{([A-Za-z][A-Za-z0-9_]*)\}\}/g)].map((match) => [match[1], 'test'])
          : []))
        assert.equal(startStory(route.content, story.id, step.id, variables).step.id, step.id,
          `story runner cannot resume at ${step.id}`)
      }
      for (const step of story.steps) {
        if (reachable.has(step.id)) continue
        assert.equal(step.kind, 'end', `orphan non-terminal ${step.id} in ${story.id}`)
        assert.ok(route.label === 'Subevent 1' && ['subevent1.jin.end', 'subevent1.marco.end', 'subevent1.gald.end'].includes(step.id),
          `unexpected orphan terminal ${step.id} in ${story.id}`)
      }
    }
    assert.ok(ids.size > 0)
  })
}
