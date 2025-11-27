/**
 * GameState ユニットテスト
 * TDD: RED phase - テストを先に書く
 */
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createGameState } from '../../scripts/data/GameState.js';
import { GameConfig } from '../../scripts/data/GameConfig.js';

describe('GameState', () => {
  let gameState;
  let config;

  beforeEach(() => {
    config = GameConfig.getDefault();
    gameState = createGameState(config);
  });

  describe('初期化', () => {
    it('初期フェーズがINITIALIZEDである', () => {
      const state = gameState.getState();

      expect(state.phase).toBe('INITIALIZED');
    });

    it('初期ラウンド数が0である', () => {
      const state = gameState.getState();

      expect(state.currentRound).toBe(0);
    });

    it('プレイヤーが2人作成される', () => {
      const state = gameState.getState();

      expect(state.players).toHaveLength(2);
    });

    it('各プレイヤーが正しい初期状態を持つ', () => {
      const state = gameState.getState();
      const player = state.players[0];

      expect(player).toHaveProperty('id');
      expect(player).toHaveProperty('name');
      expect(player).toHaveProperty('hand');
      expect(player).toHaveProperty('coins');
      expect(player).toHaveProperty('isHuman');
      expect(player.hand).toEqual([]);
      expect(player.coins).toBe(3);
    });

    it('1人目のプレイヤーが人間、2人目がAIである', () => {
      const state = gameState.getState();

      expect(state.players[0].isHuman).toBe(true);
      expect(state.players[1].isHuman).toBe(false);
    });

    it('デッキが空配列で初期化される', () => {
      const state = gameState.getState();

      expect(state.discard).toEqual([]);
    });

    it('lastResultがnullで初期化される', () => {
      const state = gameState.getState();

      expect(state.lastResult).toBeNull();
    });

    it('selectedCardsが空のMapで初期化される', () => {
      const state = gameState.getState();

      expect(state.selectedCards).toBeInstanceOf(Map);
      expect(state.selectedCards.size).toBe(0);
    });
  });

  describe('状態の取得', () => {
    it('getState()で現在の状態を取得できる', () => {
      const state = gameState.getState();

      expect(state).toHaveProperty('phase');
      expect(state).toHaveProperty('players');
      expect(state).toHaveProperty('discard');
      expect(state).toHaveProperty('currentRound');
      expect(state).toHaveProperty('lastResult');
      expect(state).toHaveProperty('selectedCards');
    });

    it('getState()で取得した状態は読み取り専用', () => {
      const state = gameState.getState();

      // 直接変更しようとしてもエラーまたは無視される
      expect(() => {
        state.phase = 'READY';
      }).toThrow();
    });
  });

  describe('状態の更新', () => {
    it('setState()でフェーズを更新できる', () => {
      gameState.setState({ phase: 'READY' });

      const state = gameState.getState();
      expect(state.phase).toBe('READY');
    });

    it('setState()でラウンド数を更新できる', () => {
      gameState.setState({ currentRound: 1 });

      const state = gameState.getState();
      expect(state.currentRound).toBe(1);
    });

    it('setState()で複数のプロパティを同時に更新できる', () => {
      gameState.setState({
        phase: 'JUDGING',
        currentRound: 2,
        lastResult: 'PLAYER_WIN'
      });

      const state = gameState.getState();
      expect(state.phase).toBe('JUDGING');
      expect(state.currentRound).toBe(2);
      expect(state.lastResult).toBe('PLAYER_WIN');
    });

    it('部分的な更新でも他のプロパティは保持される', () => {
      gameState.setState({ phase: 'READY' });
      const stateBefore = gameState.getState();

      gameState.setState({ currentRound: 1 });
      const stateAfter = gameState.getState();

      expect(stateAfter.phase).toBe('READY');
      expect(stateAfter.currentRound).toBe(1);
    });
  });

  describe('リアクティブ更新（Proxy）', () => {
    it('subscribe()でリスナーを登録できる', () => {
      const listener = vi.fn();

      gameState.subscribe(listener);
      gameState.setState({ phase: 'READY' });

      expect(listener).toHaveBeenCalledTimes(1);
    });

    it('リスナーに最新の状態が渡される', () => {
      const listener = vi.fn();

      gameState.subscribe(listener);
      gameState.setState({ phase: 'READY' });

      expect(listener).toHaveBeenCalledWith(
        expect.objectContaining({ phase: 'READY' })
      );
    });

    it('複数のリスナーを登録できる', () => {
      const listener1 = vi.fn();
      const listener2 = vi.fn();

      gameState.subscribe(listener1);
      gameState.subscribe(listener2);
      gameState.setState({ phase: 'READY' });

      expect(listener1).toHaveBeenCalledTimes(1);
      expect(listener2).toHaveBeenCalledTimes(1);
    });

    it('subscribe()は解除関数を返す', () => {
      const listener = vi.fn();

      const unsubscribe = gameState.subscribe(listener);
      expect(typeof unsubscribe).toBe('function');
    });

    it('解除関数でリスナーを解除できる', () => {
      const listener = vi.fn();

      const unsubscribe = gameState.subscribe(listener);
      gameState.setState({ phase: 'READY' });
      expect(listener).toHaveBeenCalledTimes(1);

      unsubscribe();
      gameState.setState({ phase: 'PLAYER_SELECTING' });
      expect(listener).toHaveBeenCalledTimes(1); // 増えない
    });
  });

  describe('手札の管理', () => {
    it('プレイヤーの手札を更新できる', () => {
      const players = gameState.getState().players;
      const playerId = players[0].id;

      const newHand = [
        { type: 'ROCK', id: 'card-1' },
        { type: 'PAPER', id: 'card-2' }
      ];

      // プレイヤー配列を更新
      const updatedPlayers = players.map(p =>
        p.id === playerId ? { ...p, hand: newHand } : p
      );

      gameState.setState({ players: updatedPlayers });

      const state = gameState.getState();
      const player = state.players.find(p => p.id === playerId);
      expect(player.hand).toHaveLength(2);
      expect(player.hand[0].type).toBe('ROCK');
    });
  });

  describe('コインの管理', () => {
    it('プレイヤーのコイン数を更新できる', () => {
      const players = gameState.getState().players;
      const playerId = players[0].id;

      const updatedPlayers = players.map(p =>
        p.id === playerId ? { ...p, coins: 4 } : p
      );

      gameState.setState({ players: updatedPlayers });

      const state = gameState.getState();
      const player = state.players.find(p => p.id === playerId);
      expect(player.coins).toBe(4);
    });
  });

  describe('デッキの管理', () => {
    it('デッキにカードを追加できる', () => {
      const discardCards = [
        { type: 'ROCK', id: 'card-1' },
        { type: 'PAPER', id: 'card-2' }
      ];

      gameState.setState({ discard: discardCards });

      const state = gameState.getState();
      expect(state.discard).toHaveLength(2);
    });
  });

  describe('選択カードの管理', () => {
    it('selectedCardsにカードを追加できる', () => {
      const players = gameState.getState().players;
      const selectedCards = new Map();
      selectedCards.set(players[0].id, { type: 'ROCK', id: 'card-1' });

      gameState.setState({ selectedCards });

      const state = gameState.getState();
      expect(state.selectedCards.size).toBe(1);
      expect(state.selectedCards.get(players[0].id).type).toBe('ROCK');
    });
  });
});
