# 未完了タスク・既知の問題

## ~~1. バトル中の画像位置ずれ（88px問題）~~ — 解決済み

Godotレイアウトエンジンがキャラクター `TextureRect` の位置を意図せず変更していた。`StoryScene.gd` に位置ロック機構（`_char_locked_positions`）を追加して解決。BattleScene.gd の暫定対策（2回目 `setup_scene`）も削除済み。

---

## 2. ランダムバトル編集モード — farewell画面のスライダー

**現象**: バトル後の去り際画面（farewell）で、スライダーを動かしても画像の位置・スケールが反映されない。

**原因**: `_on_portrait_slider` が呼ばれているか未確認。GuildHome の `_input` でクリックがフィルタされている可能性、またはスライダーの `value_changed` シグナル接続に問題がある可能性。

**対象ファイル**: `godot/game/Main.gd`, `godot/game/GuildHome.gd`

---

## 3. gold_reward / gold_penalty のコマンド化

**設計済み・未実装**: `b.battle()` のDSLコマンドからゴールド報酬・ペナルティを指定できるようにする。

```gdscript
# 想定する書式
b.battle("res://battle/chapters/PrologueBattleChapter.gd", {
    "gold_reward": 20,       # 勝利時の固定ゴールド
    "gold_penalty": 0,       # 負け時のゴールド没収（0=なし）
    "can_gain_cards": false,
    "can_lose_cards": false,
})
```

現在はチャプターファイル内の `get_gold_reward()` で定義。コマンドからのオーバーライドは未実装。

**対象ファイル**: `godot/story/StoryCommands.gd`, `godot/game/BattleScene.gd`, `godot/battle/BattleChapterBase.gd`

---

## 4. デバッグログの削除

以下のprint文がコード内に残っている（本番前に削除が必要）:

- `godot/game/StoryScene.gd`: `[CHAR]` ログ
- `godot/game/BattleScene.gd`: `[SETUP_AFTER]` ログ
- `godot/game/Main.gd`: `[EDIT]`, `[EDIT-PORTRAIT]` ログ
- `godot/game/BattleScene.gd`: `[FORCE]` ログ

---

## 参考: 完了済みの主要機能

- GameState autoload（ゲーム状態一元管理）
- Card クラス（グレード別確率補正）
- ランダムバトルシステム（エンカウント、EncounterDatabase）
- アイテム/装備システム（ItemDatabase、バトル中使用）
- ゴールド報酬/ペナルティ
- 動画再生（OGV、全画面、縦横比維持）
- キャラ編集モード（スライダー、エリア選択、装備選択）
- イベントバトル編集モード（結果強制ボタン）
- Stage2BattleChapter（受付嬢戦）
