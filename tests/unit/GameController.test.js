/**
 * GameController ユニットテスト
 * TDD: RED phase - ゲームフロー制御をテスト
 */
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createGameController } from '../../scripts/logic/GameController.js';
import { createGameState } from '../../scripts/data/GameState.js';
import { GameConfig } from '../../scripts/data/GameConfig.js';

describe('GameController', () => {
  let gameController;
  let gameState;
  let config;

  beforeEach(() => {
    config = GameConfig.getDefault();
    gameState = createGameState(config);
    gameController = createGameController(gameState, config);
  });

  describe('initialize()', () => {
    it('ゲームを初期化しREADYフェーズに遷移する', () => {
      gameController.initialize();

      const state = gameState.getState();
      expect(state.phase).toBe('READY');
    });

    it('各プレイヤーに6枚の手札を配布する', () => {
      gameController.initialize();

      const state = gameState.getState();
      state.players.forEach(player => {
        expect(player.hand).toHaveLength(6);
      });
    });

    it('手札はグー2枚、チョキ2枚、パー2枚で構成される', () => {
      gameController.initialize();

      const state = gameState.getState();
      const hand = state.players[0].hand;

      const rockCount = hand.filter(c => c.type === 'ROCK').length;
      const paperCount = hand.filter(c => c.type === 'PAPER').length;
      const scissorsCount = hand.filter(c => c.type === 'SCISSORS').length;

      expect(rockCount).toBe(2);
      expect(paperCount).toBe(2);
      expect(scissorsCount).toBe(2);
    });

    it('各プレイヤーに3枚のコインを配布する', () => {
      gameController.initialize();

      const state = gameState.getState();
      state.players.forEach(player => {
        expect(player.coins).toBe(3);
      });
    });

    it('デッキを空にする', () => {
      gameController.initialize();

      const state = gameState.getState();
      expect(state.discard).toEqual([]);
    });

    it('currentRoundを1に設定する', () => {
      gameController.initialize();

      const state = gameState.getState();
      expect(state.currentRound).toBe(1);
    });
  });

  describe('selectCard()', () => {
    beforeEach(() => {
      gameController.initialize();
    });

    it('プレイヤーが有効なカードを選択できる', () => {
      const state = gameState.getState();
      const playerId = state.players[0].id;
      const card = state.players[0].hand[0];

      const result = gameController.selectCard(playerId, card);

      expect(result.ok).toBe(true);
    });

    it('カードを選択後、selectedCardsに記録される', () => {
      const state = gameState.getState();
      const playerId = state.players[0].id;
      const card = state.players[0].hand[0];

      gameController.selectCard(playerId, card);

      const updatedState = gameState.getState();
      expect(updatedState.selectedCards.has(playerId)).toBe(true);
      expect(updatedState.selectedCards.get(playerId)).toEqual(card);
    });

    it('手札にないカードを選択するとエラーを返す', () => {
      const state = gameState.getState();
      const playerId = state.players[0].id;
      const invalidCard = { type: 'ROCK', id: 'invalid-card-id' };

      const result = gameController.selectCard(playerId, invalidCard);

      expect(result.ok).toBe(false);
      expect(result.error.code).toBe('CARD_NOT_IN_HAND');
    });

    it('プレイヤーが選択後、AIが自動的にカードを選択する', () => {
      const state = gameState.getState();
      const playerId = state.players[0].id;
      const card = state.players[0].hand[0];

      gameController.selectCard(playerId, card);

      const updatedState = gameState.getState();
      const aiPlayerId = state.players[1].id;

      expect(updatedState.selectedCards.has(aiPlayerId)).toBe(true);
    });

    it('両者選択完了後、JUDGINGフェーズに遷移する', () => {
      const state = gameState.getState();
      const playerId = state.players[0].id;
      const card = state.players[0].hand[0];

      gameController.selectCard(playerId, card);

      const updatedState = gameState.getState();
      expect(updatedState.phase).toBe('JUDGING');
    });

    it('判定後、ROUND_RESULTフェーズに遷移する', () => {
      const state = gameState.getState();
      const playerId = state.players[0].id;
      const card = state.players[0].hand[0];

      gameController.selectCard(playerId, card);

      // selectCard内でjudgeとupdateが完了する
      const updatedState = gameState.getState();
      expect(updatedState.phase).toBe('ROUND_RESULT');
    });

    it('判定結果がlastResultに記録される', () => {
      const state = gameState.getState();
      const playerId = state.players[0].id;
      const card = state.players[0].hand[0];

      gameController.selectCard(playerId, card);

      const updatedState = gameState.getState();
      expect(updatedState.lastResult).toMatch(/PLAYER_WIN|COMPUTER_WIN|DRAW/);
    });

    it('使用済カードがデッキに追加される', () => {
      const stateBefore = gameState.getState();
      const playerId = stateBefore.players[0].id;
      const card = stateBefore.players[0].hand[0];

      gameController.selectCard(playerId, card);

      const stateAfter = gameState.getState();
      expect(stateAfter.discard.length).toBe(2); // プレイヤー+AI
    });

    it('選択したカードが手札から削除される', () => {
      const stateBefore = gameState.getState();
      const playerId = stateBefore.players[0].id;
      const card = stateBefore.players[0].hand[0];
      const handLengthBefore = stateBefore.players[0].hand.length;

      gameController.selectCard(playerId, card);

      const stateAfter = gameState.getState();
      const playerAfter = stateAfter.players.find(p => p.id === playerId);
      expect(playerAfter.hand.length).toBe(handLengthBefore - 1);
    });
  });

  describe('checkGameOver()', () => {
    beforeEach(() => {
      gameController.initialize();
    });

    it('通常状態ではnullを返す', () => {
      const result = gameController.checkGameOver();

      expect(result).toBeNull();
    });

    it('プレイヤーのコインが0の場合、敗北結果を返す', () => {
      // プレイヤーのコインを0に設定
      const state = gameState.getState();
      const updatedPlayers = state.players.map((p, i) =>
        i === 0 ? { ...p, coins: 0 } : p
      );
      gameState.setState({ players: updatedPlayers });

      const result = gameController.checkGameOver();

      expect(result).not.toBeNull();
      expect(result.winner).toBe(state.players[1].id); // AIの勝利
      expect(result.reason).toBe('COINS_DEPLETED');
    });

    it('AIのコインが0の場合、勝利結果を返す', () => {
      const state = gameState.getState();
      const updatedPlayers = state.players.map((p, i) =>
        i === 1 ? { ...p, coins: 0 } : p
      );
      gameState.setState({ players: updatedPlayers });

      const result = gameController.checkGameOver();

      expect(result).not.toBeNull();
      expect(result.winner).toBe(state.players[0].id); // プレイヤーの勝利
      expect(result.reason).toBe('COINS_DEPLETED');
    });

    it('全手札使用済でプレイヤーのコインが多い場合、勝利結果を返す', () => {
      const state = gameState.getState();
      const updatedPlayers = state.players.map((p, i) =>
        i === 0 ? { ...p, hand: [], coins: 3 } : { ...p, hand: [], coins: 2 }
      );
      gameState.setState({ players: updatedPlayers });

      const result = gameController.checkGameOver();

      expect(result).not.toBeNull();
      expect(result.winner).toBe(state.players[0].id);
      expect(result.reason).toBe('HAND_EXHAUSTED');
    });

    it('全手札使用済でコイン数が同じ場合、引き分け結果を返す', () => {
      const state = gameState.getState();
      const updatedPlayers = state.players.map(p => ({
        ...p,
        hand: [],
        coins: 2
      }));
      gameState.setState({ players: updatedPlayers });

      const result = gameController.checkGameOver();

      expect(result).not.toBeNull();
      expect(result.winner).toBe('DRAW');
      expect(result.reason).toBe('HAND_EXHAUSTED');
    });
  });

  describe('reset()', () => {
    it('ゲームを初期状態にリセットする', () => {
      // ゲームを進行させる
      gameController.initialize();
      const state = gameState.getState();
      const playerId = state.players[0].id;
      const card = state.players[0].hand[0];
      gameController.selectCard(playerId, card);

      // リセット
      gameController.reset();

      const resetState = gameState.getState();
      expect(resetState.phase).toBe('READY');
      expect(resetState.currentRound).toBe(1);
      expect(resetState.discard).toEqual([]);
      expect(resetState.lastResult).toBeNull();
      expect(resetState.selectedCards.size).toBe(0);
    });

    it('リセット後、各プレイヤーの手札とコインが初期化される', () => {
      gameController.initialize();
      gameController.reset();

      const state = gameState.getState();
      state.players.forEach(player => {
        expect(player.hand).toHaveLength(6);
        expect(player.coins).toBe(3);
      });
    });
  });

  describe('次ラウンドの準備', () => {
    beforeEach(() => {
      gameController.initialize();
    });

    it('ラウンド完了後、READYフェーズに戻る', () => {
      const state = gameState.getState();
      const playerId = state.players[0].id;
      const card = state.players[0].hand[0];

      gameController.selectCard(playerId, card);

      // 次ラウンド準備
      gameController.prepareNextRound();

      const updatedState = gameState.getState();
      expect(updatedState.phase).toBe('READY');
    });

    it('selectedCardsがクリアされる', () => {
      const state = gameState.getState();
      const playerId = state.players[0].id;
      const card = state.players[0].hand[0];

      gameController.selectCard(playerId, card);
      gameController.prepareNextRound();

      const updatedState = gameState.getState();
      expect(updatedState.selectedCards.size).toBe(0);
    });
  });
});
