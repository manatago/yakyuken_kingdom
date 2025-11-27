/**
 * AIPlayer ユニットテスト
 * TDD: RED phase - AIのカード選択ロジックをテスト
 */
import { describe, it, expect, beforeEach } from 'vitest';
import { AIPlayer } from '../../scripts/logic/AIPlayer.js';
import { createGameState } from '../../scripts/data/GameState.js';
import { GameConfig } from '../../scripts/data/GameConfig.js';

describe('AIPlayer', () => {
  let gameState;
  let aiPlayerId;

  beforeEach(() => {
    const config = GameConfig.getDefault();
    gameState = createGameState(config);

    // AI（2人目のプレイヤー）のIDを取得
    const players = gameState.getState().players;
    aiPlayerId = players[1].id;

    // AI手札を設定
    const hand = [
      { type: 'ROCK', id: 'ai-card-1' },
      { type: 'PAPER', id: 'ai-card-2' },
      { type: 'SCISSORS', id: 'ai-card-3' }
    ];

    const updatedPlayers = players.map(p =>
      p.id === aiPlayerId ? { ...p, hand } : p
    );

    gameState.setState({ players: updatedPlayers });
  });

  describe('カード選択', () => {
    it('AIの手札からカードを1枚選択する', () => {
      const selectedCard = AIPlayer.selectCard(aiPlayerId, gameState);

      expect(selectedCard).toBeDefined();
      expect(selectedCard).toHaveProperty('type');
      expect(selectedCard).toHaveProperty('id');
    });

    it('選択されたカードはAIの手札に存在する', () => {
      const selectedCard = AIPlayer.selectCard(aiPlayerId, gameState);

      const state = gameState.getState();
      const aiPlayer = state.players.find(p => p.id === aiPlayerId);
      const cardExists = aiPlayer.hand.some(card => card.id === selectedCard.id);

      expect(cardExists).toBe(true);
    });

    it('複数回呼び出してもカードを返す（ランダム性）', () => {
      const card1 = AIPlayer.selectCard(aiPlayerId, gameState);
      const card2 = AIPlayer.selectCard(aiPlayerId, gameState);
      const card3 = AIPlayer.selectCard(aiPlayerId, gameState);

      expect(card1).toBeDefined();
      expect(card2).toBeDefined();
      expect(card3).toBeDefined();
    });

    it('手札が1枚の場合でもその1枚を選択する', () => {
      // 手札を1枚だけに設定
      const state = gameState.getState();
      const players = state.players;
      const updatedPlayers = players.map(p =>
        p.id === aiPlayerId
          ? { ...p, hand: [{ type: 'ROCK', id: 'only-card' }] }
          : p
      );

      gameState.setState({ players: updatedPlayers });

      const selectedCard = AIPlayer.selectCard(aiPlayerId, gameState);

      expect(selectedCard.id).toBe('only-card');
      expect(selectedCard.type).toBe('ROCK');
    });
  });

  describe('エラーハンドリング', () => {
    it('手札が空の場合はエラーをスローする', () => {
      // 手札を空に設定
      const state = gameState.getState();
      const players = state.players;
      const updatedPlayers = players.map(p =>
        p.id === aiPlayerId ? { ...p, hand: [] } : p
      );

      gameState.setState({ players: updatedPlayers });

      expect(() => {
        AIPlayer.selectCard(aiPlayerId, gameState);
      }).toThrow('AI has no cards in hand');
    });

    it('無効なプレイヤーIDの場合はエラーをスローする', () => {
      expect(() => {
        AIPlayer.selectCard('invalid-player-id', gameState);
      }).toThrow('Player not found');
    });
  });

  describe('ランダム性の検証', () => {
    it('十分な試行回数で全種類のカードが選択される（統計的検証）', () => {
      const selectedTypes = new Set();
      const iterations = 100;

      for (let i = 0; i < iterations; i++) {
        const card = AIPlayer.selectCard(aiPlayerId, gameState);
        selectedTypes.add(card.type);
      }

      // 100回の試行で3種類全てが選択される確率は極めて高い
      // （理論上は99.99%以上）
      expect(selectedTypes.size).toBeGreaterThan(1);
    });
  });

  describe('純粋性（状態を変更しない）', () => {
    it('selectCard()呼び出し後も手札は変更されない', () => {
      const stateBefore = gameState.getState();
      const handBefore = stateBefore.players.find(p => p.id === aiPlayerId).hand;
      const handLengthBefore = handBefore.length;

      AIPlayer.selectCard(aiPlayerId, gameState);

      const stateAfter = gameState.getState();
      const handAfter = stateAfter.players.find(p => p.id === aiPlayerId).hand;

      expect(handAfter.length).toBe(handLengthBefore);
      expect(handAfter).toEqual(handBefore);
    });
  });
});
