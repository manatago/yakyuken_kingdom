/**
 * 基本的なゲームフローのE2Eテスト
 */
import { test, expect } from '@playwright/test';

test.describe('じゃんけんゲーム - 基本フロー', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('ゲームが正常に起動する', async ({ page }) => {
    // タイトルが表示される
    await expect(page.locator('h1')).toHaveText('じゃんけんゲーム');

    // プレイヤーとコンピュータの情報が表示される
    await expect(page.locator('.player-info h2')).toHaveText('あなた');
    await expect(page.locator('.opponent-info h2')).toHaveText('コンピュータ');

    // 初期コイン数が3
    await expect(page.locator('#player-coin-count')).toHaveText('3');
    await expect(page.locator('#opponent-coin-count')).toHaveText('3');
  });

  test('手札が6枚表示される', async ({ page }) => {
    // 手札エリアにカードが6枚
    const cards = page.locator('.hand-area .card');
    await expect(cards).toHaveCount(6);

    // グー、チョキ、パーが各2枚
    const rockCards = page.locator('.card[data-card-type="ROCK"]');
    const paperCards = page.locator('.card[data-card-type="PAPER"]');
    const scissorsCards = page.locator('.card[data-card-type="SCISSORS"]');

    await expect(rockCards).toHaveCount(2);
    await expect(paperCards).toHaveCount(2);
    await expect(scissorsCards).toHaveCount(2);
  });

  test('カードを選択して1ラウンドプレイできる', async ({ page }) => {
    // 最初のカードをクリック
    await page.locator('.hand-area .card').first().click();

    // 結果が表示されるまで待機
    await page.waitForSelector('.result-area', { state: 'visible' });

    // 結果テキストが表示される
    const resultText = await page.locator('.result-area').textContent();
    expect(resultText).toMatch(/勝ち|引き分け/);

    // デッキにカードが2枚追加される
    await expect(page.locator('#deck-count')).toHaveText('2');

    // 手札が5枚に減る
    const remainingCards = page.locator('.hand-area .card');
    await expect(remainingCards).toHaveCount(5);
  });

  test('リセットボタンでゲームがリセットされる', async ({ page }) => {
    // 1ラウンドプレイ
    await page.locator('.hand-area .card').first().click();
    await page.waitForTimeout(500);

    // リセットボタンをクリック
    await page.locator('#reset-button').click();

    // 手札が6枚に戻る
    const cards = page.locator('.hand-area .card');
    await expect(cards).toHaveCount(6);

    // コインが3枚に戻る
    await expect(page.locator('#player-coin-count')).toHaveText('3');
    await expect(page.locator('#opponent-coin-count')).toHaveText('3');

    // デッキが空になる
    await expect(page.locator('#deck-count')).toHaveText('0');
  });

  test('複数ラウンドプレイできる', async ({ page }) => {
    // 3ラウンドプレイ
    for (let i = 0; i < 3; i++) {
      await page.locator('.hand-area .card').first().click();
      await page.waitForTimeout(2500); // 結果表示 + 次ラウンド準備
    }

    // デッキに6枚のカードが追加される
    await expect(page.locator('#deck-count')).toHaveText('6');

    // 手札が3枚に減る
    const remainingCards = page.locator('.hand-area .card');
    await expect(remainingCards).toHaveCount(3);
  });
});
