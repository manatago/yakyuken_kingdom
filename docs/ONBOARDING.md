# Onboarding (Yakyuken Kingdom)

画像・動画アセット込みで開発に参加するためのセットアップ手順です。

このプロジェクトは画像/動画を **Git LFS** で管理しています(セルフホスト LFS サーバ on Sakura VPS)。
通常の `git clone` / `git pull` / `git push` がそのまま使えますが、初回だけ git-lfs と認証の準備が必要です。

## 0. 認証情報の受け取り

LFS サーバへアクセスするための **Basic Auth ユーザー名/パスワード** を Satoshi から個別に受け取ってください
(Slack DM や 1Password 等、安全なチャネル経由)。GitHub 側は SSH 鍵で認証されるので、こちらは別途 GitHub に登録済みであること。

## 1. ツールのインストール

### macOS
```bash
# Homebrew 未導入なら:
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install git git-lfs
git lfs install   # 初回のみ。git にフィルタを登録する
```

### Windows
1. [Git for Windows](https://git-scm.com/download/win) をインストール(LFS オプションを有効に)
2. または、Git 既導入なら [git-lfs.com](https://git-lfs.com/) のインストーラを別途実行
3. PowerShell / Git Bash で:
```powershell
git lfs install
```

### Linux (Ubuntu/Debian)
```bash
sudo apt update && sudo apt install -y git git-lfs
git lfs install
```

### Linux (Rocky/RHEL/Fedora)
```bash
sudo dnf install -y git git-lfs
git lfs install
```

## 2. credential helper の設定(重要)

**macOS の標準は Keychain (`osxkeychain`) ですが、このプロジェクトでは推奨しません。**
過去に Keychain が古い認証情報をキャッシュしてループ事故が起きたため、**ファイルベース (`store`)** にしてください。

```bash
git config --global credential.helper store
```

これで `~/.git-credentials` にプレーンテキストで保存されます(権限 600)。
ローカル開発機で完結する範囲なら問題ありませんが、共有マシンや会社支給端末では運用ルールに従ってください。

Windows でも同じく `store` を推奨します(`wincred` だと同様の事故が起きる場合あり)。

## 3. リポジトリの clone

```bash
git clone git@github.com:manatago/yakyuken_kingdom.git
cd yakyuken_kingdom
```

clone の途中で **Username / Password を聞かれる**ので、Step 0 で受け取った認証情報を入力:

- Username: 受け取ったユーザー名(例: `satoshi`)
- Password: 受け取ったパスワード

> **タイプミス防止**: パスワードはタイプせず、クリップボード経由で貼り付けるのが安全です。
> macOS なら別ターミナルで `echo -n 'パスワード' | pbcopy` してから貼り付け。

入力すると画像・動画が LFS サーバから自動でダウンロードされ、`godot/assets/` 配下に展開されます。

## 4. 日常の開発フロー

```bash
git pull origin main          # 差分(画像/動画含む)を取得

# 画像を追加・差し替え
git add path/to/new_image.png
git commit -m "..."
git push origin <branch>      # ポインタは GitHub、本体は LFS サーバへ自動振り分け
```

`.gitattributes` で指定されている拡張子(`*.png`, `*.jpg`, `*.jpeg`, `*.gif`, `*.webp`, `*.bmp`,
`*.tiff`, `*.tif`, `*.psd`, `*.mp4`, `*.mov`, `*.avi`, `*.webm`, `*.mkv`, `*.m4v`)は自動で LFS に乗ります。
SVG は意図的に対象外(XML 差分を読めるように)。

## 5. トラブルシュート

### 5.1 `Uploading LFS objects: 0% ...` で止まる
ほぼ確実に **認証情報の不一致**です。Keychain が古い情報を返している可能性が高い。

```bash
# Keychain 側のエントリを削除
security delete-internet-password -s 49.212.195.249 2>/dev/null

# 認証情報を ~/.git-credentials に直接書く (Step 0 で受け取った値を埋める)
echo 'http://USERNAME:PASSWORD@49.212.195.249:8080' > ~/.git-credentials
chmod 600 ~/.git-credentials

# 再 push
git push origin <branch>
```

### 5.2 `Username for ...` が繰り返し出る
パスワードのタイプミス。`6`/`b`, `0`/`O`, `5`/`S`, 大文字小文字を間違えやすいので、必ずクリップボード経由で。

### 5.3 `Remote "origin" does not support the Git LFS locking API` 警告
無害。サーバ実装(rudolfs)がロック API を持たないだけ。警告を消したければ:
```bash
git config --local lfs.locksverify false
```

### 5.4 `git 'lfs' is not a git command`
`git-lfs` バイナリが入っていません。Step 1 を実行してください。

### 5.5 LFS サーバがダウン/オフライン環境にいる
画像なしで作業したいときは ZIP フォールバックを使えます。詳しくは
[CLAUDE.md](../CLAUDE.md) の「ZIP フォールバック」セクション参照。

## 6. 参考

- LFS サーバ URL: `http://49.212.195.249:8080/api/manatago/yakyuken_kingdom`
  (`.lfsconfig` に書かれているので意識する必要なし)
- アーキテクチャ全体像 / Docker / Godot ビルド方法: [CLAUDE.md](../CLAUDE.md)
