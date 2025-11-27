/**
 * @file GameState.js
 * @description ゲーム状態のリアクティブストア（Proxy-based）
 */

/**
 * @typedef {'INITIALIZED' | 'READY' | 'PLAYER_SELECTING' | 'JUDGING' | 'ROUND_RESULT' | 'GAME_OVER'} GamePhase
 * ゲームフェーズ
 */

/**
 * @typedef {'PLAYER_WIN' | 'COMPUTER_WIN' | 'DRAW'} RoundResult
 * ラウンド結果
 */

/**
 * @typedef {import('./GameConfig.js').CardType} CardType
 */

/**
 * @typedef {Object} Card
 * @property {CardType} type - カード種類
 * @property {string} id - ユニークID
 */

/**
 * @typedef {Object} Player
 * @property {string} id - プレイヤーID
 * @property {string} name - プレイヤー名
 * @property {Card[]} hand - 手札
 * @property {number} coins - コイン数
 * @property {boolean} isHuman - 人間プレイヤーかAIか
 */

/**
 * @typedef {Object} GameStateData
 * @property {GamePhase} phase - 現在のゲームフェーズ
 * @property {Player[]} players - プレイヤー配列
 * @property {Card[]} discard - 使用済カード（デッキ）
 * @property {number} currentRound - 現在のラウンド数
 * @property {RoundResult | null} lastResult - 最後のラウンド結果
 * @property {Map<string, Card>} selectedCards - 選択されたカード (playerId -> Card)
 */

/**
 * @typedef {Object} GameStateStore
 * @property {function(): Readonly<GameStateData>} getState - 現在の状態を取得
 * @property {function(Partial<GameStateData>): void} setState - 状態を更新
 * @property {function(function(GameStateData): void): function(): void} subscribe - 状態変更を購読
 */

/**
 * プレイヤーIDを生成
 * @param {number} index - プレイヤーインデックス
 * @returns {string} プレイヤーID
 */
function generatePlayerId(index) {
  return `player-${index}`;
}

/**
 * プレイヤーを作成
 * @param {number} index - プレイヤーインデックス
 * @param {number} initialCoins - 初期コイン数
 * @returns {Player} プレイヤーオブジェクト
 */
function createPlayer(index, initialCoins) {
  return {
    id: generatePlayerId(index),
    name: index === 0 ? 'プレイヤー' : 'コンピュータ',
    hand: [],
    coins: initialCoins,
    isHuman: index === 0
  };
}

/**
 * 初期状態を作成
 * @param {import('./GameConfig.js').GameConfig} config - ゲーム設定
 * @returns {GameStateData} 初期状態
 */
function createInitialState(config) {
  const players = [];
  for (let i = 0; i < config.playerCount; i++) {
    players.push(createPlayer(i, config.initialCoins));
  }

  return {
    phase: 'INITIALIZED',
    players,
    discard: [],
    currentRound: 0,
    lastResult: null,
    selectedCards: new Map()
  };
}

/**
 * GameStateストアを作成
 * @param {import('./GameConfig.js').GameConfig} config - ゲーム設定
 * @returns {GameStateStore} ゲーム状態ストア
 */
export function createGameState(config) {
  // 内部状態
  let state = createInitialState(config);

  // リスナー配列
  const listeners = new Set();

  /**
   * 全リスナーに通知
   */
  function notifyListeners() {
    const readonlyState = Object.freeze({ ...state });
    listeners.forEach(listener => listener(readonlyState));
  }

  // ストアAPI
  return {
    /**
     * 現在の状態を取得（読み取り専用）
     * @returns {Readonly<GameStateData>} 現在の状態
     */
    getState() {
      // 読み取り専用の凍結オブジェクトを返す
      return Object.freeze({ ...state });
    },

    /**
     * 状態を更新
     * @param {Partial<GameStateData>} partial - 更新する部分状態
     */
    setState(partial) {
      // 部分的な更新をマージ
      state = {
        ...state,
        ...partial
      };

      // リスナーに通知
      notifyListeners();
    },

    /**
     * 状態変更を購読
     * @param {function(GameStateData): void} listener - リスナー関数
     * @returns {function(): void} 購読解除関数
     */
    subscribe(listener) {
      listeners.add(listener);

      // 購読解除関数を返す
      return () => {
        listeners.delete(listener);
      };
    }
  };
}
