/**
 * @file UIRenderer.js
 * @description メイン画面の描画とGameState購読
 */

import { CardComponent } from './CardComponent.js';
import { DeckComponent } from './DeckComponent.js';
import { CoinComponent } from './CoinComponent.js';

/**
 * @typedef {import('../data/GameState.js').GameStateStore} GameStateStore
 */

/**
 * UIRendererを作成
 * @param {GameStateStore} gameState - ゲーム状態ストア
 * @param {Object} gameController - ゲームコントローラー
 * @returns {Object} UIRendererインスタンス
 */
export function createUIRenderer(gameState, gameController) {
  // DOM要素への参照
  const elements = {
    handArea: document.getElementById('hand-area'),
    deckContainer: document.getElementById('deck-container'),
    deckCount: document.getElementById('deck-count'),
    playerCoinCount: document.getElementById('player-coin-count'),
    opponentCoinCount: document.getElementById('opponent-coin-count'),
    opponentHandCount: document.getElementById('opponent-hand-count'),
    battleArea: document.getElementById('battle-area'),
    playerBattleCard: document.getElementById('player-battle-card'),
    opponentBattleCard: document.getElementById('opponent-battle-card'),
    resultMessage: document.getElementById('result-message'),
    resetButton: document.getElementById('reset-button')
  };

  /**
   * 全UI更新
   * @param {Object} state - ゲーム状態
   */
  function updateUI(state) {
    updateHand(state);
    updateDeck(state);
    updateCoins(state);
    updateBattleCards(state);
    updateResult(state);
    updateOpponentInfo(state);
  }

  /**
   * 手札を更新
   */
  function updateHand(state) {
    const humanPlayer = state.players.find(p => p.isHuman);
    if (!humanPlayer) return;

    const isSelectable = state.phase === 'READY';

    CardComponent.renderMultiple(
      humanPlayer.hand,
      elements.handArea,
      isSelectable ? handleCardSelect : null
    );
  }

  /**
   * デッキを更新
   */
  function updateDeck(state) {
    DeckComponent.render(state.discard, elements.deckContainer);
    elements.deckCount.textContent = state.discard.length.toString();
  }

  /**
   * コインを更新
   */
  function updateCoins(state) {
    const humanPlayer = state.players.find(p => p.isHuman);
    const aiPlayer = state.players.find(p => !p.isHuman);

    if (humanPlayer) {
      CoinComponent.render(humanPlayer.coins, elements.playerCoinCount);
    }

    if (aiPlayer) {
      CoinComponent.render(aiPlayer.coins, elements.opponentCoinCount);
    }
  }

  /**
   * 対戦カードを更新
   */
  function updateBattleCards(state) {
    if (state.phase === 'JUDGING' || state.phase === 'ROUND_RESULT') {
      elements.battleArea.classList.add('battle-area--active');

      const humanPlayer = state.players.find(p => p.isHuman);
      const aiPlayer = state.players.find(p => !p.isHuman);

      const playerCard = state.selectedCards.get(humanPlayer.id);
      const opponentCard = state.selectedCards.get(aiPlayer.id);

      // プレイヤーのカードを即座に表示（isSelectable=trueでdisabledクラスを付けない）
      if (playerCard) {
        const playerCardElement = CardComponent.render(playerCard, true, false, null);
        playerCardElement.classList.add('battle-card__card');
        playerCardElement.style.cursor = 'default';
        elements.playerBattleCard.innerHTML = '';
        elements.playerBattleCard.appendChild(playerCardElement);
      }

      // 相手のカードは遅延表示（800ms後）
      if (state.phase === 'JUDGING' && opponentCard) {
        elements.opponentBattleCard.innerHTML = '';
        setTimeout(() => {
          const opponentCardElement = CardComponent.render(opponentCard, true, false, null);
          opponentCardElement.classList.add('battle-card__card');
          opponentCardElement.style.cursor = 'default';
          elements.opponentBattleCard.innerHTML = '';
          elements.opponentBattleCard.appendChild(opponentCardElement);
        }, 800);
      } else if (state.phase === 'ROUND_RESULT' && opponentCard) {
        // ROUND_RESULTフェーズでは即座に表示
        const opponentCardElement = CardComponent.render(opponentCard, true, false, null);
        opponentCardElement.classList.add('battle-card__card');
        opponentCardElement.style.cursor = 'default';
        elements.opponentBattleCard.innerHTML = '';
        elements.opponentBattleCard.appendChild(opponentCardElement);
      }
    } else {
      elements.battleArea.classList.remove('battle-area--active');
      elements.playerBattleCard.innerHTML = '';
      elements.opponentBattleCard.innerHTML = '';
    }
  }

  /**
   * 対戦結果を更新
   */
  function updateResult(state) {
    elements.resultMessage.className = 'result-message';

    if (state.phase === 'ROUND_RESULT' && state.lastResult) {
      const resultText = {
        PLAYER_WIN: '🎉 あなたの勝ち！',
        COMPUTER_WIN: '😢 コンピュータの勝ち！',
        DRAW: '🤝 引き分け'
      };

      elements.resultMessage.textContent = resultText[state.lastResult];
      elements.resultMessage.classList.add(
        state.lastResult === 'PLAYER_WIN' ? 'result-message--player-win' :
        state.lastResult === 'COMPUTER_WIN' ? 'result-message--computer-win' : 'result-message--draw'
      );

      // ゲーム終了チェック
      const gameOver = gameController.checkGameOver();
      if (gameOver) {
        showGameOver(gameOver);
      } else {
        // 3秒後に次ラウンド準備
        setTimeout(() => {
          gameController.prepareNextRound();
        }, 3000);
      }
    } else if (state.phase === 'GAME_OVER') {
      // ゲーム終了状態維持
    } else {
      elements.resultMessage.textContent = '';
    }
  }

  /**
   * 相手情報を更新
   */
  function updateOpponentInfo(state) {
    const aiPlayer = state.players.find(p => !p.isHuman);
    if (aiPlayer) {
      elements.opponentHandCount.textContent = aiPlayer.hand.length.toString();
    }
  }

  /**
   * ゲーム終了画面を表示
   */
  function showGameOver(gameOverResult) {
    gameState.setState({ phase: 'GAME_OVER' });

    let message;
    if (gameOverResult.winner === 'DRAW') {
      message = '引き分けです！';
    } else {
      const humanPlayer = gameState.getState().players.find(p => p.isHuman);
      const isPlayerWin = gameOverResult.winner === humanPlayer.id;
      message = isPlayerWin ? '🎉 あなたの勝利です！' : '😢 敗北しました...';
    }

    const reasonText = gameOverResult.reason === 'COINS_DEPLETED'
      ? '服が0になりました'
      : '全ての手札を使い切りました';

    elements.resultMessage.innerHTML = `
      <div class="game-over">
        <div class="game-over__title">${message}</div>
        <div class="game-over__reason">${reasonText}</div>
      </div>
    `;
  }

  /**
   * カード選択ハンドラー
   */
  function handleCardSelect(card) {
    const state = gameState.getState();
    const humanPlayer = state.players.find(p => p.isHuman);

    const result = gameController.selectCard(humanPlayer.id, card);

    if (!result.ok) {
      console.error('カード選択エラー:', result.error);
    }
  }

  /**
   * リセットボタンハンドラー
   */
  function handleReset() {
    gameController.reset();
  }

  /**
   * 初期化
   */
  function initialize() {
    // リセットボタンのイベント登録
    elements.resetButton.addEventListener('click', handleReset);

    // GameStateの購読
    gameState.subscribe(updateUI);

    // 初回描画
    const state = gameState.getState();
    updateUI(state);
  }

  return {
    initialize
  };
}
