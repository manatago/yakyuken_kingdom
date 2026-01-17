# Repository Guidelines

## プロジェクト構成とモジュール配置
- `godot/` には本番用 Godot 4 プロジェクトがあり、主要シーン (`Main.tscn`, `Table3D.tscn`) やゲームスクリプト、シェーダー、アセットがまとまっています。ランタイム作業は Godot 4.2 以上で `godot/project.godot` を開き、`timelines/` や `resources/` をセットで更新すると差分追跡が容易です。
- Godot 以外のブラウザ向けシェルは廃止済みです。ドキュメント用途の `assets/` は参考資料・画像プロンプトのみを置きます。

## ビルド・テスト・開発コマンド
- Godot エディタで `Main.tscn` を実行し、演出・バトルフローを手動確認してください。
- 会話や HUD だけ確認したい場合は `TestDisplay.tscn` を使い、`StoryScene` 単体での再生をデバッグできます。
- エクスポート手順は `Project > Export` から Python/シェーダー含めてビルドし、zip 化の前に `Project > Tools > Reimport` でアセットを刷新してください。

## コーディングスタイルと命名
- GDScript は 4 スペースインデント、シーンクラスは PascalCase (`Table3D`)、関数や export 変数は snake_case を徹底します。Signal を優先し、補助スクリプトは対応 `.tscn` と同じフォルダーに置きます。
- コメントは意図や数学的トリックなど説明が必要な部分だけに絞り、ノード名やフォルダー名で自己説明的に保つ方針です。

- 自動テストは未導入のため、重要な演出変更時は Godot 内で再現手順と期待結果を README/PR に明記してください。

## コミットと Pull Request
- Git は英語の命令形・センテンスケースでまとめます（例: `Implement win rate control logic`）。Godot シーンとスクリプトの関連変更は同じコミットに束ね、1 つの振る舞いにフォーカスしてください。
- PR では簡潔な概要、UI が変わる場合のスクリーンショット/GIF、参照した `game_spec.md` セクション、実行した Godot プレイテストの手順を明示します。関連 Issue をリンクし、影響したシーンの担当レビューアをメンションしましょう。
- アセット追加時は出典ライセンスを PR 説明へ記載し、`godot/assets/` (必要なら `godot/raw_images/`) に想定外の差分がないか WIP 中でも確認してください。

## セキュリティと構成メモ
- 外部サービスのトークンは `.env.local` など未コミットファイルに置き、Godot 側へ渡す場合は `project.godot` に直書きしないで `autoload` スクリプトから参照します。
- 大きな画像を扱う際は `godot/tools/install_all_assets.py` や `godot/tools/setup_assets.py` で生成されるテンポラリを `.gitignore` で管理し、誤ってバイナリをコミットしないようにします。
