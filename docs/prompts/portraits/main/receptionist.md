# 受付嬢リーゼ（通常立ち絵プロンプト集）

**キャラID**: `receptionist`
**本名**: リーゼ（`Liese`）／通常呼称は「受付嬢」
**参照**:
- `style_guide.md`、`character_sheet.md` の `receptionist` 項
- 画風参照画像: `references/ref_receptionist.png`（後日配置）

**登場範囲**: ステージ1〜ステージ7、サブイベ1〜4の全章で受付業務として登場。
サブイベ4ではバトル立ち絵として戦闘もあるが、それは `portraits/battle/receptionist_battle.md` に別ファイル。

本ファイルは受付カウンターでの立ち絵バリエーションを扱う。

**ネガティブプロンプト**（共通）:
```
lowres, bad anatomy, bad hands, missing fingers, extra digits,
cropped, worst quality, low quality, jpeg artifacts,
signature, watermark, text, blurry, bad proportions, deformed,
multiple girls, boy, man, male, old, child, loli
```

---

## 基本タグ（共通）

```
1girl, solo, young adult, mid twenties, adult,
western features, platinum blonde long hair,
half-up hairstyle or low ponytail, ice blue eyes,
sharp expressionless eyes, pale porcelain skin,
slender tall elegant figure, guild receptionist uniform,
navy vest over white blouse, tight knee skirt, white gloves,
silver guild emblem brooch on chest,
cold professional aura
```

---

## 受付業務の共通構図

背景: ギルドカウンター前（書類、羽ペン、帳面、ランプ等が見える想定）
照明: `warm cozy guild interior lighting`

---

## 受付嬢の表情バリエーション（`char10_st1_XXX`）

### char10_st1_001（基本・無愛想・通常業務顔）

**シーン**: 全章で最頻出の基本顔。無表情、事務的。

```
masterpiece, best quality, very aesthetic, absurdres,
1girl, solo, young adult, western features, platinum blonde long hair,
half-up hairstyle, ice blue sharp eyes, pale skin, slender,
navy vest, white blouse, tight skirt, white gloves,
upper body shot behind counter, (neutral expressionless face,
flat professional gaze, mouth in straight line, emotionless),
default work pose, warm guild interior lighting,
simple background, plain white background
```

### char10_st1_002（事務的半目・「何かご用」）

```
masterpiece, best quality, very aesthetic, absurdres,
1girl, solo, young adult, platinum blonde long hair, half-up,
ice blue eyes, pale skin, guild uniform, upper body shot,
(half-lidded bureaucratic eyes, slightly lowered eyelids,
mouth barely moving, flat businesslike expression,
document in hand), warm guild interior lighting,
simple background, plain white background
```

### char10_st1_003（冷たい丁寧・「魔力水晶に触れて」）

**シーン**: 事務的に手順を説明する、冷たい笑みなし。

```
masterpiece, best quality, very aesthetic, absurdres,
1girl, solo, young adult, platinum blonde long hair, half-up,
ice blue eyes, pale skin, guild uniform, upper body shot,
(polite professional expression, slight formal nod,
gesturing with one gloved hand, mouth speaking words,
icy courteous demeanor), warm guild interior lighting,
simple background, plain white background
```

### char10_st1_004（ジト目・「犯罪歴は、ない」）

**シーン**: サトシを疑いの目で見る、帳面を指でなぞる。

```
masterpiece, best quality, very aesthetic, absurdres,
1girl, solo, young adult, platinum blonde long hair, half-up,
ice blue eyes, pale skin, guild uniform, upper body shot,
(suspicious narrowed half-lidded eyes, unconvinced flat mouth,
one finger tapping ledger meaningfully, doubtful scrutinizing gaze),
warm guild interior lighting,
simple background, plain white background
```

### char10_st1_005（カウンター置き・「冒険者証」）

**シーン**: 物を受付嬢がカウンターに置くが、サトシ側には押しやらない。

```
masterpiece, best quality, very aesthetic, absurdres,
1girl, solo, young adult, platinum blonde long hair, half-up,
ice blue eyes, pale skin, guild uniform, upper body shot,
(placing item on counter with pinched fingers, expressionless
distance maintained, mouth slightly parted speaking,
polite but cold gesture), warm guild interior lighting,
simple background, plain white background
```

---

## サブイベ4・エピローグ関連の微笑バリエーション

サブイベ4で初めて「わずかな微笑」を見せ、stage7 エンディングでも類似の微笑を見せる。
これらは通常立ち絵のバリエーションとして記述。

