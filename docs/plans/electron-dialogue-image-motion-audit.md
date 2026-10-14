# Godot原本とのセリフ・画像・モーション照合

調査日: 2026-10-11。初回調査の結果は履歴として保持する。その後の修正・検証は「修正と検証」を参照。コミット・Pushは行っていない。

## 2026-10-12 継続調査

- 第2章ミニゲームは原本10場面・50応答を機械取得し、原本コマンド再生・初手支援ロック・選択・保存再開・勝敗後の同じstory復帰へ接続。対象UIで本文、表情バッジ、反応文、途中再開、所持情報不変を確認。吹き出しの配置・アニメーションを含む全画素一致は未確認。
- 第2〜6章通常戦は原本メソッドを変更せず、実GameStateのstageN_first_battle_doneを切り替えて初戦／再戦10設定・勝敗90分岐を取得。初戦win_rate=0、初戦敗北continue、再戦敗北guild_home。データの取得であり、本編戦闘画面／保存への接続完了ではない。
- 第3章ミニゲームは全本15×物証15=225組、既使用正解7分岐、未使用正解を選ぶ支援7分岐を取得。取得方法は実_apply_choice／_apply_pisukeの実行。画面・runtime・保存は未接続。
- 原本Main.gdのscenario_orderはprologue／stage1のみ。scenario_fromはstage2〜7を単独sceneとして再生する。sequence_finishedはis_dialogue_activeをfalseにするだけで次sceneを開始しない。Guildのnext_storyもホームを閉じてreturnするだけ。primary原本も同じで、linkedとの差は報酬処理2箇所のみ。旧Electronの独自な章連結を「Godotの実進行と一致」と扱わない。全章通常接続は追加調査・記録対象。

## 調査対象と証拠

- 原本: `/Users/sin/Git/OtherRepositories/janken/godot` の現在のファイル（ユーザー変更を含む）。
- Electron: `/private/tmp/janken-electron-linked` の現在のソース。起動中アプリのビルドとセーブは未特定。
- 原本の `DefaultStory` をGodotで実行し、開発用exporterで `/private/tmp/janken-original-audit-20261011.json` へ出力。終了コード0、47シーケンス出力。macOS証明書警告あり。
- JSON構造の全体比較で `cast`、`portrait_layouts`、`sequences` はElectronの `content/stories/godot-original.json` と一致。
- 47シーケンス、2,586命令、画像配置86登録、画像参照275パス。275パスすべてが `original-assets.ts` に対応付け済み。画像の画素・全画面描画一致は今回未検証。

## データと実際の接続は別に判定する

|区間|データ|プレイ経路|
|---|---|---|
|プロローグ|一致|`createNewGameSave` → `original:prologue:0` → `OriginalStoryScreen`|
|マチルダ2戦・第1章|会話データ一致|原本用画面に接続、画面完全一致は未確認|
|サブイベント1・盗賊団|会話データ一致|原本用経路あり。別JSONを読む以前の経路もmainに残る|
|サブイベント2～4|会話データ一致|原本入口あり。ただしmainの依頼戦開始はsubevent1限定で、戦闘から先が未接続|
|第2～7章|原本データあり|GuildHome/mainは従来のstage別JSON・StoryScreenを使用する経路が残る|

根拠: `packages/domain/new-game.ts`、`electron/renderer/src/main.tsx`、`GuildHome.tsx`、`packages/battle/fixed.ts`、`packages/story/original-quest-save.ts`。

盗賊団の別データ `content/stories/subevent1-jin.json` はline27件中、原本の当該3シーケンスの本文・retry本文と完全一致するもの6件。改行差も不一致に含むため、残21件すべてを意味の変更とは断定しない。通常経路でどちらが使われるかはcheckpointとquestメタデータで異なる。ユーザーが見た画面の原因はまだ特定していない。

## モーション照合（初回調査・修正前）

原本会話命令の実数: show_character782、hide_character122、background78、band1407、battle26。登退場効果指定はfade200、fade_slide62、shrink1、fade_grow1。

|項目|判定|根拠|
|---|---|---|
|上から登場|部分一致|stage1命令13、ピースケ。fade_slide、top、300px、0.6秒をElectronも解釈する|
|スライドの速度変化|不一致|Godot登場はSINE/EASE_OUT、退場はSINE/EASE_IN。OriginalPortraitはlinear|
|縮小退場shrink|未実装|Godotは中心に向かってscale0へ縮小。Electronの退場framesはnormal→movedだけで縮小しない|
|fade_grow|実装あり・見た目未確認|Electronに中心から拡大する処理あり。原本と同じ全軌跡は未検証|
|背景クロスフェード|未実装|原本はBackground.fadeを使う。Electronはimgのsrc差し替えで、fadeを使用しない|
|退場待機|処理あり・見た目未確認|wait_for_exit、exit_duration、wait_afterの待機処理あり|
|連続画像・微動・背景フィルター|今回の会話出力では該当0件|原本再生エンジンには命令型があるが今回47シーケンスに実命令なし。戦闘・別経路は別途確認が必要|

