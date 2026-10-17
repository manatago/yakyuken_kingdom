# Yakyuken Kingdom (じゃんけんキングダム)

Godot版を唯一の原本として、Electron / React / TypeScriptへ移植しているカードバトルゲームです。Windowsを主対象とし、macOSにも対応します。

## 開発・引継ぎの入口

- **Windowsへ移行するエージェントは [Windows引継ぎ手順](docs/WINDOWS_HANDOFF.md) を最初に読んでください。** 古いcloneは保管し、同資料と同じ公開ブランチから新規取得します。
- [エージェント向けルール](AGENTS.md)
- [残作業の統合タスク](docs/plans/electron-developer-tools-parity.md)
- [開発用エディタ](docs/electron-layout-editor.md)
- [検証記録](test-results.md)

Windows引継ぎ版は`chore/windows-development-handoff`です。資料と実装を同じブランチへ公開します。main/developを最新版と推測せず、GitHub上の同ブランチの引継ぎ資料を参照してください。

## 特徴

- **3Dテーブルビュー**: 没入感のある3D空間でのカードバトル。
- **カードシステム**: 限られた手札を使った戦略的な駆け引き。
- **ダイナミックなカメラ**: スムーズなカメラワークと演出。
- **レスポンシブなUI**: 使いやすいHUDとリスタート機能。

## 遊び方

1. 手札からカード（グー、チョキ、パー）を1枚選びます。
2. CPUもカードを選びます。
3. バトルの結果を見守りましょう！
4. 3ターン勝負で勝ち越せば勝利です。

## 開発環境

現行版はNode.js 22.12.0（CIと同じバージョン）、Git、Git LFSを使用します。`git lfs install`、`git lfs pull`、`npm ci`、`npm run build`の順で準備し、`npm run dev:game`で起動します。Windows PowerShellでは`npm.cmd`を使えます。エディタは別ビルドで、単独起動は`npm run dev:editor`です。同じフォルダでテスト・ビルド・開発サーバーを同時実行しません。

以下の3D機能紹介はGodot原本の説明です。Electron版の実装状況は上記の統合タスクを参照してください。

### アセット
- カード画像やテクスチャは `godot/assets/` にあります。
- Godotは比較対象の原本です。Electron版は`electron/`、共通処理は`packages/`、ゲームが読むJSONは`content/`にあります。
- 画像・動画は Git LFS で管理しているため、clone する場合は事前に `git-lfs` をインストールしてください。
  詳しい手順は [docs/ONBOARDING.md](docs/ONBOARDING.md) を参照。
