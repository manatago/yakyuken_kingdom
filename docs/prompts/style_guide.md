# Style Guide（画風共通ルール）

全画像生成プロンプトの土台。個別プロンプト（`portraits/main/*.md`, `portraits/battle/*.md`）は
このガイドを継承する前提で書く。

---

## 想定生成AI

- **サービス**: NovelAI Diffusion（最新アニメモデル想定 / NAI Diffusion Anime 系列）
- **記述形式**: Danbooru タグ形式（カンマ区切り）＋必要に応じて自然言語併記
- **成人向け表現**: 許容。下着・乳房・局部などの描写OK（成人向けOKなサービス前提）
- **参照画像**: `docs/prompts/references/` 配下に後日配置予定。画風は参照画像準拠
  - 例: `references/ref_satoshi.png`, `references/ref_princess.png` 等のプレースホルダ名で
    個別プロンプト内に記述しておく。実ファイルは別途配置

---

## 基本クオリティタグ

### ポジティブ（必須・プロンプトの先頭）

```
masterpiece, best quality, very aesthetic, absurdres, highly detailed
```

### ネガティブ（必須）

```
lowres, bad anatomy, bad hands, missing fingers, extra digits, fewer digits,
cropped, worst quality, low quality, jpeg artifacts, signature, watermark,
text, blurry, bad proportions, deformed, mutated, disfigured
```

---

## 画風

- **基本**: アニメ調、セル塗り、線画はっきり
- **彩度**: やや高め（ファンタジー世界の華やかさを意識）
- **陰影**: 柔らかめのセル影2〜3段階
- **線画**: 瞳は大きめ、睫毛は明確、髪はロック単位で束が見える
- **参照画像**: `references/` 配下の参照画像に画風を合わせる（後日追加）

---

## キャラ表現の基本比率

- **頭身**: 7〜8頭身（一般的なJRPG調）
- **目**: やや大きめ、瞳孔に明確なハイライト2点
- **顔立ち**: 異世界ファンタジーのため、**西洋寄り**（日本人的デフォルメは避ける）
  - 例外: サトシ・みのり（日本の大学生なのでアジア系）
- **肌**: キャラごとに差別化（`character_sheet.md` 参照）

---

## 立ち絵・構図

### 通常立ち絵（`portraits/main/`）

- **画角**: バストアップ〜ウエストアップ基本（顔・表情を見せる）
- **例外**: 登場時やドラマチックな場面では全身・膝上
- **背景**: `simple background`, `plain white background`, `white background` 等
  - 背景除去スクリプト（`scripts/remove_bg_birefnet.py`）で後処理するため
  - **背景は描くが、簡素に**
- **ポーズ**: キャラの性格に合わせた自然な立ち姿
- **カメラ**: 正面またはやや斜め

### バトル立ち絵（`portraits/battle/`）

- **画角**: 半身〜ウエストアップ（戦闘の構えを見せる）
- **背景**: 通常立ち絵と同じ（simple background）
- **ポーズ**: カードを構える／片手を前に出す／挑発的な構え／余裕の立ち姿 等
- **カメラ**: 正面やや下から（挑んでくる圧を出す場合も可）

### 顔アップ（大写し）

- **画角**: バストアップの上部トリミング、または顔単独
- **背景**: 同上
- 表情の迫力が欲しいシーン用（例: `char01_pg_021` の絶望パニック顔）

---

## 照明

- **基本**: 画面上方やや左からの柔らかい環境光
- **シーンに合わせた色調**:
  - 大学キャンパス昼間: 自然光、明るめ、暖色寄り
  - 加速器施設: 蛍光灯、白色、硬質
  - 牢屋: 松明の暖色光、片面陰影強め
  - 教会・昼: ステンドグラス越しの彩り光
  - 教会・夜間潜入: 月光、青系寒色、影強め
  - 宮中・大広間: シャンデリアの金色光、上品
  - 訓練場: 自然光、白砂の反射で下からも光
  - 夕暮れ: 暖色オレンジ、影長め

---

## 衣装段階（outfit）

野球拳バトル中の衣装段階。バトル立ち絵で使用する。
**男女問わず、敗北時（outfit_1）は素っ裸＋モザイク処理**で描写する。

