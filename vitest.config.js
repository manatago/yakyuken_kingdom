import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // テスト環境
    environment: 'jsdom',

    // グローバルテストAPI (describe, it, expect等)
    globals: true,

    // カバレッジ設定
    coverage: {
      provider: 'c8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'tests/',
        '*.config.js',
        'scripts/main.js' // エントリーポイントは除外
      ],
      // カバレッジ目標
      lines: 70,
      functions: 70,
      branches: 70,
      statements: 70
    },

    // テストファイルパターン
    include: ['tests/**/*.{test,spec}.{js,mjs,cjs}'],

    // セットアップファイル
    setupFiles: [],

    // テストタイムアウト
    testTimeout: 10000
  }
});
