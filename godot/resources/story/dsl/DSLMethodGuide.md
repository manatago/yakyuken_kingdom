# Story DSL Method Guide

このメモは `PrologueChapter._build_prologue()` などの章ビルダー関数内でよく使用する DSL メソッドをまとめたものです。`b` は `StoryDsl.build()` から渡されるビルダープロキシ、`hero` や `matilda` は `b.character("id")` で取得した `StoryCharacterHandle` を表します。

## ビルダープロキシ (`b`) のメソッド

### `character(id: String) -> StoryCharacterHandle`
キャスト ID から `StoryCharacterHandle` を生成します。章内で同じ ID を繰り返し参照するためのエントリポイントです。

```gdscript
var hero := b.character("main")
```

### `set_protagonist(character_id: String)`
主人公 ID を記録し、`b.protagonist_band()` などのデフォルト話者に利用します。章の冒頭で 1 度呼ぶ想定です。

### `background(path: String, fade := 0.0)`
背景テクスチャを切り替えます。第 2 引数はフェード秒（未実装ですが、将来クロスフェードを追加する前提のパラメーター）です。

```gdscript
b.background("res://assets/backgrounds/bg01_university.png", 0.5)
```

### `show_band()` / `hide_band()`
画面下部のバンドを表示／非表示にします。`show_band()` 単体ではテキストは変わりません。

### `narrator_band(text: String, wait_for_input := true, min_duration := 0.0)`
ナレーター話者でバンドを更新します。既定で Enter/クリック待ちになります。`wait_for_input` を `false` にすると自動で次へ進めます。

### `band(text: String, extra := {})`
任意話者 ID でバンドを表示する汎用メソッド。`extra` には `speaker_id`、`portrait`、`side`、`wait_for_input` などを指定できます。キャラクターハンドルの `band()` から内部的に呼び出されます。

### `clear_band_text()`
バンドは残したままテキストと話者名だけを消します。連続した演出の合間に余計な文言を残さないために使います。

### `hide_dialogue()`
現在表示中のフキダシ（左／右）をまとめて非表示にします。`hero.say()` 直後に別フォーマットへ切り替える際などに使用してください。

## キャラクターハンドル (`hero`, `matilda` など) のメソッド

### `say(text: String, extra := {})`
通常のフキダシ台詞を表示します。`extra` には `portrait`, `side`, `offset`, `wait_for_input`, `duration` など `StoryLineCommand` と同じキーを指定できます。

```gdscript
hero.say("ここが噂の研究施設…", {"portrait": "Isekai"})
```

### `band(text: String, extra := {})`
そのキャラクターを話者としたバンドメッセージを表示します。`extra` は `b.band()` と同じで、指定しなければ自動で `speaker_id` と `wait_for_input` を補います。

### `hide_dialogue()`
このキャラクターから呼び出してもビルダープロキシと同じくフキダシを消す処理を発行します。`hero.say()` の直後に `hero.hide_dialogue()` を呼ぶと HUD をバンドへ切り替えやすくなります。

### `show(extra := {})`
セリフなしで立ち絵だけを表示します。`extra` では `portrait`, `side`（`"left"`/`"center"`/`"right"`）, `position_mode`, `position` などを指定できます。`position_mode` は `"offset"`, `"absolute"`, `"normalized"` をサポートします。

### `appear(extra := {})`
`show()` の拡張版で、登場演出や配置を指定します。主なオプション:

- `side`: `"left"` / `"center"` / `"right"`（使用するスロット。省略時は空いている側を自動使用）
- `appear_effect`: `"fade"`（デフォルト） / `"slide"` / `"fade_slide"` / `"grow"` / `"fade_grow"`
- `appear_duration`: 演出にかける秒数（例: `0.35`）
- `appear_from`: スライド元方向（`"left"`, `"right"`, `"top"`, `"bottom"` など）
- `appear_distance`: スライド距離（ピクセル、既定 200）
- `position_mode`: `"offset"`（スロット基準のオフセット） / `"absolute"`（絶対座標） / `"normalized"`（ビューポート比率）
- `position`: `Vector2`。`position_mode` に応じてオフセット量や座標を指定します。

例:

```gdscript
hero.appear({
	"side": "left",
	"appear_effect": "fade_slide",
	"appear_from": "right",
	"appear_duration": 0.45,
	"appear_distance": 250,
	"position_mode": "offset",
	"position": Vector2(0, -20),
	"portrait": "Isekai"
})

hero.appear({
	"side": "center",
	"appear_effect": "fade_grow",
	"appear_duration": 0.5,
	"portrait": "teleport_white_coat"
})
```

### `stay_left()` / `stay_right()` / `set_portrait()`
立ち絵の位置固定と差し替え。`stay_left()` / `stay_right()` は左右を指定位置に保ち、`set_portrait()` は位置はそのままにポートレートだけ差し替えます。

### `leave(extra := {})`
キャラを退場させます。オプションでフェードアウトやスライド方向を指定できます。

- `exit_effect`: `"fade"` / `"slide"` / `"fade_slide"` / `"shrink"` / `"fade_shrink"`
- `exit_duration`: 演出時間（秒）
- `exit_to`: スライド方向（`"left"`, `"right"`, `"top"`, `"bottom"`）
- `exit_distance`: 移動距離（ピクセル、既定 200）
- `wait_for_exit`: `true` で退場アニメ完了を待ってから次のコマンドへ
- `wait_after`: 退場完了後に待つ追加秒数（`wait_for_exit` と組み合わせるとフェード後の余韻に使用可能）

```gdscript
matilda.leave({
	"exit_effect": "fade_slide",
	"exit_to": "right",
	"exit_duration": 0.5,
	"wait_for_exit": true,
	"wait_after": 0.2
})
```

## 典型的なシーケンス例

```gdscript
var hero := b.character("main")
var matilda := b.character("matilda")
b.set_protagonist("main")

b.background("res://assets/backgrounds/bg01_university.png", 0.5)
b.show_band()
b.narrator_band("5月の大学キャンパス。")

hero.band("本気を出せば主席だって狙えるのに…")
hero.hide_dialogue()
hero.band("掲示板の募集、まだ締切ってないはずだ。")
b.clear_band_text()

b.background("res://assets/backgrounds/bg03-1_lab.png", 0.5)
hero.say("ここが噂の研究施設…SPring-8そっくりじゃないか。")
matilda.say("勝率を見せな。")
```

このファイルを参照しながら `_build_prologue()` などの章スクリプトを編集すると、各メソッドの意図やパラメーターがわかりやすくなります。
