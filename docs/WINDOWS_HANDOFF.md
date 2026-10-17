# Windows開発環境への引継ぎ

更新日：2026-10-16。移行先エージェントが、この会話を参照せずに作業するための資料です。

## 今回の取得ブランチ

`chore/windows-development-handoff` を使用します。このブランチへ本資料と最新実装をまとめて公開します。GitHubで本資料を閲覧できる状態になった後は、以下の「作成時点で未Push」という記載は公開前の経緯です。取得後は `git rev-parse HEAD` で実際のSHAを記録してください。

資料URL：<https://github.com/manatago/yakyuken_kingdom/blob/chore/windows-development-handoff/docs/WINDOWS_HANDOFF.md>

## 目的と方針

開発をMacからWindowsへ移します。Windowsには古いcloneがありますが、ほぼ使用していません。**Mac側の最新版を正とし、旧Windows cloneはバックアップとして残し、新規cloneで再開してください。旧コードをマージする作業ではありません。**

Windowsを主対象、macOSも対応対象とします。FHD基準、縦横比優先で余白を許容します。ゲームと開発用エディタは別ビルドです。Godotが唯一の移植原本であり、セリフ・画像・配置・動作を独自ストーリーへ置き換えません。

判断できることは自律的に進め、判断・未確認点を記録してください。既存データの破棄、認証不足、取得元不明などの重大な問題だけ確認を求めます。引継ぎ依頼だけではコミット・Push・PR・マージを行いません。

## 公開前の確認（Mac側担当）

**本資料の作成時点では、最新実装と本資料は未コミット・未Pushです。GitHubのmainを取得するだけでは最新版になりません。** 公開担当はユーザーからPublishの指示を受けてから、以下を行います。

1. `git worktree list` と差分で最新実装の作業ツリーを確認します。通常の古いdevelopフォルダではなく分離した作業ツリーにあります。基点 `870028117f09deea2c02a01fcd86932075fff851` はmain統合コミットであり、引継ぎ完成版ではありません。
2. 本資料・README・AGENTS・ONBOARDINGと最新実装を**同じ引継ぎブランチ**へ公開します。必要な未追跡ソース・コンテンツ・テストも含めます。無関係なGodot画像変更、node_modulesリンク、生成UID、キャッシュ、ローカルエージェント状態は除外します。
3. 移行のためだけにmain/developをマージしません。現在の実装はmain由来です。通常のdevelop向けPRを作る場合もmain固有のGodot変更を不用意に混ぜないよう差分を確認します。
4. Push後、ブランチ名・最新SHA・**そのブランチの本資料のGitHub URL**を渡します。必要なLFSオブジェクトの公開も確認します。

Windows側は、**渡された本資料のGitHub URLが指すブランチ／コミット**を取得します。main/developへ読み替えません。取得元が不明なら確認します。

確認用ファイル：`electron/renderer/src/GameExit.tsx`、`electron/renderer/src/TitleNavigation.tsx`、`content/developer-tools.json`、`tests/ui/exit-menu.test.mjs`。資料だけ存在し実装が欠けていたら公開不備として報告し、古いWindowsコードで補完しません。

## Windows側の実行手順

### 1. 古いcloneを保存

既存フォルダで `git status --short --branch`、`git remote -v`、`git log -1 --oneline` を確認します。認証情報を含むURLは転載しません。本リポジトリと確認できたフォルダだけを、使用中のエディタやゲームを閉じたうえで日付付きの別名へ変更して残します。変更できなければ別の新規フォルダを使います。

バックアップは削除しません。`reset --hard`、`clean`、旧フォルダへの上書きは不要です。Macのnode_modules、dist、.godot、一時フォルダ、資格情報、実セーブはコピーしません。セーブ移行は今回の依頼に含みません。

### 2. ツール・認証・取得元を確認

WindowsネイティブのPowerShellで実行します。Node.jsはCIと同じ22.12.0。WSLでの成功をWindows版の成功としません。

```powershell
git --version
git lfs version
node --version
npm.cmd --version
git lfs install
```

次の変数は、実際の資料URLと未使用の配置先から設定します。山括弧の説明文をそのまま実行しません。

```powershell
$SourceBranch = 'chore/windows-development-handoff'
$TargetDir = '<新規clone先の絶対パス>'
git clone --branch $SourceBranch https://github.com/manatago/yakyuken_kingdom.git $TargetDir
Set-Location $TargetDir
git status --short --branch
git rev-parse HEAD
git lfs pull
node .github/scripts/pull-original-assets.mjs --check
```

**各コマンドの終了コードを確認し、失敗したまま次へ進みません。** 資料URLがSHA固定なら、そのコミットを取得・チェックアウトします。ブランチの場合も公開担当から受けたSHAと照合し、違えば差分を確認します。

GitHubとLFSは別認証です。ユーザーは既存LFSユーザー名・パスワードを所持しています。不足時は本人にOSの対話的認証へ入力してもらいます。チャット・ログ・URL・`.env`へ秘密情報を記載させません。[認証の注意](ONBOARDING.md)を参照してください。HTTP/HTTPS・認証方式・CI設定は変更しません。

