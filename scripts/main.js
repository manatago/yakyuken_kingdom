/**
 * じゃんけんゲーム - メインエントリーポイント
 * 全モジュールの初期化とワイヤリングを行う
 */

import { GameConfig } from './data/GameConfig.js';
import { createGameState } from './data/GameState.js';
import { createGameController } from './logic/GameController.js';
import { createUIRenderer } from './ui/UIRenderer.js';

/**
 * アプリケーション初期化
 */
function initializeApp() {
    console.log('じゃんけんゲーム起動中...');

    try {
        // ゲーム設定
        const config = GameConfig.getDefault();

        // ゲーム状態ストア
        const gameState = createGameState(config);

        // ゲームコントローラー
        const gameController = createGameController(gameState, config);

        // UIレンダラー
        const uiRenderer = createUIRenderer(gameState, gameController);

        // 初期化
        gameController.initialize();
        uiRenderer.initialize();

        console.log('ゲームの準備が完了しました');
    } catch (error) {
        console.error('初期化エラー:', error);
        alert('ゲームの初期化に失敗しました。ページを再読み込みしてください。');
    }
}

// エラーハンドリング
window.onerror = function(message, source, lineno, colno, error) {
    console.error('ランタイムエラー:', { message, source, lineno, colno, error });
    return false;
};

// DOM読み込み完了後に初期化
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeApp);
} else {
    initializeApp();
}
