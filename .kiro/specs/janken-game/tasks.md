# Implementation Plan

## Overview
カードベースじゃんけんゲームのMVP実装タスク。Component-based + Layered architectureに従い、Data/Logic/Presentationの3層を順次構築し、最後にシステム統合とテストを実施します。

## Tasks

### 1. プロジェクトセットアップ
- [x] 1.1 (P) 基本ファイル構造とエントリーポイントの作成
  - index.htmlの作成（エントリーポイント、HTML5セマンティック構造）
  - scripts/ディレクトリ配下にdata/, logic/, ui/サブディレクトリを作成
  - styles/ディレクトリとmain.cssを作成
  - assets/images/ディレクトリを作成
  - _Requirements: 8.6, 10.4_

- [x] 1.2 (P) テスト環境のセットアップ
  - Vitestのインストールと設定（vitest.config.js）
  - tests/ディレクトリ構造の作成（unit/, integration/, e2e/）
  - Playwrightの設定（playwright.config.js）
  - package.jsonのテストスクリプト定義
  - _Requirements: 全要件（テスト容易性確保）_

### 2. データレイヤー実装
- [x] 2.1 (P) GameConfigの実装
  - ゲーム設定値の定義（手札枚数、初期コイン数、プレイヤー数、カード種類）
  - デフォルト値の設定（handSize: 6, initialCoins: 3, playerCount: 2）
  - 設定値の検証ロジック（handSize > 0, initialCoins > 0, playerCount >= 2）
  - JSDoc型アノテーション（GameConfig, CardType）
  - _Requirements: 1.2, 1.3, 10.1, 10.2, 10.3_

- [x] 2.2 GameStateのリアクティブストア実装
  - JavaScript Proxyベースのリアクティブストアの実装
  - 状態データ構造の定義（phase, players, discard, currentRound, lastResult, selectedCards）
  - subscribe/setState/getStateメソッドの実装
  - 状態変更の検知とリスナー通知機能
  - JSDoc型アノテーション（GamePhase, RoundResult, Card, Player, GameStateData, GameStateStore）
  - _Requirements: 1.4, 2.1, 2.2, 2.3, 5.1, 6.1, 6.4_

### 3. ロジックレイヤー実装（コアロジック）
- [x] 3.1 (P) JudgeServiceの実装
  - じゃんけん勝敗判定ロジック（引き分け → プレイヤー勝利条件チェック）
  - 全9パターンの判定（ROCK/PAPER/SCISSORS組み合わせ）
  - 純粋関数として実装（状態を持たない）
  - JSDoc型アノテーション（judgeRound関数）
  - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [x] 3.2 (P) AIPlayerの実装
  - コンピュータプレイヤーのランダムカード選択ロジック
  - 手札からのランダム選択アルゴリズム（Math.random()）
  - 手札存在チェックとバリデーション
  - JSDoc型アノテーション（selectCard関数）
  - _Requirements: 3.3, 3.4_

- [x] 3.3 GameControllerの実装
  - ゲーム初期化ロジック（initialize）
  - カード選択処理（selectCard）とバリデーション
  - ゲーム終了判定（checkGameOver）
  - ゲームリセット機能（reset）
  - 状態遷移管理（INITIALIZED → READY → PLAYER_SELECTING → JUDGING → ROUND_RESULT → GAME_OVER）
  - JudgeServiceとAIPlayerとの連携
  - JSDoc型アノテーション（GameControllerService, InvalidCardError, GameOverResult）
  - _Requirements: 1.1, 1.5, 3.1, 3.2, 3.5, 4.1, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 9.1, 9.2, 9.3, 9.4, 9.5_

### 4. ロジックレイヤー実装（コイン・デッキ管理）
- [x] 4.1 コイン管理ロジックの実装
  - 勝敗に応じたコイン増減処理
  - コイン数の下限チェック（0以上）
  - GameStateとの連携
  - _Requirements: 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_
  - **Note**: GameController.executeJudgment()に統合済み

- [x] 4.2 デッキ管理ロジックの実装
  - 使用済カードのデッキへの追加
  - デッキのリセット処理
  - GameStateとの連携
  - _Requirements: 6.2, 6.3, 6.5_
  - **Note**: GameController.executeJudgment()に統合済み

### 5. プレゼンテーションレイヤー実装（UIコンポーネント）
- [x] 5.1 (P) CardComponentの実装
  - カード種類に応じた表示（グー、チョキ、パー）
  - カード選択状態のハイライト表示
  - クリックイベントハンドラーの実装
  - CSS classによるスタイル切り替え
  - GameStateの手札状態購読
  - _Requirements: 2.2, 2.4, 3.2, 8.1, 8.7_

- [x] 5.2 (P) DeckComponentの実装
  - 使用済カード（デッキ）の表示
  - カード枚数の表示
  - CSS Gridレイアウトでの視覚表示
  - GameStateのdiscard配列購読
  - _Requirements: 6.1, 6.3, 6.4, 8.3_

- [x] 5.3 (P) CoinComponentの実装
  - プレイヤーとコンピュータのコイン数表示
  - コイン増減の視覚的表示
  - GameStateのplayers[].coins購読
  - _Requirements: 5.1, 8.4_

- [x] 5.4 UIRendererの実装
  - メイン画面のDOM構築
  - GameStateの購読とリアクティブUI更新
  - CardComponent、DeckComponent、CoinComponentの統合
  - ゲーム状態に応じたUI表示切り替え
  - コンピュータの上半身静止画表示
  - 対戦結果の表示
  - _Requirements: 4.7, 8.2, 8.3, 8.4, 8.5_

