# Research & Design Decisions

---
**Purpose**: カードベースじゃんけんゲームの技術調査と設計決定の記録

**Usage**:
- ディスカバリーフェーズの調査活動と結果をログ
- design.mdに記載するには詳細すぎる設計決定のトレードオフを文書化
- 将来の監査や再利用のための参照情報と証拠を提供
---

## Summary
- **Feature**: `janken-game`
- **Discovery Scope**: New Feature (グリーンフィールド)
- **Key Findings**:
  - Vanilla JavaScriptでのモジュラー設計が拡張性要件に最適
  - Tauri移行を考慮したフレームワーク非依存のアーキテクチャが必要
  - 状態管理は軽量なReactiveパターンで実装可能

## Research Log

### Browser Card Game Architecture Patterns

**Context**: ブラウザベースのカードゲームに適したアーキテクチャパターンの調査

**Sources Consulted**:
- GitHub Topics: TypeScript card game projects
- cards-ts framework: TypeScript card game framework
- Phaser 3, PixiJS: TypeScript game engines

**Findings**:
- Drawable objectパターン: Draw()メソッドを持つオブジェクトをコンテナオブジェクトで管理
- Component-based architecture: カードゲームではopenCards、clearedCards、movesなどの状態を管理
- Entity Component System (ECS): モジュラーゲーム開発に適したアーキテクチャ
- TypeScript採用が主流: 型安全性とメンテナンス性向上
- Vite: 2025年の開発ツールトレンド、高速でシンプル

**Implications**:
- MVC/MVP パターンよりもComponent-based architectureが適している
- 型安全性のためTypeScriptを推奨するが、MVP要件を考慮しVanilla JSも選択肢
- 描画ロジックと状態管理の分離が重要

### State Management Approaches

**Context**: カードゲームの状態管理戦略の調査

**Sources Consulted**:
- React card game tutorials
- Vue.js state management documentation
- Vanilla JavaScript state management patterns (2026 trends)

**Findings**:
- React: useState/useReducer + Context API
- Vue: reactive() + Vue.set for reactive properties
- Vanilla JS: Proxy objectを使用した軽量リアクティブシステム
- 状態管理ライブラリは大規模アプリ向け、小規模ゲームには過剰

**Implications**:
- MVPではVanilla JSのシンプルな状態管理で十分
- Proxy-based reactive stateで軽量かつ拡張可能
- フレームワーク非依存でTauri移行が容易

### Rock Paper Scissors Game Logic

**Context**: じゃんけん勝敗判定アルゴリズムの実装方式

**Sources Consulted**:
- GeeksforGeeks: Winner determination algorithms
- Rosetta Code: Multiple language implementations
- Algorithm optimization techniques

**Findings**:
- 基本的なif-else approach: 全組み合わせをチェック
- 数学的アプローチ: 整数マッピング (0: グー, 1: チョキ, 2: パー) + モジュロ演算
- ビット操作アプローチ: 高速だが可読性低下
- 引き分けチェック優先で分岐削減可能

**Implications**:
- 可読性重視でif-else approach採用
- 引き分けチェック → プレイヤー勝利条件の順で判定
- 3種類のカードのみなので最適化は不要

### Tauri Migration Strategy

**Context**: Web版からTauri desktop版への移行戦略

**Sources Consulted**:
- Tauri 2.0 official documentation
- Migration guides and discussions
- Framework compatibility information

**Findings**:
- Tauriはフレームワーク非依存: React、Vue、Vanilla JS全対応
- 既存Webアプリの変更不要でデスクトップアプリ化可能
- JavaScript/TypeScript APIでクリップボード、ダイアログ、イベント処理
- バックエンドロジックはRust、フロントエンドは既存Web技術
- npm install @tauri-apps/cli → npx tauri init で既存プロジェクトに追加

**Implications**:
- MVP実装はフレームワーク非依存のVanilla JS推奨
- HTMLファイル + JS/CSS の静的構成でTauri移行が最も容易
- distフォルダ構成をTauri仕様に合わせる

### Modular & Configurable Game Architecture

**Context**: 拡張性要件(手札枚数、コイン数、多人数対戦)への対応

**Sources Consulted**:
- TypeScript game development guides
- Modular JavaScript architecture patterns
- Plugin architecture examples

**Findings**:
- Object/Component model: すべてのオブジェクトが同じクラスのインスタンス
- Constructor parameters: 設定可能な制御のためクラスコンストラクタにパラメータ追加
- Plugin architecture: 基本APIの拡張と親クラスのデフォルト値マージ
- ECS (Entity Component System): モジュラー開発に最適

**Implications**:
- GameConfigオブジェクトで設定を集約
- コンストラクタインジェクションで設定値を渡す
- プレイヤー数拡張のためPlayerクラス配列化

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| MVC (Model-View-Controller) | ビジネスロジック、表示、制御の分離 | 標準的な構造、理解しやすい | ゲームの状態遷移に複雑さ | Web開発では一般的だがゲームには過剰 |
| Component-based | UI/ゲーム要素をコンポーネント化 | 再利用性高、モジュラー | コンポーネント間通信の設計必要 | カードゲームに最適、調査で主流 |
| ECS (Entity Component System) | エンティティ、コンポーネント、システムの分離 | 高度な拡張性、パフォーマンス | 学習コスト高、MVP過剰 | 将来の多人数対戦拡張に有効 |
| State Machine Pattern | ゲームフェーズを状態遷移で管理 | 明確なフロー、デバッグ容易 | 状態数増加で複雑化 | ゲームフェーズ管理に部分適用 |

