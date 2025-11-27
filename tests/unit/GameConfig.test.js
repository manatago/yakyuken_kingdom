/**
 * GameConfig ユニットテスト
 * TDD: RED phase - テストを先に書く
 */
import { describe, it, expect } from 'vitest';
import { GameConfig } from '../../scripts/data/GameConfig.js';

describe('GameConfig', () => {
  describe('デフォルト設定', () => {
    it('デフォルト値が正しく設定されている', () => {
      const config = GameConfig.getDefault();

      expect(config.handSize).toBe(6);
      expect(config.initialCoins).toBe(3);
      expect(config.playerCount).toBe(2);
      expect(config.cardTypes).toEqual(['ROCK', 'PAPER', 'SCISSORS']);
    });

    it('カード種類が3種類である', () => {
      const config = GameConfig.getDefault();

      expect(config.cardTypes).toHaveLength(3);
    });
  });

  describe('設定値の検証', () => {
    it('handSize > 0 を満たす設定は有効', () => {
      const config = { handSize: 6, initialCoins: 3, playerCount: 2 };

      expect(() => GameConfig.validate(config)).not.toThrow();
    });

    it('handSize <= 0 の場合はエラー', () => {
      const config = { handSize: 0, initialCoins: 3, playerCount: 2 };

      expect(() => GameConfig.validate(config)).toThrow('handSize must be greater than 0');
    });

    it('initialCoins > 0 を満たす設定は有効', () => {
      const config = { handSize: 6, initialCoins: 3, playerCount: 2 };

      expect(() => GameConfig.validate(config)).not.toThrow();
    });

    it('initialCoins <= 0 の場合はエラー', () => {
      const config = { handSize: 6, initialCoins: 0, playerCount: 2 };

      expect(() => GameConfig.validate(config)).toThrow('initialCoins must be greater than 0');
    });

    it('playerCount >= 2 を満たす設定は有効', () => {
      const config = { handSize: 6, initialCoins: 3, playerCount: 2 };

      expect(() => GameConfig.validate(config)).not.toThrow();
    });

    it('playerCount < 2 の場合はエラー', () => {
      const config = { handSize: 6, initialCoins: 3, playerCount: 1 };

      expect(() => GameConfig.validate(config)).toThrow('playerCount must be at least 2');
    });
  });

  describe('カスタム設定の作成', () => {
    it('カスタム設定値で作成できる', () => {
      const customConfig = GameConfig.create({
        handSize: 9,
        initialCoins: 5,
        playerCount: 3
      });

      expect(customConfig.handSize).toBe(9);
      expect(customConfig.initialCoins).toBe(5);
      expect(customConfig.playerCount).toBe(3);
      expect(customConfig.cardTypes).toEqual(['ROCK', 'PAPER', 'SCISSORS']);
    });

    it('部分的なカスタム設定はデフォルト値で補完される', () => {
      const partialConfig = GameConfig.create({
        handSize: 9
      });

      expect(partialConfig.handSize).toBe(9);
      expect(partialConfig.initialCoins).toBe(3); // デフォルト
      expect(partialConfig.playerCount).toBe(2); // デフォルト
    });

    it('無効な設定値の場合はエラー', () => {
      expect(() => GameConfig.create({ handSize: -1 })).toThrow();
      expect(() => GameConfig.create({ initialCoins: 0 })).toThrow();
      expect(() => GameConfig.create({ playerCount: 1 })).toThrow();
    });
  });

  describe('Immutability（不変性）', () => {
    it('設定オブジェクトは凍結されている', () => {
      const config = GameConfig.getDefault();

      expect(Object.isFrozen(config)).toBe(true);
    });

    it('cardTypes配列も凍結されている', () => {
      const config = GameConfig.getDefault();

      expect(Object.isFrozen(config.cardTypes)).toBe(true);
    });
  });
});