### recep_smile_001（ステージ7・初めての微笑）

**シーン**: stage7 場面2、エンディングで初めて見せるわずかな微笑。
**表情・状態**: 表情はほぼ変わらないが確かに微笑んでいる

```
masterpiece, best quality, very aesthetic, absurdres,
1girl, solo, young adult, platinum blonde long hair, half-up,
ice blue eyes slightly softened, pale skin, guild uniform,
upper body shot, (very subtle faint smile, corners of mouth
just barely turned up, eyes showing the tiniest warmth,
expression nearly unchanged but definitely smiling),
warm guild interior lighting,
simple background, plain white background
```

### recep_warm_001（ステージ7・わずかな賞賛）

**シーン**: stage7 場面2、「卑怯だが誠実な王」の民の声を伝える時のわずかな表情。

```
masterpiece, best quality, very aesthetic, absurdres,
1girl, solo, young adult, platinum blonde long hair, half-up,
ice blue eyes, pale skin, guild uniform, upper body shot,
(slight softened expression, mouth in hint of pleased curve,
subtle approving gaze, gentle dignified demeanor),
warm guild interior lighting,
simple background, plain white background
```

### recep_smile_002〜006（サブイベ4・決着後の微笑バリエーション）

サブイベ4 場面4で受付嬢が見せる表情差分。共通ベース＋差分タグ:

- **recep_smile_002（冗談顔）**: `(teasing slight smirk, eyes still cold but mouth playful, faint amused curve)`
- **recep_smile_003（真剣顔）**: `(composed earnest expression, formal posture, significant gaze)`
- **recep_smile_004（認める温もり）**: `(rare warm acknowledgment, slight nod, professional approval with hidden warmth)`
- **recep_smile_005（淡々と皮肉）**: `(deadpan ironic expression, slight head tilt, dry wit in eyes)`
- **recep_smile_006（怖い微笑）**: `(unsettling calm smile, eyes not matching mouth, possessive guardian aura)`

各バリエーションのプロンプトベース:
```
masterpiece, best quality, very aesthetic, absurdres,
1girl, solo, young adult, platinum blonde long hair, half-up,
ice blue eyes, pale skin, guild uniform, upper body shot,
[上記差分タグ], warm guild interior lighting,
simple background, plain white background
```

---

## サブイベ4・敗北直後の乱れた姿（受付嬢脱衣の残滓）

サブイベ4 場面4 で最後のカードを失った直後、頬を赤らめ制服のボタンを一つ外している姿。
（バトル立ち絵と重複するが、会話立ち絵としても使う）

### recep_defeat_001（最後のカード喪失・決着直後）

```
masterpiece, best quality, very aesthetic, absurdres,
1girl, solo, young adult, platinum blonde long hair,
(slightly disheveled strand falling on cheek), ice blue eyes,
pale skin, (guild uniform with one top button undone,
vest slightly loosened), upper body shot, 
(flushed cheeks with slight blush, half-lidded defeated but
dignified eyes, mouth in quiet resignation, maintaining poise
despite the loss), warm guild interior lighting,
simple background, plain white background
```

### recep_defeat_002〜012（敗北後の会話バリエーション）

共通ベース（乱れた制服姿）:
```
masterpiece, best quality, very aesthetic, absurdres,
1girl, solo, young adult, platinum blonde long hair,
ice blue eyes, pale skin, (guild uniform with one top button
undone from match, slight disarray), upper body shot,
[差分タグ], warm guild interior lighting,
simple background, plain white background
```

差分タグの要旨（番号順）:
- recep_defeat_002: `(adjusting uniform back to normal, composed recovery)`
- recep_defeat_003: `(formal verdict expression, resolute professional)`
- recep_defeat_004: `(faint "but" gesture, raised finger of caveat)`
- recep_defeat_005: `(stern record-making face, pen to ledger)`
- recep_defeat_006: `(quiet listening expression, attentive stillness)`
- recep_defeat_007: `(distant reminiscing gaze, melancholy serene)`
- recep_defeat_008: `(self-mocking faint smile, slight bitter humor)`
- recep_defeat_009: `(silent with wavering pupils, unspoken emotion)`
- recep_defeat_010: `(eyes trembling, holding back something)`
- recep_defeat_011: `(snapping back to ledger, professional mask restored)`
- recep_defeat_012: `(teasing ledger-raised face, mischievous professional)`
