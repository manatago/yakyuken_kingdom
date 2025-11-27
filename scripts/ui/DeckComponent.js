/**
 * @file DeckComponent.js
 * @description デッキ（使用済カード）表示コンポーネント
 */

/**
 * @typedef {import('../data/GameState.js').Card} Card
 */

/**
 * カード種類の絵文字
 */
const CARD_EMOJIS = {
  ROCK: '✊',
  PAPER: '✋',
  SCISSORS: '✌️'
};

/**
 * カード種類の表示名
 */
const CARD_DISPLAY_NAMES = {
  ROCK: 'グー',
  PAPER: 'パー',
  SCISSORS: 'チョキ'
};

/**
 * DeckComponent - デッキ表示コンポーネント
 */
export const DeckComponent = {
  /**
   * デッキを描画（表向き）
   * @param {Card[]} discard - 使用済カード配列
   * @param {HTMLElement} container - コンテナ要素
   */
  render(discard, container) {
    // コンテナをクリア
    container.innerHTML = '';

    if (discard.length === 0) {
      // 空のデッキ表示
      const emptyMessage = document.createElement('div');
      emptyMessage.className = 'deck__empty';
      emptyMessage.textContent = 'まだカードがありません';
      container.appendChild(emptyMessage);
    } else {
      // 各カードを表示（表向き）
      discard.forEach(card => {
        const cardElement = document.createElement('div');
        cardElement.className = 'deck__card';
        cardElement.dataset.cardId = card.id;
        cardElement.dataset.cardType = card.type;

        // カード絵文字
        const emoji = document.createElement('div');
        emoji.className = 'deck__card-emoji';
        emoji.textContent = CARD_EMOJIS[card.type];

        // カードラベル
        const label = document.createElement('div');
        label.className = 'deck__card-label';
        label.textContent = CARD_DISPLAY_NAMES[card.type];

        cardElement.appendChild(emoji);
        cardElement.appendChild(label);
        container.appendChild(cardElement);
      });
    }
  }
};