根拠: Godot `game/StoryScene.gd` の `_apply_character_entry_effect`、`_apply_character_exit_effect`、`show_background_entry`。Electron `OriginalStoryScreen.tsx` のOriginalPortraitとrun。

画像配置の優先順位（PortraitLayout → 行指定 → キャッシュ → キャラ既定値）の一部はElectronにあるが、キャラ既定倍率・offset_yや全てのキャッシュ条件の一致は未確定。JSON一致を画面一致として扱わない。

## 確定した結論と残り

原本の会話・画像指定の機械出力は一致。ただし別ストーリー実行経路が残り、原本への戦闘接続とモーション再現が未完了。全編一致とは判定できない。

次は通常起動のビルド・セーブ経路を特定し、各表示時点の本文・話者・画像・配置・効果を記録して原本と照合する。ピースケ落下、縮小退場、背景フェードは両アプリの時系列撮影も行う。現時点では動画・全編UIプレイ・画素比較は未実施。

## 実画面検証の追記

2026-10-11: 現在ソースの `npm run build:game` 成功。隔離Electronで `original-story.test.mjs` と `original-quest-entry.test.mjs` を実行し4/4成功。新規開始→原本prologue、保存再開、原本画像ロード、4依頼入口・教会再挑戦入口、盗賊団pre→hideout遷移を確認。全編通しの証明ではない。

ピースケ登場のアニメーション測定は調査用スクリプトの開始境界指定ミスで失敗。stage1:11はshow_characterであり入力待機しないため画面は12へ進むが、スクリプトは11の表示を待ってtimeout。ゲームのモーション不具合を示す失敗ではない。次は入力待機するstage1:12から登場命令13を測定する。測定結果・撮影は今回未取得。両診断ともfinallyでElectron終了と一時セーブ削除を実行。本番セーブは未使用。

### ピースケ登場の実測（続行で取得）

隔離Electronのstage1:12から13を実行し、Element.animate呼出しを測定。framesはopacity0/translate(0,-300px)→opacity1/translate(0,0)、duration600ms、easing linear。画像pisuke_default_001.pngロード成功。登場完了後、opacity1・translate0・display blockを確認し、stage1:14の原本本文（改行含む）と表示本文の一致を確認。

- 方向・距離・時間・画像・この時点の本文: 一致。
- 移動曲線: 不一致（Godot SINE/EASE_OUT、Electron linear）。
- 画像配置: Electron測定x1410.4/y70.4/scale0.2、原本画像2048×2048・right・offset[0,-600]のFHD計算と一致。両画面の画素比較は未実施。
- 撮影: `/private/tmp/janken-stage1-motion-audit.png`（登場途中）、`/private/tmp/janken-stage1-motion-final.png`（本文と登場完了後）。目視で完了後の鳥と主人公・本文を確認。
- 診断2回ともfinallyでElectron終了・一時save削除。初回save.readはnullで本番save未使用。ゲームコード変更なし。

### 盗賊団の主要人物46会話地点（実画面）

`subevent1_pre/hideout/post` のジン・マルコ・ガルド・ベルカ・番兵・受付嬢が話す全46入力待機地点を、隔離Electronの原本再生画面で確認。各cursorで表示本文（改行込み）を原本データの再生状態に照合。表示中の全人物画像について、ビルド済みPNGのSHA256と原本参照PNGを比較し、画像の欠落・予期しない人物の表示も検査。46地点とも差分なし。

当該3シーケンスに含まれる55画像参照は、linked worktreeと現在の主作業場所のGodotでファイル内容が一致。番兵登場地点post:20は `guard_default_025.png` が表示され、みのりではない。撮影 `/private/tmp/janken-thieves-guard-audit.png` を目視確認。

制限: 原本再生画面の地点別検証であり、通常プレイの戦闘・報酬・章間遷移を通した検証ではない。再挑戦フラグは未設定の初回相当。配置・背景・話者名の全46地点の独立測定、モーション、全編は今回の照合対象外。表示状態の期待値はElectronの再生エンジンから取得しているため、そのエンジン自体のGodotとの等価性の証明でもない。

診断初回はNodeのTSモジュール読込方式が合わず、Electron起動前に失敗。CommonJS読込方式で再実行して成功。ゲームコード修正なし。最後のsave.readはnull。finallyでElectron終了・一時saveフォルダ削除。

