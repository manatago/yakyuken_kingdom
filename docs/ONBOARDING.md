# Git / LFSの準備

Windowsへの移行は先に [Windows引継ぎ手順](WINDOWS_HANDOFF.md) を読んでください。取得ブランチ、古いcloneの保存、ビルドと検証をまとめています。

## 必要なもの

Git、Git LFS、Node.js 22.12.0（CIと同じバージョン）、GitHubへのアクセス権、既存LFSサーバーのユーザー名・パスワードが必要です。

`git --version`、`git lfs version`、`node --version`、`npm --version`で確認し、`git lfs install`を実行します。Windows PowerShellでは`npm.cmd`を使えます。

## 認証

GitHubのコード取得とLFS画像取得は別認証です。`gh auth status`の成功だけでは画像取得を確認できません。既存のOS資格情報管理を使用し、不足時はユーザー本人に対話的認証を依頼してください。ユーザーはLFSのユーザー名・パスワードを所持しています。

秘密情報をチャット、リポジトリ、`.env`、URL、コマンド引数、ログへ記録しません。平文資格情報ファイルの作成、`credential.helper store`の一律設定、既存資格情報の削除は行いません。Macの資格情報ファイルもコピーしません。

接続先は`.lfsconfig`です。現状はHTTP接続のため、Basic認証情報と通信内容がTLSで保護されないリスクがあります。HTTPS化は別作業として保留中です。移行時は接続先・認証方式・証明書検証・CI認証を変更せず、失敗内容を秘密情報なしで報告してください。

## 取得確認

```sh
git lfs pull
node .github/scripts/pull-original-assets.mjs --check
```

画像がLFSポインタのままなら取得未完了です。同スクリプトの`--pull`はCI用の認証経路を使うため、ローカルでは通常の`git lfs pull`を使います。

作業再開時は現在のブランチと変更を確認してから更新します。常にmainをpullしたり、古いフォルダへ強制上書きしたりしません。
