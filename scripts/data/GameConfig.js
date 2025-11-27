/**
 * @file GameConfig.js
 * @description ゲーム設定値の管理（手札枚数、初期コイン数、プレイヤー数）
 */

/**
 * @typedef {'ROCK' | 'PAPER' | 'SCISSORS'} CardType
 * カード種類: グー、パー、チョキ
 */

/**
 * @typedef {Object} GameConfig
 * @property {number} handSize - 初期手札枚数（デフォルト: 6）
 * @property {number} initialCoins - 初期コイン数（デフォルト: 3）
 * @property {number} playerCount - プレイヤー数（デフォルト: 2、将来拡張用）
 * @property {CardType[]} cardTypes - カード種類（デフォルト: [ROCK, PAPER, SCISSORS]）
 */

/**
 * デフォルトのゲーム設定値
 * @type {Readonly<GameConfig>}
 */
const DEFAULT_CONFIG = Object.freeze({
  handSize: 6,
  initialCoins: 3,
  playerCount: 2,
  cardTypes: Object.freeze(['ROCK', 'PAPER', 'SCISSORS'])
});

/**
 * GameConfig - ゲーム設定の管理
 */
export const GameConfig = {
  /**
   * デフォルト設定を取得
   * @returns {Readonly<GameConfig>} デフォルトのゲーム設定
   */
  getDefault() {
    return DEFAULT_CONFIG;
  },

  /**
   * 設定値の検証
   * @param {Partial<GameConfig>} config - 検証する設定オブジェクト
   * @throws {Error} 設定値が無効な場合
   */
  validate(config) {
    if (config.handSize !== undefined && config.handSize <= 0) {
      throw new Error('handSize must be greater than 0');
    }

    if (config.initialCoins !== undefined && config.initialCoins <= 0) {
      throw new Error('initialCoins must be greater than 0');
    }

    if (config.playerCount !== undefined && config.playerCount < 2) {
      throw new Error('playerCount must be at least 2');
    }
  },

  /**
   * カスタム設定の作成
   * @param {Partial<GameConfig>} customConfig - カスタム設定（部分的でも可）
   * @returns {Readonly<GameConfig>} 検証済みの不変設定オブジェクト
   * @throws {Error} 設定値が無効な場合
   */
  create(customConfig = {}) {
    // 検証
    this.validate(customConfig);

    // デフォルトとマージ
    const mergedConfig = {
      ...DEFAULT_CONFIG,
      ...customConfig
    };

    // cardTypesは常にデフォルトを使用（将来の拡張用）
    mergedConfig.cardTypes = DEFAULT_CONFIG.cardTypes;

    // 不変オブジェクトとして返す
    return Object.freeze(mergedConfig);
  }
};