## 通常経路と起動中ゲームの調査

- `original-flow / original-quest-flow / original-town-flow / original-stage1-flow` Unit9/9成功。
- 実戦UI `original-quest-battle` 2/2成功。ジン勝利からhideout:29へ原本会話復帰、敗北から原本farewell→共通会話→Guild帰還、draft/結果/選択アイテムの再開を確認。開始点はbattle checkpointであり、冒頭から全戦闘通しではない。
- 新規開始コードはoriginal:prologue:0。原本Guildの受注ボタンはstartOriginalQuestを使う。過去Guild originや過去checkpointの場合、mainには旧StoryScreen経路が残る。
- CUAで既に起動中の `/tmp/janken-electron-linked/node_modules/electron/dist/Electron.app` の画面を読み取り（クリック・変更なし）。Janken Kingdom、URL `localhost:5173/`、checkpoint表示 `prologue.guard`、画像alt `サトシの立ち絵` と `friendの立ち絵`。番兵本文は「身元が確認できるまで、いったん保護室で話を聞く。落ち着いて事情を説明してくれ。」。
- この画面は現在ビルドしたfile://の原本再生画面とは異なり、旧StoryScreenの表示である。起動中画面が原本経路に入っていないことを直接確認。なぜ旧経路に入ったか（過去dev serverのモジュール・既存save等）の区別と、ユーザーが以前見た盗賊団の当時の状態は未特定。現在セーブファイルは読取・書換していない。
- 次はdev serverの起動元・読み込み済みモジュールとセーブcheckpointの関係を非破壊で特定し、最新版への起動統一と既存saveの扱いを検討する。過去saveを黙って削除・進行変換しない。

### 起動元・保存地点の切り分け

読み取り専用で調査。dev serverはlinked worktreeのelectron-vite、Electronも同worktreeのdist/game/main/index.jsを起動。localhost:5173から現在配信されるmain.tsxにはOriginalStoryScreenがあり、new-game.tsにはoriginal:prologue:0がある。別repositoryのdev serverではない。

プロセスのuser-data-dirとgame.tsの保存先を照合し、`/Users/sin/Library/Application Support/Electron/janken-save.json` の進行メタデータのみ読み取った。checkpointはprologue.guard、original_quest/original_quest_battle/subevent1_jin_battleなし。保存変更・リロード・ウィンドウ終了は行わない。

現main.tsxには旧プロローグ描画分岐がなく、該当checkpointは対応画面なしの表示に至るはずだが、既存ウィンドウは旧プロローグを表示中。このため現在配信コードだけではなく、ウィンドウ内の読込済みコード/状態が古いことも示される。旧saveと古い読込済み画面の組合せが現在の不一致要因。ユーザーが以前見た盗賊団の当時の保存地点は未取得なのでその時点まで断定しない。

最新版を起動し直すだけでは旧saveの続きは原本経路へ移らない。新規開始は原本経路だが旧saveを上書きするため、黙って実行しない。まず隔離saveで通常経路の検証を続け、旧save移行/退避の扱いは明示的に決める必要がある。

## 新規開始からの順次照合

通常タイトルの「はじめから」で隔離新規saveを作り、prologue冒頭から最初のチュートリアルまで実際に「次へ」で進行。入力待機86会話について本文を照合、表示人物の不足/余分、各人物PNGおよび背景PNGの実体を現在Godotと比較。退場アニメーション完了後の検査で差分0、original:prologue:198に到達して原本tutorial ledgerが作られた。

高速送りの初回検査は退場中の画像を「余分」と数えたが、演出完了後の再検査では消えた。画像差し替えの不具合とは判断しない。通常新規開始からの接続確認でありqueryによる地点指定ではない。一方、期待表示状態は原本JSONを読むElectron再生関数で構築しておりGodot画面との独立ピクセル比較ではない。

原本tutorial/normal/adventurer UIをまとめて実行し2/3成功。マチルダ通常戦は結果再開・勝利3round・精算・原本勝利sequenceまでのassertを通過後、test75行の勝利後本文待機でtimeout。保存cursorを読むテストと、保存後React描画のタイミング差が原因候補だがまだ未確定。全編通し検証完了とはしない。ゲームコード・テスト期待値の修正なし。

追加判明: show_characterのcross_fade指定636件が原本JSONにあるがOriginalPortraitはtransition/transition_durationを処理していない。背景フェードとは別の人物画像切替演出の未実装として記録する。

normal UIを単独実行しても同じtest75行でtimeout。並列実行だけが原因ではない。隔離saveを勝利後sequence開始に置く別診断で、表示cursor3/5の原本文を待ち「次へ」→「次の章へ」と操作したところstage1:4へ到達成功。勝利後再生から第1章への接続自体は動くが、戦闘終了からの元テスト経路との差は未確定。テストの保存cursor/表示待機競合が最有力候補。現時点でゲーム側正常やテストだけの不具合とは断定しない。診断save以外は変更せずfinallyで終了削除。

