# Micro Motion Demo 再開メモ

## 現状
- `docs/micro_motion_demo.md` に実装ガイドと DSL 連携方針をまとめ済み。
- Godot プロジェクト（`godot/`）側にはまだ `StoryMicroMotionCommand` やデモ専用チャプターの実装が入っていない想定。
- 立ち絵素材は未確定。Body/Head 分離、目・口差分などが必要。

## すぐに再開する手順
1. Godot 4.2 以上で `godot/project.godot` を開く。
2. `StoryCharacterRoot` 系ノードに微細アニメ API（呼吸、瞬き、Tween など）を実装。
3. `StoryMicroMotionCommand.gd` を `StoryCommand` から派生させ、`StoryCharacterHandle` へ `breathe/slide_in/blink` 糖衣関数を追加。
4. `DemoMicroMotionChapter.gd`（仮）を作り、各手法を 1 回ずつ呼び出す構成で DSL を記述。
5. `StoryScript.gd` と `Main.gd` にデモ切り替え用の export 変数/enum を追加し、Inspector から `Demo` を選択して `Main.tscn` を F5 実行して確認。

## アセット面で必要なもの
- Body/Head 分離済みの立ち絵 PNG。
- 目パチ、口パク差分（各 2〜3 コマ）。
- デフォーメーション用にメッシュ化したシーン（必要なら）。
- 風揺れ対象部分のマスク or 個別スプライト。

## 実装後の確認メモ
- Demo モード → 全 5 手法が順番に発火するか。
- 本番モード → 既存 Prologue/Stage へ影響しないか。
- 重要演出変更時は README or PR テンプレに再現手順を書き足す。
