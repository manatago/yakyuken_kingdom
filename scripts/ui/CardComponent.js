/**
 * @file CardComponent.js
 * @description カード表示コンポーネント
 */

/**
 * @typedef {import('../data/GameState.js').Card} Card
 */

/**
 * カード種類の表示名
 */
const CARD_DISPLAY_NAMES = {
  ROCK: 'グー',
  PAPER: 'パー',
  SCISSORS: 'チョキ'
};

/**
 * カード種類の絵文字
 */
const CARD_EMOJIS = {
  ROCK: '✊',
  PAPER: '✋',
  SCISSORS: '✌️'
};

/**
 * CardComponent - カード表示コンポーネント
 */
export const CardComponent = {
  /**
   * カードのDOM要素を作成
   * @param {Card} card - カードデータ
   * @param {boolean} isSelectable - 選択可能かどうか
   * @param {boolean} isSelected - 選択されているかどうか
   * @param {function(Card): void} onSelect - 選択時のコールバック
   * @returns {HTMLElement} カードDOM要素
   */
  render(card, isSelectable = true, isSelected = false, onSelect = null) {
    const button = document.createElement('button');
    button.className = 'card';
    button.dataset.cardId = card.id;
    button.dataset.cardType = card.type;

    // 選択状態のクラス
    if (isSelected) {
      button.classList.add('card--selected');
    }

    // 選択不可の場合
    if (!isSelectable) {
      button.disabled = true;
      button.classList.add('card--disabled');
    }

    // カード内容
    const emoji = document.createElement('div');
    emoji.className = 'card__emoji';
    emoji.textContent = CARD_EMOJIS[card.type];

    const label = document.createElement('div');
    label.className = 'card__label';
    label.textContent = CARD_DISPLAY_NAMES[card.type];

    button.appendChild(emoji);
    button.appendChild(label);

    // クリックイベント
    if (isSelectable && onSelect) {
      button.addEventListener('click', () => onSelect(card));
    }

    return button;
  },

  /**
   * 複数のカードを描画
   * @param {Card[]} cards - カード配列
   * @param {HTMLElement} container - コンテナ要素
   * @param {function(Card): void} onSelect - 選択時のコールバック
   */
  renderMultiple(cards, container, onSelect = null) {
    // コンテナをクリア
    container.innerHTML = '';

    // 各カードを描画
    cards.forEach(card => {
      const cardElement = this.render(card, true, false, onSelect);
      container.appendChild(cardElement);
    });
  }
};