## Design Decisions

### Decision: アーキテクチャパターンの選択

**Context**:
- MVP要件: ブラウザ動作
- 拡張性要件: 手札枚数、コイン数、プレイヤー数の変更
- 将来要件: Tauri desktop版への移行

**Alternatives Considered**:
1. React/Vue フレームワーク — リアクティブなUI、大規模なバンドルサイズ
2. Vanilla JavaScript — 軽量、フレームワーク非依存、学習コスト低
3. TypeScript — 型安全性、エディタサポート、ビルドステップ追加

**Selected Approach**:
Component-based architecture with Vanilla JavaScript + optional TypeScript

**Rationale**:
- MVP要件にフレームワークは過剰
- Tauri移行でフレームワーク非依存が有利
- Component-basedで拡張性確保
- TypeScriptは将来的に導入可能(段階的移行)

**Trade-offs**:
- Benefits: 軽量、高速、Tauri移行容易、依存関係最小
- Compromises: リアクティブUIはProxyで自前実装、フレームワークエコシステム未使用

**Follow-up**:
- Proxy-based reactivityのパフォーマンステスト
- TypeScript導入のタイミング検討(MVP後)

### Decision: 状態管理戦略

**Context**:
ゲーム状態(手札、コイン、デッキ、ゲームフェーズ)の集中管理が必要

**Alternatives Considered**:
1. グローバル変数 — シンプルだが保守性低
2. Singleton GameStateクラス — カプセル化、変更追跡困難
3. Reactive Store pattern — Proxy使用、変更検知、購読可能

**Selected Approach**:
Reactive Store pattern with JavaScript Proxy

**Rationale**:
- 状態変更の自動UI更新
- 購読パターンでコンポーネント分離
- Vanilla JSで軽量実装可能

**Trade-offs**:
- Benefits: リアクティブ、デバッグ容易、拡張性
- Compromises: Proxy理解が必要、古いブラウザ非対応(IE11)

**Follow-up**:
- Proxy polyfillの必要性確認(ターゲットブラウザ依存)

### Decision: 勝敗判定アルゴリズム

**Context**:
じゃんけんの3すくみロジック実装

**Alternatives Considered**:
1. if-else全組み合わせ — 9パターン明示的チェック
2. 引き分け優先 + プレイヤー勝利条件 — 分岐削減
3. 数学的アプローチ — モジュロ演算

**Selected Approach**:
引き分け優先 + プレイヤー勝利条件チェック

**Rationale**:
- 可読性とメンテナンス性優先
- 3種類のカードのみで最適化不要
- テストケース作成が容易

**Trade-offs**:
- Benefits: 明確なロジック、拡張容易
- Compromises: 数学的手法より冗長

**Follow-up**:
- ユニットテストで全パターン検証

### Decision: UI実装方式

**Context**:
カード、デッキ、コインの視覚表示

**Alternatives Considered**:
1. HTML/CSS only — DOM操作、シンプル
2. Canvas API — 描画制御、アニメーション容易
3. SVG — スケーラブル、DOM統合

**Selected Approach**:
HTML/CSS with minimal DOM manipulation

**Rationale**:
- 静止画要件でCanvas不要
- CSS FlexboxでレイアウトOK
- DOM操作がシンプル

**Trade-offs**:
- Benefits: 実装速度、デバッグ容易、アクセシビリティ
- Compromises: 複雑なアニメーション困難(将来要件なし)

**Follow-up**:
- カードアニメーション要件発生時はCanvas検討

### Decision: モジュール構成

**Context**:
拡張性要件への対応(設定変更、多人数対戦)

**Alternatives Considered**:
1. Single file — 全コード1ファイル、管理困難
2. Feature-based modules — 機能別分割
3. Layer-based modules — レイヤ別分割(data, logic, view)

**Selected Approach**:
Hybrid: Layer-based + Feature modules

**Rationale**:
- GameConfig, GameState (data layer)
- GameLogic, JudgeService (logic layer)
- UIRenderer, CardComponent (view layer)
- 各レイヤで責務明確

**Trade-offs**:
- Benefits: 疎結合、テスト容易、並行開発可能
- Compromises: ファイル数増加

**Follow-up**:
- ES Modulesでインポート管理
- Viteでバンドル最適化

## Risks & Mitigations

- **Risk 1: Proxy互換性** — 古いブラウザでProxy未対応 → Mitigation: ターゲットブラウザ確認、必要ならpolyfill
- **Risk 2: Tauri移行の複雑さ** — Web版とdesktop版の差異 → Mitigation: 静的HTML構成維持、Tauri特有機能は条件分岐
- **Risk 3: 拡張時の設計変更** — 多人数対戦で大規模リファクタ → Mitigation: Player配列化、Turn管理抽象化を初期設計に含む
- **Risk 4: 状態同期バグ** — UI更新漏れ、状態不整合 → Mitigation: Reactive store + 自動UI更新、状態変更の単一経路

## References

- [Tauri 2.0 Documentation](https://tauri.app/) — Desktop app migration
- [JavaScript Proxy MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy) — Reactive state implementation
- [Component-based Game Architecture](https://codewords.recurse.com/issues/three/making-modular-videogames) — Modular design patterns
- [State Management in Vanilla JS: 2026 Trends](https://medium.com/@chirag.dave/state-management-in-vanilla-js-2026-trends-f9baed7599de) — Modern patterns