LFSポインタのままなら取得未完了です。画像表示の実装不具合と誤診しません。スクリプトの `--pull` はCI用認証経路なので、ローカルでは通常の `git lfs pull` を使います。

### 3. 依存導入と検証

リポジトリ直下で順に実行し、終了コードと実行結果を確認します。

```powershell
npm.cmd ci
npm.cmd run typecheck
npm.cmd test
npm.cmd run test:ui
npm.cmd run smoke:game
npm.cmd run smoke:editor
```

`npm test` は単体・結合テストです。結合・UIテストは両ビルドを含みます。テストは隔離userDataを使い、通常セーブは書き換えません。UIテストを起動できない環境なら未確認と記録し、成功扱いにしません。

`npm.cmd`を使い、PowerShell全体の実行ポリシーを緩めません。lockfileを維持し、依存の一括更新や `npm audit fix` は行いません。同じフォルダでテスト・ビルド・開発サーバーを並行起動しません。

### 4. 起動と報告

検証後に `npm.cmd run dev:game`。エディタ単独起動は `npm.cmd run dev:editor`。古いゲームを複数残さず、本リポジトリ由来と確認できた不要プロセスだけを終了します。

タイトル階層、途中開始の場面選択、イベント戦、別エディタ起動、手札表面とグレード、相手より手前のテーブル、下部Exitで最上位タイトルへ戻ることを確認します。一時プレイで通常セーブが変わらない検証も隔離環境で行い、実セーブをテスト用にしません。

ブランチ／SHA、旧フォルダ保存先、新規作業先、ツールバージョン、LFS結果、テスト成功数・失敗・未確認、両アプリ起動結果、判断した点を報告します。共有する検証記録は `test-results.md` に残します。コミット・Pushは別途依頼がある場合だけです。

## 引き継ぐ現在の実装

- 通常ゲームはFHDを上限に作業領域へ収め、エディタは1280×720。
- タイトルは「新しく始める」「中断から始める→場面選択」「イベントバトル→通常戦10件」「編集モード」の階層。「つづきから」は通常の保存再開。
- 途中開始・単独イベントは一時メモリセッション。別エディタからの開発プレイも通常セーブと隔離。
- Exitはアプリ終了ではなく最上位タイトルへ戻る。閲覧画面と一時セッションを閉じ、通常プレイの進行中保存を待つ。古い非同期処理の復活を防止。
- 手札がボタン余白で縮んでいた問題と、通常戦・依頼戦・マチルダチュートリアル・プレビューのテーブル重なり順を修正。冒険者チュートリアルへのテーブル追加は別の未対応差分。
- 開始地点108件中93件が利用可能。区切り10、存在しないラベル3、Smoke専用、マチルダ敗北専用の計15件は理由表示して無効化。
- 全47ストーリーの既存命令値と、9種類の戦闘／ミニゲーム文書の既存表示命令を編集可能。保存・再読込・競合検出・バックアップ、画像候補・プレビュー、参照画像のビルド同梱を実装。

2026-10-16のMac検証：型チェック、両ビルド、単体349/349、結合42/42、UI87/87、ゲーム／エディタ両Smoke成功。**Windows確認の代わりではありません。** 後続変更で件数は変わり得るため、現在の結果を記録します。

## 残作業と保留

移植全体は未完了です。[統合タスク](plans/electron-developer-tools-parity.md)を正とし、残りも1件として進めます。

- ランダム戦立ち絵編集、バトルシステム確認。
- 画像取り込み／書き出し、ワンド・ブラシ・Undo・rembg等。
- セリフ／紙芝居ページの追加・削除と保存位置・スナップショット整合。
- 途中開始の専用処理、開発用勝敗指定 `force_result_selector_mode`。
- 全対象の保存後ゲーム反映と原本操作の網羅確認。
- 下部Save／Load／Configは未実装。Exit完了と混同しない。

ユーザー指定の保留：ギルドホームからサブイベントへの通常進行問題、Skip、Godot原本のバグ修正、身代わりカード報酬、配布・更新・署名、HTTPS化。移行のついでに仕様追加・修正しません。

編集済みJSONを原本再抽出で上書きしません。ローカル `.bak` は新規cloneにあるとは限りません。再抽出は別出力へ行い、編集内容と照合してから統合します。

`.agents/`、`.agentskills/`、`SESSION_BRIEF.md`、Mac一時ログはGit管理外です。追跡対象の資料・コード・テストを根拠にし、ローカル専用資料や疑似コマンドがWindowsにもあると仮定しません。

## 移行先エージェントへの指示例

> このGitHubブランチの `AGENTS.md` と `docs/WINDOWS_HANDOFF.md` を読み、Windowsへの引継ぎを実行してください。古いcloneをバックアップとして残し、この資料と同じブランチの最新版を新規取得してください。LFS・依存導入・単体／結合／UIテスト・ゲームとエディタの起動まで確認し、結果を報告してください。重大な問題以外は自律的に進め、通常セーブと認証設定は変更せず、コミット・Pushはまだしないでください。