### outfit_3（フル装備）

- キャラの基本衣装すべて身につけた状態
- `character_sheet.md` の「基本衣装」定義そのまま

### outfit_2（半裸・中間段階）

- 衣装の一部を失った状態（**下着は描かない**）
- 想定: 上衣を失い上半身露出＋下半身は破れた短パン／短いスカート／布切れ 等
  - 女性: **乳房露出、局部は下半身の残存布で隠れる**（直接描写回避）
  - 男性: **上半身完全露出、下半身は短パン or 破れたズボン等**
- タグ例（女性）: `topless, (torn short skirt or cloth wrapping waist), bare breasts, nipples visible`
- タグ例（男性）: `shirtless, bare chest, (torn shorts or tattered pants), muscular/lean torso`

### outfit_1（素っ裸＋モザイク）

- 最終敗北状態。**完全に裸**。
- 局部は**モザイク処理**で隠す（成人向けサービス側のモザイクフィルター or プロンプトでの `censored` タグ）
- 男女ともに同仕様。男性も敗北時は素っ裸で描画
- キャラの性格に応じた敗北ポーズ:
  - 両腕で隠す（恥ずかしがり）
  - 膝を抱える（屈辱）
  - 倒れ込む／膝をつく（敗北直後）
  - 開き直って堂々と（挑発的なキャラ）
  - 座り込んで泣く（純情・箱入り系）
- **タグ例（女性）**:
  ```
  completely nude, full nudity, bare breasts, nipples visible,
  (mosaic censoring on genitals, censored pubic area),
  no clothes, defeat pose
  ```
- **タグ例（男性）**:
  ```
  completely nude male, full nudity, bare chest,
  (mosaic censoring on genitals, censored groin),
  no clothes, defeat pose
  ```

### モザイク処理の指針

- **局部（股間）** には必ずモザイクを入れる（男女問わず）
- 女性の**乳首は露出OK**（モザイクなし）※成人向けOKサービス前提
- モザイクのサイズ・粒度は画像生成AI側の標準に委ねる
- プロンプト上は `mosaic censoring on genitals, censored pubic area` 等で指示
- NovelAI の場合: `censored` タグや自動モザイクオプションを活用

---

## 表情差分の命名方針（方針A）

個別プロンプトは、**表情差分を共通ベース＋追加タグ方式にせず**、各ポートレート番号
ごとに独立したフルプロンプトを記述する。

- 例: `char01_pg_002`（会話表情A）も `char01_pg_003`（会話表情B）もそれぞれ
  完全なプロンプトを書く
- 冗長だが、画像生成時に迷わず、生成結果が安定する
- キャラの基本外観部分は `character_sheet.md` から引用する形でキープ

---

## プロンプト記述フォーマット（各ポートレート）

各ポートレート1件を、以下のフォーマットで記述する:

```markdown
### char01_pg_000（プロローグ・大学キャンパス立ち絵）

**シーン**: 場面1、5月の大学キャンパス。日常の気楽な立ち姿。
**使用場面**: prologue_scenario.txt 場面1

**ポジティブプロンプト**:
```
masterpiece, best quality, very aesthetic, absurdres, 1boy,
[キャラ外観タグ（character_sheet.md の satoshi 項を展開）],
[衣装タグ],
[表情・ポーズタグ],
[背景・照明タグ],
simple background
```

**ネガティブプロンプト**: 共通ネガティブ（style_guide.md 参照）

**備考**: （あれば。参照画像、色味の注意点、等）
```

---

## 命名規則と参照

- キャラID（ファイル名）: 英小文字＋スネークケース（例: `knight_commander`）
- 画像ファイル名は実装側の命名規則（`char01_pg_000.png`, `layla_battle_001.png` 等）に従う
- プロンプトファイル内では「画像ファイル名」を見出しに使い、本文で完全プロンプトを記述

---

## 免責・運用メモ

- NovelAIのサービスポリシー範囲内でのみ生成すること
- 成人向け描写は成人向けOKのモデル／サービスでのみ使用
- 年齢に関する表記は「18歳以上」「adult」「young adult」等を明記（モデルの学習ガード対策）
- 生成後は `scripts/remove_bg_birefnet.py` で背景除去して立ち絵素材化する想定
