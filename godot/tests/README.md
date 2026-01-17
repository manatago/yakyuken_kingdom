# Godot Test Runner

このフォルダーには簡易的な GDScript テストハーネスを配置しています。`TestRunner.gd` は `TestSuite` を継承したクラスを順番に実行し、CLI で結果を表示します。

## 実行方法

Godot 4.2 以降で以下を実行します。

```bash
godot4 --headless --path godot --run TestRunner
```

* `--headless` はウィンドウを開かずに実行するオプションです。
* `--run TestRunner` で `class_name TestRunner` を持つノードを起動し、スクリプト内でテストを走らせます。

成功時は `[PASS]` ログとともにゼロ終了コードで終了し、失敗時は `push_error` と非ゼロコードで終了します。
