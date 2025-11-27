/**
 * @file CoinComponent.js
 * @description コイン表示コンポーネント
 */

/**
 * CoinComponent - コイン表示コンポーネント
 */
export const CoinComponent = {
  /**
   * コイン数を描画
   * @param {number} coins - コイン数
   * @param {HTMLElement} element - 表示要素
   */
  render(coins, element) {
    element.textContent = coins.toString();

    // コイン数に応じたクラス
    element.className = 'coin-count';
    if (coins === 0) {
      element.classList.add('coin-count--zero');
    } else if (coins <= 1) {
      element.classList.add('coin-count--low');
    }
  }
};