### 6. CSS実装
- [x] 6.1 レイアウトとスタイリング
  - Flexboxによるメインレイアウト（手札：画面下部、デッキ：中央、相手：上部）
  - カードのホバー・選択エフェクト（transform, box-shadow, transition）
  - レスポンシブデザイン対応
  - カラーテーマの定義（CSS変数）
  - BEM記法によるクラス命名
  - _Requirements: 8.1, 8.2, 8.3, 8.6, 8.7_

### 7. システム統合
- [x] 7.1 全レイヤーの統合
  - main.jsでのモジュール初期化とワイヤリング
  - GameController → GameState → UIRenderer の連携確認
  - イベントフローの検証（カード選択 → AI選択 → 判定 → コイン更新 → UI更新）
  - エラーハンドリングの統合（window.onerror, InvalidCardError処理）
  - _Requirements: 全要件（システム全体の統合）_

- [ ] 7.2 ブラウザ互換性の検証
  - ターゲットブラウザでの動作確認（Chrome 49+, Firefox 18+, Safari 10+, Edge 12+）
  - Proxy APIの動作確認
  - DOM操作とCSS表示の検証
  - _Requirements: 8.6, 10.4_

### 8. テスト実装
- [x] 8.1 (P) Unitテストの実装
  - JudgeService.judgeRound()の全9パターンテスト
  - AIPlayer.selectCard()のランダム選択テスト
  - GameController.selectCard()のバリデーションテスト
  - GameController.checkGameOver()の終了条件テスト
  - GameState.setState()の状態変更とリスナー通知テスト
  - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.6, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_
  - **Note**: GameConfig, GameState, JudgeService, AIPlayer, GameControllerのユニットテスト実装済み

- [ ] 8.2 (P) Integrationテストの実装
  - ゲーム初期化フローテスト（GameController → GameState → UI描画）
  - 1ラウンド完全フローテスト（カード選択 → 判定 → コイン更新 → デッキ追加）
  - ゲーム終了フローテスト（コイン0/手札0 → GAME_OVER）
  - リセットフローテスト（GameController.reset() → 初期状態復帰）
  - Reactive更新テスト（GameState変更 → UIリスナー発火）
  - _Requirements: 1.1, 1.5, 4.1, 5.2, 5.3, 5.4, 5.5, 6.2, 7.7, 9.5_
  - **Note**: 統合テストはユニットテストで部分的にカバー済み

- [x] 8.3 (P) E2Eテスト（Playwright）の実装
  - ゲーム起動からプレイまでのフローテスト
  - 複数ラウンドプレイとスコア正確性テスト
  - 勝利条件達成テスト（相手コイン0）
  - 敗北条件達成テスト（自分コイン0）
  - リセット機能テスト
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 9.1, 9.5_
  - **Note**: 基本的なE2Eテスト実装済み

## Requirements Coverage

全10要件（Requirement 1-10）の全サブ要件（1.1-10.4）がタスクに完全にマッピングされています。

### 要件マッピングサマリー
- **Requirement 1（ゲーム初期化）**: Tasks 2.1, 2.2, 3.3, 8.2
- **Requirement 2（手札管理）**: Tasks 2.2, 5.1
- **Requirement 3（カード選択）**: Tasks 3.2, 3.3, 5.1
- **Requirement 4（勝敗判定）**: Tasks 3.1, 3.3, 5.4, 8.1
- **Requirement 5（コイン管理）**: Tasks 2.2, 4.1, 5.3, 8.2
- **Requirement 6（デッキ管理）**: Tasks 2.2, 4.2, 5.2, 8.2
- **Requirement 7（ゲーム終了条件）**: Tasks 3.3, 8.1, 8.2, 8.3
- **Requirement 8（UI表示要件）**: Tasks 5.1, 5.2, 5.3, 5.4, 6.1, 7.2
- **Requirement 9（ゲームリセット）**: Tasks 3.3, 8.2, 8.3
- **Requirement 10（拡張性要件）**: Tasks 1.1, 2.1, 7.2

## Execution Notes

### 並列実行可能なタスク
以下のタスクは `(P)` マーカーで識別され、並列実行可能です：
- **セットアップ**: 1.1, 1.2（独立したセットアップ作業）
- **データレイヤー**: 2.1（GameConfigは独立）
- **ロジックレイヤー**: 3.1, 3.2（JudgeServiceとAIPlayerは依存関係なし）
- **UIコンポーネント**: 5.1, 5.2, 5.3（各コンポーネントは独立）
- **テスト**: 8.1, 8.2, 8.3（テスト種別ごとに独立）

### 依存関係
- タスク2.2（GameState）は2.1（GameConfig）に依存
- タスク3.3（GameController）は3.1, 3.2に依存
- タスク4.1, 4.2は2.2に依存
- タスク5.4（UIRenderer）は5.1, 5.2, 5.3に依存
- タスク7（システム統合）は全ての実装タスク完了後

### タスクサイズ目安
- セットアップタスク: 各1-2時間
- データレイヤー: 各2-3時間
- ロジックレイヤー: 各2-3時間
- UIコンポーネント: 各1-2時間
- CSS: 2-3時間
- システム統合: 2-3時間
- テスト: 各3-4時間

**総見積もり時間**: 約40-50時間（MVP完成まで）
