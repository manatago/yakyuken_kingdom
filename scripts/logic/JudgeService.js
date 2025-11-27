/**
 * @file JudgeService.js
 * @description じゃんけん勝敗判定ロジック（純粋関数）
 */

/**
 * @typedef {import('../data/GameConfig.js').CardType} CardType
 */

/**
 * @typedef {import('../data/GameState.js').Card} Card
 */

/**
 * @typedef {import('../data/GameState.js').RoundResult} RoundResult
 */

/**
 * JudgeService - じゃんけん勝敗判定
 */
export const JudgeService = {
  /**
   * じゃんけんのラウンド結果を判定する
   *
   * 判定ロジック:
   * 1. 引き分けチェック（同じカード種類）
   * 2. プレイヤー勝利条件チェック
   *    - グー > チョキ
   *    - チョキ > パー
   *    - パー > グー
   * 3. 上記以外はコンピュータ勝利
   *
   * @param {Card} card1 - プレイヤーのカード
   * @param {Card} card2 - コンピュータのカード
   * @returns {RoundResult} 判定結果
   */
  judgeRound(card1, card2) {
    // 引き分けチェック
    if (card1.type === card2.type) {
      return 'DRAW';
    }

    // プレイヤー勝利条件チェック
    const playerWins =
      (card1.type === 'ROCK' && card2.type === 'SCISSORS') ||
      (card1.type === 'SCISSORS' && card2.type === 'PAPER') ||
      (card1.type === 'PAPER' && card2.type === 'ROCK');

    if (playerWins) {
      return 'PLAYER_WIN';
    }

    // それ以外はコンピュータ勝利
    return 'COMPUTER_WIN';
  }
};
