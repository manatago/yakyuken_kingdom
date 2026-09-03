# 軽量 Godot CI 導入計画

## 目的

プルリクエストごとに、Godot プロジェクトの読み込み不能や今回追加したバトル・アイテムロジックの回帰を早期に検出する。実画面テストを実行せず、GitHub Actions の実行時間と不安定さを抑える。

## 現状

- `.github/workflows/` は存在せず、GitHub Actions は未設定。
- `godot/tests/RunBattleSystemItemTests.gd` はヘッドレス実行できる。
- `godot/tests/run_regression.sh` は一部で実ディスプレイが必要なテストを実行するため、初期CIには不適切。
- 画像アセットは Git LFS 管理であり、CI のチェックアウト時に LFS 取得が必要。
- ローカルで確認済みの Godot は 4.6.2。

## 提案する挙動

`pull_request` と `main` への push で、Linux ランナー上の軽量CIを実行する。

1. Git LFS を含めてリポジトリをチェックアウトする。
2. Godot 4.6.2 を固定して導入する。
3. Godot をヘッドレスでエディタ起動し、プロジェクトとアセット参照を検証する。
4. `RunBattleSystemItemTests.gd` をヘッドレス実行する。
5. いずれかが非ゼロ終了なら、PRチェックを失敗にする。

## 対象範囲

- 新規: `.github/workflows/godot-ci.yml`
- 必要なら新規: CI用の小さなヘッドレステスト起動スクリプト
- 既存: `godot/tests/RunBattleSystemItemTests.gd` をCIで実行する

## 対象外

- 実画面、クリック入力、スクリーンショットを必要とするテスト
- `godot/tests/run_regression.sh` の全実行
- ゲームのエクスポート・配布zip作成
- macOS/Windowsのマトリクスビルド
- テストフレームワークの全面置換

## 代替案

### A. 初期段階は2コマンドだけ実行する（採用）

- `Godot --headless --path godot --editor --quit`
- `Godot --headless --path godot --script res://tests/RunBattleSystemItemTests.gd`

実行時間と失敗原因を最小化できる。新しいロジックテストは、CI安全な `Run*.gd` を明示的に追加していく。

### B. `run_regression.sh` を全実行する

既存回帰テストを広くカバーできるが、実ディスプレイを必要とするテストが混在し、Linux CIでは `xvfb` 等の追加設定と長い実行時間が必要になるため不採用。

### C. PRでエクスポートまで行う

配布物の検証は強くなるが、実行コストが高く、export presetの保守も必要になるため不採用。リリース工程が固まった後にタグPushまたは夜間実行として検討する。

## リスクと対策

- **Godot導入方法の保守**: ワークフロー内でエンジンのバージョンを固定し、更新はローカル確認後にのみ行う。
- **LFS未取得**: チェックアウト時のLFS有効化と、必要に応じた `git lfs pull` を明示する。
- **テスト増加による遅延**: 初期はテストを明示的なallowlistにし、全`Run*.gd`の自動探索はしない。
- **UI回帰の未検知**: 実画面テストはローカル手動確認に残す。CIに無理に含めない。

## 実装手順

1. GitHub Actionsで利用するGodot 4.6.2の導入手段を選定し、バージョン固定する。
2. `.github/workflows/godot-ci.yml` を追加する。
3. `pull_request` と `push`（`main`）をトリガーに設定する。
4. LFSを有効にしてチェックアウトする。
5. ヘッドレスのエディタ検証と `RunBattleSystemItemTests.gd` を別ステップで実行する。
6. PR上で各ステップのログと終了状態が確認できることを検証する。
7. ローカルの同一コマンドとCI結果が一致することを確認する。

## 検証

- 意図的なGDScript構文エラーを含むブランチで、エディタ検証ステップが失敗すること。
- `RunBattleSystemItemTests.gd` の期待値を一時的に壊したブランチで、テストステップが失敗すること。
- 通常のPRで2ステップとも成功し、実画面テストやエクスポートが起動していないこと。
- Git LFS管理のアイテム画像を参照するテストが成功すること。

## 未解決事項

- GitHub Actions上でGodot 4.6.2を導入する具体的な方式（固定Dockerイメージまたはバイナリ取得）。
- CI用に追加するヘッドレステストを、将来どの単位でallowlistへ増やすか。
