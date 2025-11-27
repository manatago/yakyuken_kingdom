/**
 * @file AIPlayer.js
 * @description コンピュータプレイヤーのカード選択ロジック
 */

/**
 * @typedef {import('../data/GameState.js').Card} Card
 */

/**
 * @typedef {import('../data/GameState.js').GameStateStore} GameStateStore
 */

/**
 * AIPlayer - コンピュータプレイヤーの戦略
 */
export const AIPlayer = {
  /**
   * AIの手札からランダムにカードを選択する
   *
   * MVP版ではシンプルなランダム選択。
   * 将来的に戦略ロジック（相手の傾向分析、カード温存等）を追加可能。
   *
   * @param {string} playerId - AIプレイヤーのID
   * @param {GameStateStore} gameState - ゲーム状態ストア
   * @returns {Card} 選択されたカード
   * @throws {Error} プレイヤーが見つからない場合
   * @throws {Error} 手札が空の場合
   */
  selectCard(playerId, gameState) {
    const state = gameState.getState();

    // プレイヤーを取得
    const player = state.players.find(p => p.id === playerId);

    if (!player) {
      throw new Error('Player not found');
    }

    // 手札チェック
    if (player.hand.length === 0) {
      throw new Error('AI has no cards in hand');
    }

    // ランダムにインデックスを選択
    const randomIndex = Math.floor(Math.random() * player.hand.length);

    // カードを返す（状態は変更しない）
    return player.hand[randomIndex];
  }
};
