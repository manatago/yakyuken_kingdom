# Godot Docker Environment

Godot 4.4.1 のヘッドレス実行環境です。テスト実行やプロジェクト検証に使用します。

## セットアップ

```bash
cd docker
./run.sh build
```

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `./run.sh build` | Dockerイメージをビルド |
| `./run.sh validate` | プロジェクトを検証（インポート＆エラーチェック） |
| `./run.sh test` | テストを実行 |
| `./run.sh import` | リソースを再インポート |
| `./run.sh shell` | コンテナ内でbashを起動 |
| `./run.sh godot <args>` | 任意のGodotコマンドを実行 |

## 使用例

```bash
# プロジェクト検証
./run.sh validate

# テスト実行
./run.sh test

# Godotバージョン確認
./run.sh godot --version

# スクリプトの構文チェック
./run.sh godot --check-only
```

## docker compose 直接実行

```bash
# 検証
docker compose run --rm validate

# テスト
docker compose run --rm test

# カスタムコマンド
docker compose run --rm godot godot --headless --version
```

## 制限事項

- **ヘッドレスのみ**: GUIは表示できません
- **確認可能**: スクリプトエラー、リソース参照切れ、テスト結果
- **確認不可**: ビジュアルレイアウト、アニメーション動作
