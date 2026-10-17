# Repository Guidelines

## 現行Electron開発とWindows引継ぎ

- 最初にルートの `Windows移行指示.txt`、次に `docs/WINDOWS_HANDOFF.md` を読む。既存Windowsディレクトリ全体のバックアップを作成・確認してから引継ぎブランチへ切り替える。新規cloneは必須ではない。移行準備ではゲーム・UI／Smokeテストを起動しない。古い変更を自動で混ぜない。
- 現在の開発対象はElectron版（`electron/`、`packages/`、`content/`、`tests/`）。Godotはストーリー・配置・動作の唯一の移植原本。以下のGodot向け手順は原本確認用。
- 残作業・保留は `docs/plans/electron-developer-tools-parity.md`、検証履歴は `test-results.md`。全移植を完了済みと推測しない。
- Node.jsはCIと同じ22.12.0。`npm ci`、`npm run typecheck`、`npm test`、`npm run test:ui`、`npm run smoke:game`、`npm run smoke:editor`で検証。PowerShellでは`npm.cmd`を使用。Macでの成功をWindows成功と扱わない。
- ゲームとエディタは別ビルド。通常セーブとGodot原本を検証で上書きせず、編集済みJSONも再抽出で上書きしない。
- 重大な問題以外は自律的に進め、判断を記録。コミット・Push・マージは依頼時のみ。通常PRはdevelop向け。移行だけを理由にmain/developをマージしない。

## プロジェクト構成とモジュール配置
- `godot/` には本番用 Godot 4 プロジェクトがあり、主要シーン (`Main.tscn`, `Table3D.tscn`) やゲームスクリプト、シェーダー、アセットがまとまっています。ランタイム作業は Godot 4.2 以上で `godot/project.godot` を開き、`timelines/` や `resources/` をセットで更新すると差分追跡が容易です。
- 旧ブラウザ向けシェルは廃止済みですが、現行Electron版とは別物です。ドキュメント用途の `assets/` は参考資料・画像プロンプトのみを置きます。

## ビルド・テスト・開発コマンド
- Godot エディタで `Main.tscn` を実行し、演出・バトルフローを手動確認してください。
- 会話や HUD だけ確認したい場合は `TestDisplay.tscn` を使い、`StoryScene` 単体での再生をデバッグできます。
- エクスポート手順は `Project > Export` から Python/シェーダー含めてビルドし、zip 化の前に `Project > Tools > Reimport` でアセットを刷新してください。

## コーディングスタイルと命名
- GDScript は 4 スペースインデント、シーンクラスは PascalCase (`Table3D`)、関数や export 変数は snake_case を徹底します。Signal を優先し、補助スクリプトは対応 `.tscn` と同じフォルダーに置きます。
- コメントは意図や数学的トリックなど説明が必要な部分だけに絞り、ノード名やフォルダー名で自己説明的に保つ方針です。

- Electron版は単体・結合・UIテストを実行して記録してください。原本との演出比較は再現手順と期待結果も記録し、自動テストだけで見た目の一致を断定しないでください。

## コミットと Pull Request
- Git は英語の命令形・センテンスケースでまとめます（例: `Implement win rate control logic`）。Godot シーンとスクリプトの関連変更は同じコミットに束ね、1 つの振る舞いにフォーカスしてください。
- PR では簡潔な概要、UI が変わる場合のスクリーンショット/GIF、参照した `game_spec.md` セクション、実行した Godot プレイテストの手順を明示します。関連 Issue をリンクし、影響したシーンの担当レビューアをメンションしましょう。
- アセット追加時は出典ライセンスを PR 説明へ記載し、`godot/assets/` (必要なら `godot/raw_images/`) に想定外の差分がないか WIP 中でも確認してください。

## セキュリティと構成メモ
- 外部サービスのトークンは `.env.local` など未コミットファイルに置き、Godot 側へ渡す場合は `project.godot` に直書きしないで `autoload` スクリプトから参照します。
- 大きな画像を扱う際は `godot/tools/install_all_assets.py` や `godot/tools/setup_assets.py` で生成されるテンポラリを `.gitignore` で管理し、誤ってバイナリをコミットしないようにします。

<!-- AgentSkills Common Rules: BEGIN -->
## AgentSkills Common Rules

When `.agentskills/rules/AGENTS.base.md` exists locally, read and follow it before AgentSkills workflow work; use the available `::help` implementation for command discovery.
`.agentskills/` and `.agents/` are ignored local tooling and may be absent in a fresh clone. If absent, follow this file and repository-native commands. Do not claim unavailable pseudo-commands or gates ran, or reuse Mac-specific absolute paths on Windows.
<!-- AgentSkills Common Rules: END -->
