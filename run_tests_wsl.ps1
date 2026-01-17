$ErrorActionPreference = "Stop"

<#
Usage:
  1. PowerShell を管理者権限で開かずに通常のセッションでこのディレクトリへ移動します。
  2. 以下のコマンドを実行してセッション単位でスクリプト実行を許可します。
       PS> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  3. 続けてテストスクリプトを実行します。
       PS> .\run_tests_wsl.ps1
  4. セッションを閉じれば元の実行ポリシーに戻ります。

Note:
  WSL から直接 Windows の Godot 実行ファイルを呼び出すと vsock エラー
  (UtilAcceptVsock/UtilBindVsock) でハングするため、WSL 側でも PowerShell を
  経由してこのスクリプトを実行してください。
#>

$godotPath = "D:\Application\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe"
$projectPath = "D:\Dropbox\Git\OtherRepositories\janken\godot"

Write-Host "[PowerShell] Running Godot tests..."


$arguments = @(
    "--headless",
    "--path", $projectPath,
    "--script", "res://tests/TestRunnerMain.gd",
    "--rendering-driver", "dummy",
    "--audio-driver", "Dummy",
    "--no-window"
)

$godotOutput = & $godotPath @arguments 2>&1
$exitCode = if ($LASTEXITCODE -ne $null) { $LASTEXITCODE } else { -1 }
Write-Host "--- Godot output begin ---"
$godotOutput | ForEach-Object { Write-Output $_ }
Write-Host "--- Godot output end ---"

if ($exitCode -ne 0) {
    Write-Host "Tests failed with exit code $exitCode" -ForegroundColor Red
    exit $exitCode
} else {
    Write-Host "Tests completed successfully." -ForegroundColor Green
}