## 修正と検証

### 第4・5章ミニゲームの原本接続（2026-10-12）

第4章は強度別選択、第5章は質問ごとの選択と勝利時の物証演出をGodotメソッド実行で取得し、通常の原本ストーリーbattle命令から接続した。保存は行動履歴の再実行で検証し、終了まで所持情報を変更しない。現在値0〜130と成功-40/失敗+5の262遷移を各章で取得し、ゾーン変更時の原文を実値に合わせる。黄開始49・赤開始100は原本実処理に基づく。

第5章は赤6問/strong6問、全72応答、未使用質問循環、4MISSから3提示を保持。独自のセリフや章連結は追加していない。ミニゲーム画面の吹き出し形状、揺れ・閃光・テロップ等を含む全Godot画面ピクセル/時系列一致はまだ証明していない。ゲージ数値と原文の検証を全演出一致と言い換えない。

全UI回帰中に内包build付きintegration scriptを実行してしまい、Matilda journeyがタイムアウトした。ゲーム変更なしの固定build単独再実行1PASS150.83秒。これは失敗原因の完全な特定ではなく、全UI再実行成功の代替証拠でもない。今後は明示build後、内包buildなしintegration runner、最後にUIの順で検証する。

### 2026-10-12：カード配置エディタの原本接続（部分完了）

カードボックス／デッキのプレビューは原本チュートリアル画面と共用し、原本コマンドでdeck待機まで進めた状態を表示する。Godot BattleSceneの初期位置（FHD：box 1497.6/58、deck 0/930）を保持し、既存保存形式の基準値からの移動差分だけを適用する。配置ファイル内の旧セリフを原本再生に使わない。再ビルド・2回起動による反映、セーブバイト不変、バックアップ・保存失敗保全のUI2件成功。人物配置2種と勝負カードのプレビューは旧画面のままであり、残る移行対象として明記する。全編の独立Godot画面比較は未完。

### フェード修正の最新結果

- 全Unit251/251、Integration29/29、typecheck、Game/Editor build成功。モーション端点とslotの復元/置換を含む。
- フレームを早く進める条件で人物fade開始の欠落を再現。各命令のReact commitを確認してから次へ進む方式に変更し、演出完了は待たず原本の非同期演出を維持。画面破棄時は待機中のcommitも解除する。
- Godotと同じleft/right/centerの3枠でrendererを維持し、別人物への同slot置換を実装。同じ背景の再指定もcommand単位でfadeを開始する。背景は新画像0→1の後、旧画像1→0。人物は旧画像を減衰させず保持。
- snapshotへ現在のWeb Animationのopacity/translate/transform/left/topをコピー。途中のcrossfadeの取消前に状態を取得する順序へ修正。原本の300msフェード途中、opacity0.5を保持するRED→GREENを確認するテストを追加。
- 対象UIは通常/高速フレーム各10回ずつの人物・背景、同背景、別人物同slot、途中画面破棄、途中再切替を検証。snapshotの画像実体・透明度・終了後除去も確認する。これは636指定全件やGodot全画面の独立ピクセル一致を証明したものではない。
- 最新の対象UIは15/15成功（フェード6ケースと既存原本経路9ケース）。途中状態の保持も含めて最終ビルドで検証。単独SELF-REVIEWで取消順序の問題を再現・修正済み。全統合diff/gateや独立レビューは未実施。
- 回帰検証中にJin敗北後本文待機が1回timeout（テスト107行）。無変更の単独再実行2/2、診断実行2/2、3反復診断6/6は成功。原因未確定。Jinのゲームコード/テスト期待値を修正していない。
- 本番save保全、commit/Pushなし。Publish可否は未完のまま。

normal UIの待機を、原本command順で表示cursorと完全な本文を確認する形に修正。さらに表示時点の保存cursorも一致確認。UI1/1成功し第1章まで遷移。セリフ・報酬・勝敗・再開の期待値は不変。

モーションのSINE入口減速/出口加速、CUBIC縮小・拡大、別linear alphaを61点標本化するoriginal-motion.tsを追加してOriginalPortraitへ接続。上/下の別名up/down、center登場の既定topも反映。未実装REDの後、Unit2/3成功。残1件はcos(pi/2)の浮動小数誤差で退場終点200pxが199.99999999999997pxとなり厳密assert失敗。端点のprogressを明示的に1に固定する修正が必要。typecheck成功。追加修正・renderer build/UI回帰はまだ行っていない。cross_fadeと背景fadeも未完。
