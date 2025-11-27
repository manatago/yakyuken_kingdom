/**
 * JudgeService ユニットテスト
 * TDD: RED phase - じゃんけん勝敗判定の全9パターンをテスト
 */
import { describe, it, expect } from 'vitest';
import { JudgeService } from '../../scripts/logic/JudgeService.js';

describe('JudgeService', () => {
  describe('じゃんけん勝敗判定 - 全9パターン', () => {
    // プレイヤー勝利パターン（3パターン）
    it('グー vs チョキ → プレイヤー勝利', () => {
      const card1 = { type: 'ROCK', id: 'p-1' };
      const card2 = { type: 'SCISSORS', id: 'c-1' };

      const result = JudgeService.judgeRound(card1, card2);

      expect(result).toBe('PLAYER_WIN');
    });

    it('チョキ vs パー → プレイヤー勝利', () => {
      const card1 = { type: 'SCISSORS', id: 'p-1' };
      const card2 = { type: 'PAPER', id: 'c-1' };

      const result = JudgeService.judgeRound(card1, card2);

      expect(result).toBe('PLAYER_WIN');
    });

    it('パー vs グー → プレイヤー勝利', () => {
      const card1 = { type: 'PAPER', id: 'p-1' };
      const card2 = { type: 'ROCK', id: 'c-1' };

      const result = JudgeService.judgeRound(card1, card2);

      expect(result).toBe('PLAYER_WIN');
    });

    // コンピュータ勝利パターン（3パターン）
    it('グー vs パー → コンピュータ勝利', () => {
      const card1 = { type: 'ROCK', id: 'p-1' };
      const card2 = { type: 'PAPER', id: 'c-1' };

      const result = JudgeService.judgeRound(card1, card2);

      expect(result).toBe('COMPUTER_WIN');
    });

    it('チョキ vs グー → コンピュータ勝利', () => {
      const card1 = { type: 'SCISSORS', id: 'p-1' };
      const card2 = { type: 'ROCK', id: 'c-1' };

      const result = JudgeService.judgeRound(card1, card2);

      expect(result).toBe('COMPUTER_WIN');
    });

    it('パー vs チョキ → コンピュータ勝利', () => {
      const card1 = { type: 'PAPER', id: 'p-1' };
      const card2 = { type: 'SCISSORS', id: 'c-1' };

      const result = JudgeService.judgeRound(card1, card2);

      expect(result).toBe('COMPUTER_WIN');
    });

    // 引き分けパターン（3パターン）
    it('グー vs グー → 引き分け', () => {
      const card1 = { type: 'ROCK', id: 'p-1' };
      const card2 = { type: 'ROCK', id: 'c-1' };

      const result = JudgeService.judgeRound(card1, card2);

      expect(result).toBe('DRAW');
    });

    it('チョキ vs チョキ → 引き分け', () => {
      const card1 = { type: 'SCISSORS', id: 'p-1' };
      const card2 = { type: 'SCISSORS', id: 'c-1' };

      const result = JudgeService.judgeRound(card1, card2);

      expect(result).toBe('DRAW');
    });

    it('パー vs パー → 引き分け', () => {
      const card1 = { type: 'PAPER', id: 'p-1' };
      const card2 = { type: 'PAPER', id: 'c-1' };

      const result = JudgeService.judgeRound(card1, card2);

      expect(result).toBe('DRAW');
    });
  });

  describe('純粋関数としての性質', () => {
    it('同じ入力に対して常に同じ結果を返す', () => {
      const card1 = { type: 'ROCK', id: 'p-1' };
      const card2 = { type: 'SCISSORS', id: 'c-1' };

      const result1 = JudgeService.judgeRound(card1, card2);
      const result2 = JudgeService.judgeRound(card1, card2);
      const result3 = JudgeService.judgeRound(card1, card2);

      expect(result1).toBe('PLAYER_WIN');
      expect(result2).toBe('PLAYER_WIN');
      expect(result3).toBe('PLAYER_WIN');
    });

    it('入力オブジェクトを変更しない', () => {
      const card1 = { type: 'ROCK', id: 'p-1' };
      const card2 = { type: 'SCISSORS', id: 'c-1' };
      const card1Original = { ...card1 };
      const card2Original = { ...card2 };

      JudgeService.judgeRound(card1, card2);

      expect(card1).toEqual(card1Original);
      expect(card2).toEqual(card2Original);
    });
  });

  describe('エッジケース', () => {
    it('カードIDが異なっても判定は型のみに基づく', () => {
      const card1a = { type: 'ROCK', id: 'p-1' };
      const card1b = { type: 'ROCK', id: 'p-999' };
      const card2 = { type: 'SCISSORS', id: 'c-1' };

      const result1 = JudgeService.judgeRound(card1a, card2);
      const result2 = JudgeService.judgeRound(card1b, card2);

      expect(result1).toBe('PLAYER_WIN');
      expect(result2).toBe('PLAYER_WIN');
    });
  });
});
