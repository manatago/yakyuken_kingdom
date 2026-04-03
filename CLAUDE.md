# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Yakyuken Kingdom (じゃんけんキングダム) - A 3D card battle rock-paper-scissors game built with Godot 4.5. Features a visual novel-style story system with character dialogue, animations, and staged battles.

## Common Commands

### Docker環境（推奨）
```bash
cd docker

# 初回ビルド
./run.sh build

# プロジェクト検証（エラーチェック）
./run.sh validate

# テスト実行
./run.sh test

# 任意のGodotコマンド
./run.sh godot --version
```

### ローカル実行（Godotインストール済みの場合）
```bash
# Godot Editorで開く
godot4 --path godot

# ゲーム実行
godot4 --path godot --run

# テスト実行
godot4 --headless --path godot --run TestRunner
```

## Architecture

### Core Game Loop (`godot/scripts/Main.gd`)
The main controller manages three game states:
- **INTRO**: Story sequences play via StoryScene
- **BATTLE**: Card selection and turn-based combat
- **RESULT**: Win/lose dialogue sequences

Key flow: `scenario()` → `_play_stage()` → RPG battle loop with `turn_finished` signal

### 3D Viewport System (`godot/scripts/Table3D.gd`)
Renders 2D game UI (`Main.gd`) onto a 3D plane via SubViewport texture. Manages HUD overlay and camera positioning.

### Story System
The story engine uses a command pattern with a DSL for scripting:

**Key Components:**
- `StoryScene.gd` - Runtime for playing sequences, manages character positioning and dialogue bubbles
- `StoryDsl.gd` - Fluent API for building story sequences
- `StorySequence.gd` - Container for story commands
- `StoryScript.gd` / `DefaultStory.gd` - Story definition with character cast

**Chapter Pattern:**
Chapters extend `StoryChapterBase` and implement `register_sequences()`:
```gdscript
# Example chapter structure
func _build_chapter(dsl: StoryDsl) -> StorySequence:
    return dsl.build("sequence_id", func(b):
        var hero := b.character("main")
        b.background("res://assets/backgrounds/bg.png")
        hero.say("Dialogue text")
    )
```

**DSL Reference:**
- Character methods: `say()`, `appear()`, `leave()`, `show()`, `band()`
- Builder methods: `background()`, `pause()`, `show_band()`, `hide_band()`, `narrator_band()`
- See `godot/resources/story/dsl/DSLMethodGuide.md` for full API

### Battle Chapter System (`godot/resources/battle/CardBattleChapterBase.gd`)
Configures battle parameters: opponent data, card textures, win rates, and custom text.

### Test Framework
Custom GDScript test harness in `godot/tests/`:
- `TestSuite.gd` - Base class with `before_each()`, `after_each()`, `assert_*` methods
- `TestRunner.gd` - Discovers and runs all suites
- Tests return `true`/`false` for pass/fail

## アセット管理

画像・動画はgit管理外。プロジェクトルートのZIPファイルで管理。

**最新アセット**: プロジェクトルートの `assets_*.zip`（最新のものを使用）

### 別PCでのセットアップ
```bash
# 1. Pull
git pull origin main

# 2. ZIPファイルをプロジェクトルートにコピー（手動）

# 3. 展開
# Mac/Linux:
./scripts/restore-assets.sh

# Windows PowerShell:
.\scripts\restore-assets.ps1
```

### アセットのアーカイブ（画像追加・変更後）
```bash
# godot/ 内で実行
cd godot
python3 -c "
import zipfile, os, subprocess
rev = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD']).decode().strip()
from datetime import datetime
date = datetime.now().strftime('%Y%m%d')
zip_name = f'assets_{rev}_{date}.zip'
zip_path = os.path.join('..', zip_name)
count = 0
with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk('assets'):
        for f in sorted(files):
            if f.endswith(('.png', '.jpg', '.jpeg', '.webp', '.ogv')):
                filepath = os.path.join(root, f)
                zf.write(filepath, filepath)
                count += 1
print(f'{count} files -> {zip_name}')
"
```

## Key Directories

- `docker/` - Docker環境（Godot 4.4.1 ヘッドレス）
- `godot/scripts/` - Core game scripts (Main, Table3D, StoryScene)
- `godot/resources/story/` - Story system (DSL, commands, chapters)
- `godot/resources/battle/` - Battle configuration
- `godot/assets/` - Images (characters, backgrounds, cards, UI)
- `godot/tests/` - Test suites

## Spec-Driven Development

This project uses Kiro-style specification workflow:

1. **Steering** (`.kiro/steering/`) - Project-wide rules and context
2. **Specs** (`.kiro/specs/`) - Feature specifications with requirements, design, and tasks

**Workflow Commands:**
- `/kiro:spec-init "description"` - Start new feature spec
- `/kiro:spec-requirements {feature}` - Generate requirements
- `/kiro:spec-design {feature}` - Create technical design
- `/kiro:spec-tasks {feature}` - Generate implementation tasks
- `/kiro:spec-impl {feature}` - Execute implementation
- `/kiro:spec-status {feature}` - Check progress

## Language Notes

- Code comments and variable names: English
- User-facing text and markdown docs in specs: Japanese
- Story dialogue content: Japanese
