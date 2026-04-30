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

### Macでのローカル実行（Godot.app）
```bash
# ゲーム実行
/Applications/Godot.app/Contents/MacOS/Godot --path godot --run

# テスト実行（推奨ランナー: TestRunnerMain.gd）
/Applications/Godot.app/Contents/MacOS/Godot --path godot --headless --script res://tests/TestRunnerMain.gd
```

## テスト実行ルール（重要）

以下の変更を行った後は **必ずテストを実行して結果を確認すること**:

- `godot/game/Main.gd` の編集
- `godot/game/BattleScene.gd` の編集
- `godot/game/StoryScene.gd` の編集
- `godot/battle/chapters/*.gd` の編集
- `godot/story/chapters/*.gd` の編集
- `godot/encounter/EncounterDatabase.gd` の編集

### 実行コマンド（Mac）
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path godot --headless --script res://tests/TestRunnerMain.gd 2>&1 | tail -60
```

### チェック項目
- E2EBattle スイートが全てパスすること（特に `all_chapters_load`, `all_portrait_paths_exist`, `main_battle_requested_connected`）
- 新規パースエラー（`SCRIPT ERROR:`）が発生していないこと
- 既存の失敗テスト（StorySceneの `_ready` / `apply_band_command` 参照）は既知の未対応項目なので、これらが増えていなければOK

テストが落ちた場合は、コミットや次の作業に進む前に修正すること。

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

画像・動画は **Git LFS** で管理(セルフホストの rudolfs サーバ on `49.212.195.249:8080`)。
`.gitattributes` に列挙された拡張子(`*.png`, `*.jpg`, `*.mp4` など)は自動で LFS に乗る。
SVG は意図的に対象外(XML 差分を読めるようにするため)。

ZIP ベースの旧ワークフロー(`assets_*.zip` + `scripts/restore-assets.{sh,ps1}`)は
**LFS サーバが使えない時のフォールバック**として並走で残してある。

### 別PCでのセットアップ(LFS メイン)
```bash
# 1. 初回のみ: git-lfs を入れる
#    Mac:    brew install git-lfs
#    Linux:  sudo dnf/apt install git-lfs
#    Win:    https://git-lfs.com/ からインストーラ
git lfs install

# 2. clone(画像/動画も自動で LFS サーバから取得される)
git clone git@github.com:manatago/yakyuken_kingdom.git
# → 初回 LFS アクセス時に Basic Auth が要求される。
#   ユーザー名: satoshi
#   パスワード: 共有された LFS パスワード(VPS の ~/rudolfs/lfs.password.txt)

# 3. 更新時は普通に
git pull origin main           # 差分のみ取得

# 4. 画像/動画の追加・差し替え
#    .gitattributes 該当拡張子なら、何もせず通常の add/commit/push でOK
git add path/to/new_image.png
git commit -m "add image"
git push origin main           # ポインタは GitHub、本体は VPS
```

### ZIP フォールバック(LFS サーバが落ちている/オフライン時)
```bash
# 1. Pull(LFS スキップでポインタだけ取得)
GIT_LFS_SKIP_SMUDGE=1 git pull origin main

# 2. assets_*.zip をプロジェクトルートにコピー(手動)

# 3. 展開
# Mac/Linux:
./scripts/restore-assets.sh
# Windows PowerShell:
.\scripts\restore-assets.ps1
```

### ZIP スナップショットを作る(リリース配布等で必要なら)
```bash
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

### LFS サーバ運用メモ(VPS 側 / satoshi@49.212.195.249)
- 実体: `~/rudolfs/storage/` 配下に OID ベースで保存
- 起動: rootless podman + systemd user unit(`systemctl --user status rudolfs`)
- 認証: nginx Basic Auth(`/etc/nginx/conf.d/lfs.conf` + `/etc/nginx/lfs.htpasswd`)
- 鍵: `~/rudolfs/key.env` の `RUDOLFS_KEY` で at-rest 暗号化

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
