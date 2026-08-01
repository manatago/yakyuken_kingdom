# SESSION_BRIEF

> This file overrides prior conversation context for the current task. Include confirmed, adopted specifications only. Do not include proposals under consideration, rejected ideas, or superseded history.

## Work Mode

Convergence

## Purpose

Commit the AgentSkills kit deployment into this repository and verify the `::publish` flow end to end (commit -> push -> draft PR) on branch `fix/test_tagomori`.

## Confirmed Specification

- `AGENTS.md` and `CLAUDE.md` each carry an AgentSkills rules block delimited by `BEGIN` / `END` markers that point at `.agentskills/rules/`.
- `AGENT_MODELS.md` and `SESSION_BRIEF.md` are tracked so other machines and collaborators inherit the same workflow configuration.
- `.agentskills` is an absolute symlink to a machine-local `AgentSkills/common` checkout and must stay untracked; each machine recreates it with `common/setup/deploy.sh`.
- `test.txt` is the throwaway payload used to confirm that `::publish` stages, commits, pushes, and opens a draft PR.

## Current Problem

The kit was deployed to the working tree but never committed, and the Claude-side deployment (`scripts/deploy-skills.sh`, which symlinks skills and sub-agents into `~/.claude/`) had not been run, so the workflow was only half installed. `.agentskills` also appeared as an untracked path that would break on other machines if committed.

## Targets

- `AGENTS.md` — AgentSkills rules block
- `CLAUDE.md` — AgentSkills rules block
- `AGENT_MODELS.md` — new, model/threshold configuration
- `SESSION_BRIEF.md` — new, this brief
- `.gitignore` — ignore the `.agentskills` symlink
- `test.txt` — publish-flow smoke payload

## Non-Targets

- `godot/` under all paths (game code, scenes, tests, assets)
- Git LFS configuration (`.gitattributes`, `.lfsconfig`)
- `.kiro/` specifications and steering
- The `AgentSkills` repository itself
- `~/.claude/` deployed symlinks (machine-local, outside this repository)

## Prohibitions

- Do not change test expectations for implementation convenience.
- Do not perform unrelated refactoring.
- Do not modify non-target files without updating this brief and obtaining approval.
- Do not merge the draft PR or mark it ready for review.

## Verification

- `git check-ignore -v .agentskills` reports the `.gitignore` rule, and `git status --short` no longer lists `.agentskills`.
- `git diff --cached --stat` lists exactly the six target paths and nothing else.
- `bash .agentskills/gates/pre-commit-gate.sh` reports a final `PASS`.
- Godot tests are not required: no file under `godot/` changes, so the CLAUDE.md test rule (Main.gd / BattleScene.gd / StoryScene.gd / chapters / EncounterDatabase.gd) does not trigger.
- `gh pr view` shows a draft PR whose base is `main` and head is `fix/test_tagomori`.
