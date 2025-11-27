/**
 * @file GameController.js
 * @description ゲーム全体のフロー制御と状態遷移管理
 */

import { JudgeService } from './JudgeService.js';
import { AIPlayer } from './AIPlayer.js';

/**
 * @typedef {import('../data/GameState.js').Card} Card
 */

/**
 * @typedef {import('../data/GameState.js').GameStateStore} GameStateStore
 */

/**
 * @typedef {import('../data/GameConfig.js').GameConfig} GameConfig
 */

/**
 * @typedef {Object} InvalidCardError
 * @property {'CARD_NOT_IN_HAND' | 'NOT_PLAYER_TURN' | 'INVALID_PHASE'} code
 * @property {string} message
 */

/**
 * @typedef {Object} GameOverResult
 * @property {string} winner - プレイヤーID or 'DRAW'
 * @property {'COINS_DEPLETED' | 'HAND_EXHAUSTED'} reason
 * @property {Map<string, number>} finalScores - playerId -> coins
 */

/**
 * @template T, E
 * @typedef {{ok: true, value: T} | {ok: false, error: E}} Result
 */

/**
 * カードIDを生成
 */
let cardIdCounter = 0;
function generateCardId() {
  return `card-${++cardIdCounter}`;
}

/**
 * 手札を作成（グー2枚、チョキ2枚、パー2枚）
 * @returns {Card[]} 手札配列
 */
function createHand() {
  const hand = [];
  const cardTypes = ['ROCK', 'PAPER', 'SCISSORS'];

  cardTypes.forEach(type => {
    for (let i = 0; i < 2; i++) {
      hand.push({
        type,
        id: generateCardId()
      });
    }
  });

  return hand;
}

/**
 * GameControllerを作成
 * @param {GameStateStore} gameState - ゲーム状態ストア
 * @param {GameConfig} config - ゲーム設定
 * @returns {Object} GameControllerインスタンス
 */
export function createGameController(gameState, config) {
  /**
   * ゲームを初期化
   */
  function initialize() {
    const state = gameState.getState();

    // 各プレイヤーに手札とコインを配布
    const updatedPlayers = state.players.map(player => ({
      ...player,
      hand: createHand(),
      coins: config.initialCoins
    }));

    // 状態を更新
    gameState.setState({
      phase: 'READY',
      players: updatedPlayers,
      discard: [],
      currentRound: 1,
      lastResult: null,
      selectedCards: new Map()
    });
  }

  /**
   * カードを選択
   * @param {string} playerId - プレイヤーID
   * @param {Card} card - 選択するカード
   * @returns {Result<void, InvalidCardError>} 結果
   */
  function selectCard(playerId, card) {
    const state = gameState.getState();

    // プレイヤーを取得
    const player = state.players.find(p => p.id === playerId);
    if (!player) {
      return {
        ok: false,
        error: {
          code: 'NOT_PLAYER_TURN',
          message: 'Player not found'
        }
      };
    }

    // カードが手札にあるかチェック
    const cardInHand = player.hand.some(c => c.id === card.id);
    if (!cardInHand) {
      return {
        ok: false,
        error: {
          code: 'CARD_NOT_IN_HAND',
          message: 'Card not in player hand'
        }
      };
    }

    // 選択カードを記録
    const selectedCards = new Map(state.selectedCards);
    selectedCards.set(playerId, card);

    gameState.setState({ selectedCards });

    // AI自動選択
    const aiPlayer = state.players.find(p => !p.isHuman);
    const aiCard = AIPlayer.selectCard(aiPlayer.id, gameState);
    selectedCards.set(aiPlayer.id, aiCard);

    // JUDGINGフェーズに遷移
    gameState.setState({
      phase: 'JUDGING',
      selectedCards
    });

    // 判定実行
    executeJudgment();

    return { ok: true, value: undefined };
  }

  /**
   * 判定を実行し、結果を反映
   */
  function executeJudgment() {
    const state = gameState.getState();
    const players = state.players;
    const humanPlayer = players.find(p => p.isHuman);
    const aiPlayer = players.find(p => !p.isHuman);

    const humanCard = state.selectedCards.get(humanPlayer.id);
    const aiCard = state.selectedCards.get(aiPlayer.id);

    // 勝敗判定
    const result = JudgeService.judgeRound(humanCard, aiCard);

    // 服の数更新（負けた側のみ減る、勝っても増えない）
    let updatedPlayers = [...players];
    if (result === 'PLAYER_WIN') {
      updatedPlayers = updatedPlayers.map(p => {
        if (!p.isHuman) {
          return { ...p, coins: Math.max(0, p.coins - 1) };
        }
        return p;
      });
    } else if (result === 'COMPUTER_WIN') {
      updatedPlayers = updatedPlayers.map(p => {
        if (p.isHuman) {
          return { ...p, coins: Math.max(0, p.coins - 1) };
        }
        return p;
      });
    }

    // 使用済カードを手札から削除してデッキに追加
    const discard = [...state.discard, humanCard, aiCard];
    updatedPlayers = updatedPlayers.map(p => {
      const selectedCard = state.selectedCards.get(p.id);
      return {
        ...p,
        hand: p.hand.filter(c => c.id !== selectedCard.id)
      };
    });

    // 演出のため1.5秒後に結果フェーズに遷移
    setTimeout(() => {
      gameState.setState({
        phase: 'ROUND_RESULT',
        players: updatedPlayers,
        discard,
        lastResult: result
      });
    }, 1500);
  }

  /**
   * ゲーム終了判定
   * @returns {GameOverResult | null} ゲーム終了結果、継続中ならnull
   */
  function checkGameOver() {
    const state = gameState.getState();
    const players = state.players;

    // コイン枯渇チェック
    const humanPlayer = players.find(p => p.isHuman);
    const aiPlayer = players.find(p => !p.isHuman);

    if (humanPlayer.coins === 0) {
      return {
        winner: aiPlayer.id,
        reason: 'COINS_DEPLETED',
        finalScores: new Map([
          [humanPlayer.id, humanPlayer.coins],
          [aiPlayer.id, aiPlayer.coins]
        ])
      };
    }

    if (aiPlayer.coins === 0) {
      return {
        winner: humanPlayer.id,
        reason: 'COINS_DEPLETED',
        finalScores: new Map([
          [humanPlayer.id, humanPlayer.coins],
          [aiPlayer.id, aiPlayer.coins]
        ])
      };
    }

    // 全手札使用済チェック
    const allHandsEmpty = players.every(p => p.hand.length === 0);
    if (allHandsEmpty) {
      let winner;
      if (humanPlayer.coins > aiPlayer.coins) {
        winner = humanPlayer.id;
      } else if (aiPlayer.coins > humanPlayer.coins) {
        winner = aiPlayer.id;
      } else {
        winner = 'DRAW';
      }

      return {
        winner,
        reason: 'HAND_EXHAUSTED',
        finalScores: new Map([
          [humanPlayer.id, humanPlayer.coins],
          [aiPlayer.id, aiPlayer.coins]
        ])
      };
    }

    return null;
  }

  /**
   * ゲームをリセット
   */
  function reset() {
    // カウンターリセット
    cardIdCounter = 0;

    // 初期化と同じ処理
    initialize();
  }

  /**
   * 次ラウンドの準備
   */
  function prepareNextRound() {
    gameState.setState({
      phase: 'READY',
      selectedCards: new Map()
    });
  }

  return {
    initialize,
    selectCard,
    checkGameOver,
    reset,
    prepareNextRound
  };
}
