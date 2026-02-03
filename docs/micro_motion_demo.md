# Godot 4 Micro Motion Demo Integration Guide

このドキュメントでは、紙芝居型ストーリーに「静止画を活かした微細な動き」を組み込むための手法と、DSL/StoryChapter から簡単に呼び出すための仕組み、さらにデモチャプターと本番チャプターの切り替え方法をまとめます。

## 1. 5種類の表現手法
| 手法 | 主要ノード/機能 | 実装ポイント |
| --- | --- | --- |
| プロパティ・アニメーション（目パチ/口パク） | `Sprite2D` + `AnimationPlayer` | `texture` をキーフレームで切り替える。目の瞬きや発話タイミングの短いループを用意。 |
| 階層構造トランスフォーム（呼吸/浮遊） | `Node2D` 階層 + `AnimationPlayer` | 胴体→頭の親子構造。親の `scale`/`position` を 1.0〜1.02 程度でサイン波アニメ。 |
| デフォーメーション（2Dボーン） | `Polygon2D`, `Skeleton2D`, `Bone2D` | メッシュ化した立ち絵をボーン回転で歪ませ、腕や首に動きを足す。 |
| 頂点シェーダー（風揺れ） | `ShaderMaterial` (CanvasItem) | `VERTEX` を `sin(TIME)` で揺らし、髪や衣装が自動で波打つ表現。 |
| Tween（登場/退場） | `create_tween()` | `TRANS_QUART`, `EASE_OUT` などのイージングでスライドイン/アウトやフェードを制御。 |

## 2. 推奨ノード構成
```
StoryCharacterRoot (Node2D)
├── BreathingRig (Node2D)
│   ├── AnimationPlayer   # 呼吸、親子スケール操作
│   └── SpriteLayer (Node2D)
│       ├── BodySprite (Sprite2D)
│       └── HeadRig (Node2D)
│           └── HeadSprite (Sprite2D + AnimationPlayer)  # 目パチ/口パク
├── MeshRig (Polygon2D + Skeleton2D + Bone2D)            # 必要時のみ
├── WindOverlay (Sprite2D/Polygon2D + ShaderMaterial)
└── TweenAnchor (Node)                                   # create_tween() 呼び出し用
```
`StoryCharacterRoot.gd` に `play_breathing()`, `play_blink()`, `slide_in_from()`, `apply_wind_shader()` などの API をまとめ、DSL から呼びやすいようにする。

## 3. DSL コマンドとの連携
1. `StoryMicroMotionCommand.gd`（新規）を `StoryCommand` から派生させ、`execute()` で `StoryScene` からキャラクターノードを取得して API を呼ぶ。
2. `StoryDsl.gd` に `func micro_motion(id, params := {}):` を用意し、`StoryCharacterHandle` の糖衣関数で `hero.breathe({...})` などを提供する。
3. `PrologueChapter.gd` などの DSL スクリプトでは、従来の `appear/band` と同様に `hero.breathe({"amplitude":0.015})`, `hero.slide_in({"start":Vector2(-800,-20)})` などの新メソッドを呼ぶだけで微細アニメが発動する。

### コマンド例
```gdscript
# res://resources/story/commands/StoryMicroMotionCommand.gd
extends StoryCommand
class_name StoryMicroMotionCommand

var character_id: String
var params := {}

func _init(_character_id: String, _params := {}):
    character_id = _character_id
    params = _params

func execute(scene: StoryScene) -> void:
    var node = scene.get_character_node(character_id)
    if node == null:
        return
    match params.get("type", "breath"):
        "breath":
            node.play_breathing(params.get("amplitude", 0.02), params.get("speed", 1.5))
        "blink":
            node.play_blink(params.get("clip", "blink_loop"))
        "slide_in":
            node.slide_in_from(params.get("start", Vector2(-600, node.position.y)), params.get("duration", 0.9))
        "wind":
            node.apply_wind_shader(params.get("shader_path"))
```

```gdscript
# StoryCharacterHandle.gd
func breathe(params := {}):
    _builder.add_command(StoryMicroMotionCommand.new(_id, params.merged({"type": "breath"})))

func slide_in(params := {}):
    _builder.add_command(StoryMicroMotionCommand.new(_id, params.merged({"type": "slide_in"})))

func blink(params := {}):
    _builder.add_command(StoryMicroMotionCommand.new(_id, params.merged({"type": "blink"})))
```

## 4. デモチャプターと本番チャプターの切り替え
### エクスポート変数で切り替える方法
1. `StoryScript.gd`（`DefaultStory.gd`）に `@export var use_demo_sequence := false` を追加。
2. `get_chapters()` 内で `if use_demo_sequence: return [DemoMicroMotionChapter.new()] else: return [PrologueChapter.new(), ...]` のように分岐する。
3. `Main.tscn` の `Main.gd` に `@export var demo_mode := false` を追加し、`_create_story_scene()` で `story_script.use_demo_sequence = demo_mode` をセット。
4. Godot Editor のインスペクタで `demo_mode` を切り替えるだけで、デモか本番かを選択できる。

### コメントアウトで切り替える簡易方法
`StoryScript.gd` の `get_chapters()` 冒頭に以下のようなガードを挟む：
```gdscript
func get_chapters() -> Array:
    # DEMO ONLY: true にするとデモチャプターだけ再生
    if false:
        return [DemoMicroMotionChapter.new()]
    return [PrologueChapter.new(), Stage1Chapter.new()]
```
`false` を `true` に書き換えるだけで一時的にデモモードに切り替わる。

### enum 選択で柔軟に
`Main.gd` に `@export_enum("demo", "prologue", "stage1") var story_mode := "prologue"` を定義し、`match story_mode:` で `story_script.force_chapter("demo")` などを呼び分ける実装も可能。

## 5. 動作確認フロー
1. Godot で `Main.tscn` を開く。
2. インスペクタ上の `demo_mode`（または `story_mode`）で再生したいシナリオを選択。
3. `StoryCharacterRoot` の API を呼ぶ DSL を `PrologueChapter.gd` や `DemoMicroMotionChapter.gd` に記述。
4. `F5` 実行 → `StoryScene` が DSL コマンドを順に解釈し、微細アニメが適用される。

この構成に従うことで、1) Godot の標準機能で 5 種の微細アニメを組み合わせられ、2) DSL/StoryChapter による演出呼び出しを統一し、3) コメントアウトや export 変数でデモ ⇔ 本番の切り替えも容易になります。
