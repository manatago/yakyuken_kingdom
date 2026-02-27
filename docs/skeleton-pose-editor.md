# Skeleton Pose Editor - プロジェクト概要

AI画像生成でポーズを指定するための、スケルトン（骨格）ポーズ作成Webアプリケーション。

## コンセプト

円（関節）と線（ボーン）で構成されるスケルトンを、UI上で直感的に操作してポーズを作成する。
作成したポーズ画像をControlNet等のAI画像生成ツールに入力として使用する。

## 技術スタック

| 要素 | 技術 | 理由 |
|------|------|------|
| フレームワーク | React + TypeScript | 状態管理中心のSPAに最適 |
| ビルドツール | Vite | 高速ビルド、シンプルな構成 |
| 描画 | SVG (DOM直接) | 関節=`<circle>`、ボーン=`<line>`で自然に表現。ドラッグイベントも容易 |
| ポーズ推定 | MediaPipe Pose (`@mediapipe/tasks-vision`) | ブラウザ内完結、サーバー不要、33関節検出 |
| スタイリング | Tailwind CSS | ユーティリティファーストで高速開発 |
| エクスポート | html-to-image / SVG serialize | PNG/SVG出力 |
| デプロイ | Vercel / Netlify / GitHub Pages | 静的ホスティングで十分 |

## ディレクトリ構成

```
skeleton-pose-editor/
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.ts
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── components/
    │   ├── Canvas/
    │   │   ├── SkeletonCanvas.tsx   # SVG描画エリア（メインキャンバス）
    │   │   ├── Joint.tsx            # 関節コンポーネント（draggable circle）
    │   │   └── Bone.tsx             # ボーンコンポーネント（line）
    │   ├── Controls/
    │   │   ├── ToolBar.tsx          # リセット、エクスポート、プリセット選択
    │   │   ├── CoordinatePanel.tsx  # 座標数値入力パネル（Phase 3）
    │   │   └── TextInput.tsx        # テキストでポーズ指定（Phase 3）
    │   └── ImageUpload/
    │       └── ImageUploader.tsx    # 画像アップロード + ポーズ推定UI
    ├── models/
    │   ├── skeleton.ts              # 型定義（Joint, Bone, Skeleton）
    │   └── presets.ts               # プリセットポーズデータ
    ├── hooks/
    │   ├── useDragJoint.ts          # 関節ドラッグ操作フック
    │   └── usePoseEstimation.ts     # MediaPipe連携フック
    └── utils/
        ├── exportImage.ts           # PNG/SVGエクスポート処理
        └── poseParser.ts            # テキスト/座標 → ポーズ変換
```

## データモデル

```typescript
interface Joint {
  id: string;      // 例: "head", "left_shoulder", "right_elbow"
  x: number;       // SVG座標
  y: number;
  label: string;   // 表示名
}

interface Bone {
  from: string;    // 接続元 Joint.id
  to: string;      // 接続先 Joint.id
}

interface Skeleton {
  joints: Joint[];
  bones: Bone[];
}
```

### 標準スケルトン構成（17関節）

```
        head
         |
        neck
       / | \
  l_sh  spine  r_sh
   |     |      |
  l_el  hip   r_el
   |   /   \    |
  l_wr l_hp r_hp r_wr
       |     |
      l_kn  r_kn
       |     |
      l_ak  r_ak
```

関節一覧:
- 頭部: `head`, `neck`
- 体幹: `spine`, `hip`
- 左腕: `left_shoulder`, `left_elbow`, `left_wrist`
- 右腕: `right_shoulder`, `right_elbow`, `right_wrist`
- 左脚: `left_hip`, `left_knee`, `left_ankle`
- 右脚: `right_hip`, `right_knee`, `right_ankle`
- (手指・足指は将来拡張)

## 開発フェーズ

### Phase 1: 基本エディタ
- [ ] プロジェクトセットアップ（Vite + React + TypeScript + Tailwind）
- [ ] スケルトンデータモデル定義
- [ ] SVGキャンバスに標準スケルトン表示
- [ ] 関節のドラッグ＆ドロップでポーズ変更
- [ ] ボーンの自動追従（関節移動時に線が連動）
- [ ] リセットボタン（初期ポーズに戻す）
- [ ] PNG/SVGエクスポート

### Phase 2: 画像からスケルトン作成
- [ ] 画像アップロードUI
- [ ] MediaPipe Poseでブラウザ内ポーズ推定
- [ ] 推定結果をスケルトンに反映
- [ ] アップロード画像を背景に表示し、スケルトンを重ねて微調整
- [ ] プリセットポーズ（立ちポーズ、座りポーズ等）

### Phase 3: 入力方法拡張
- [ ] 座標パネル（各関節のx,y値を数値入力 ⇄ SVG連動）
- [ ] テキスト入力でポーズ指定（「右手を上げる」等）
- [ ] ポーズのJSON保存/読み込み

## 画像→スケルトン変換フロー

```
画像アップロード
    ↓
MediaPipe Pose（ブラウザ内推論）
    ↓
33関節の座標を取得
    ↓
17関節にマッピング（不要な関節を除外）
    ↓
SVGキャンバスに反映
    ↓
手動で微調整
    ↓
PNG/SVGエクスポート
```

## UI レイアウト案

```
┌─────────────────────────────────────────────┐
│  ToolBar [リセット] [プリセット▼] [エクスポート] │
├────────────────────────┬────────────────────┤
│                        │  Controls          │
│                        │                    │
│    SVG Canvas          │  ・画像アップロード  │
│    (スケルトン描画)      │  ・座標パネル       │
│                        │  ・テキスト入力      │
│                        │                    │
│                        │                    │
└────────────────────────┴────────────────────┘
```

## 出力仕様

- **PNG**: 黒背景 + 白/カラーのスケルトン（ControlNet OpenPose互換）
- **SVG**: ベクター形式（再編集可能）
- **JSON**: ポーズデータ（保存/読み込み用）

## 選定理由

### React + Viteを選んだ理由
- 単一画面のSPAであり、フルフレームワーク（Next.js/React Router V7等）は不要
- 状態管理（関節座標）がReactのstateで自然に扱える
- 静的サイトとしてデプロイ可能、サーバー不要
- 必要に応じて後からreact-router-domを追加可能

### SVGを選んだ理由
- 関節=`<circle>`、ボーン=`<line>`でHTMLの意味論と一致
- 各要素にイベントハンドラを直接付与できる（Canvasより簡単）
- ブラウザの開発者ツールでデバッグ可能
- スケルトン程度の要素数（30〜40）ではパフォーマンス問題なし
