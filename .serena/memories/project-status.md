# プロジェクト状況 - Yakyuken Kingdom

## アーキテクチャ決定事項
- **Portrait参照方式**: ラベル辞書 → `res://` 直接パス指定に移行済み (2026-02-26)
  - `StoryCharacter.get_portrait_path()` は `res://` 始まりならそのまま返す
  - 辞書は後方互換のため残っているが空。今後のキャラ追加でも辞書不要
- **画像背景透明化**: ImageMagick floodfill (fuzz 15%, 四隅) で白背景除去が有効

## キャラクター画像
- メインキャラ: `assets/characters/char01-*.png`, `ch01-*.png`
- ヒロイン(プロローグ): `assets/characters/prologue/char02_pg_001〜008.png` (背景透明済)
- ヒロイン(デフォルト): `assets/characters/char02-1_childhood_friend.png`
- 番兵: `assets/characters/char03-1_guard.png`
- マチルダ: `assets/characters/char04-1_prison_guard.png`

## テスト状況
- 13件全PASS (StoryScript 6, StorySequence 3, StoryScene 4)
- RIDリーク警告はGodotヘッドレス環境の既知問題（無害）

## 既知の課題
- PrologueChapter内のコメントアウト行(247〜302行)は旧シナリオ。整理が必要
- prologue/配下のヒロイン画像 002〜008 はまだシーンに未割り当て
