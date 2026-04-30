# ピー助（通常立ち絵プロンプト集）

**キャラID**: `pisuke`
**参照**:
- `style_guide.md`、`character_sheet.md` の `pisuke` 項
- 画風参照画像: `references/ref_pisuke.png`（後日配置）

**登場形態**:
- **Stage1 前半のみ**: ヨウム姿で画面に登場（姿あり）
- **Stage1 後半以降**: 透明化、**姿は描かれない**（声のみのためプロンプト不要）

本ファイルは **Stage1 前半の6ポートレート**（`char08_st1_001〜006`）のみを扱う。

**ネガティブプロンプト**（全プロンプト共通）:
```
lowres, bad anatomy, cropped, worst quality, low quality, jpeg artifacts,
signature, watermark, text, blurry, humans, people, girl, boy,
cute cartoon style, too big body proportion
```

---

## 基本タグ（共通）

```
african grey parrot, medium sized parrot, grey feathers,
red tail feathers, black curved beak, bright yellow eyes,
mischievous cunning gaze, anthropomorphic intelligence,
no humans
```

---

## ステージ1・前半（姿あり）

### char08_st1_001（登場・上空から降下）

**シーン**: ステージ1冒頭、ギルド通りにいきなり登場。
**表情・状態**: 挑発的なゲコ顔、羽を広げて降下中

```
masterpiece, best quality, very aesthetic, absurdres,
african grey parrot, medium sized parrot, grey feathers,
red tail feathers, black curved beak, bright yellow eyes,
(wings spread descending from above, smug taunting expression,
beak slightly open as if speaking, sharp cunning eyes),
dynamic descending pose, outdoor daylight,
simple background, plain white background, no humans
```

### char08_st1_001b（頭上接近・「鳥と一緒にすんな」）

**シーン**: サトシの頭上付近まで接近、反転描写。
**表情・状態**: 挑発的に近づく、嘴を開けて文句を言う

```
masterpiece, best quality, very aesthetic, absurdres,
african grey parrot, grey feathers, red tail feathers, 
black beak open talking, bright yellow angry eyes,
(close to camera, talking back indignantly, ruffled feathers
of annoyance, one wing gesturing), midair pose,
outdoor daylight, simple background, plain white background, no humans
```

### char08_st1_002（「バグみたいな存在」・説明）

**シーン**: チップ説明を始める、解説モード。
**表情・状態**: 頭を垂れて解説、真面目顔

```
masterpiece, best quality, very aesthetic, absurdres,
african grey parrot, grey feathers, red tail feathers,
black beak, bright yellow eyes, (lowered head lecturing pose,
thoughtful explaining expression, one wing slightly extended
like a professor, serious intelligent look), explanation mode,
outdoor daylight, simple background, plain white background, no humans
```

### char08_st1_003（「演算核」・真面目）

**シーン**: チップの内部構造を語る、学者モード。
**表情・状態**: 真面目顔、目を細めて語る

```
masterpiece, best quality, very aesthetic, absurdres,
african grey parrot, grey feathers, red tail feathers,
black beak, bright yellow eyes, (scholarly serious expression,
narrowed focused eyes, beak half open in speech,
dignified explaining pose), outdoor daylight,
simple background, plain white background, no humans
```

### char08_st1_004（「ほう」・感心）

**シーン**: サトシの理系的気づきに感心する。
**表情・状態**: 感心した顎引き、目を丸くする

```
masterpiece, best quality, very aesthetic, absurdres,
african grey parrot, grey feathers, red tail feathers,
black beak, bright yellow eyes, (impressed expression,
head tilted slightly in admiration, wide curious eyes,
beak closed in thought), outdoor daylight,
simple background, plain white background, no humans
```

### char08_st1_005（「書き換えだって」・得意げ）

**シーン**: 自分の実力を誇示する、胸を張るモード。
**表情・状態**: 胸を張って自慢、嘴を上向け

```
masterpiece, best quality, very aesthetic, absurdres,
african grey parrot, grey feathers, red tail feathers,
black beak pointed up, bright yellow eyes, (puffed up proud chest,
wings slightly lifted in boast, smug confident expression,
beak raised with self-satisfaction), outdoor daylight,
simple background, plain white background, no humans
```

### char08_st1_006（「やれ、サトシ！」・嬉々）

**シーン**: サトシのパッチ実行を煽る、悪戯心満点。
**表情・状態**: 嬉々とした悪戯顔、翼を広げる

```
masterpiece, best quality, very aesthetic, absurdres,
african grey parrot, grey feathers, red tail feathers,
black beak open excited, bright yellow gleaming eyes,
(gleeful wicked expression, wings spread in excitement,
eyes glinting with mischief, beak open in enthusiastic shout),
dynamic cheering pose, outdoor daylight,
simple background, plain white background, no humans
```

---

## 透明化後（`Stage1 後半以降`）

**姿なし。声のみの吹き出し表示**。
- 画像生成の対象外
- シナリオ本文上は「ピー助:（小声）」として台詞のみ表示
- UI上は吹き出しの左下／右下に配置される（サトシの肩にいる想定）
