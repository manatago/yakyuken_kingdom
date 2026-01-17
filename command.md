# Project Commands

## Run Godot Tests

PowerShell で以下を実行してください。

- Windows (PowerShell) から `run_tests_wsl.ps1` を使う:
  ```powershell
  cd D:\Dropbox\Git\OtherRepositories\janken
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  .\run_tests_wsl.ps1
  ```
  PowerShell スクリプト内で実行ファイル・プロジェクトパスを指定しているので、このコマンドを実行するだけでテストが走ります。

  ※ WSL から直接 Windows 版 Godot を叩くと `UtilAcceptVsock` などの vsock エラーで止まるため、WSL からもこの PowerShell スクリプトを呼び出して実行してください。

- `--headless` : ウィンドウを開かずに実行
- `--path` : `project.godot` がある `godot` ディレクトリ
- `--run TestRunner` : `godot/tests/TestRunner.gd` を起動して全テストを実行
