# サトシ（バトル立ち絵プロンプト集）

**キャラID**: `satoshi`
**参照**: `character_sheet.md` の `satoshi` 項、`style_guide.md`

**登場範囲**: 全バトルシーンで「サトシ側」の立ち絵として使用。
**共通衣装**: 各章の通常立ち絵と同じ衣装（麻の服＋冒険者装備）。バトル立ち絵では
**サトシは脱衣対象ではない**（男性キャラで野球拳の相手）。

**ネガティブプロンプト**（共通）:
```
lowres, bad anatomy, bad hands, missing fingers, extra digits,
cropped, worst quality, low quality, jpeg artifacts,
signature, watermark, text, blurry, bad proportions, deformed,
multiple boys, girl, woman, female, old, child
```

---

## 基本タグ（共通）

```
1boy, solo, young adult, japanese, black messy short hair,
dark brown eyes, slim build, pale skin, rough linen shirt,
leather chest armor, belt, leather pouch, 
battle stance, determined focused expression,
bayes-eye activation glow in right eye (optional, subtle)
```

---

## 章別バトル立ち絵

### プロローグ（マチルダ戦／バトル立ち絵なし）

プロローグのマチルダ戦では、サトシのバトル立ち絵は実装上使用されていない。
（マチルダ側のバトル立ち絵のみ使用。サトシは主観視点扱い）

本ファイルではサトシのバトル立ち絵が実装された章のみ記述する。

---

### ステージ1（冒険者A戦）- `char01_st1_battle_XXX`

**衣装**: 麻の服（冒険者装備なしのまだ駆け出し）

#### char01_st1_battle_001（冒険者A戦・構え）

```
masterpiece, best quality, very aesthetic, absurdres,
1boy, solo, young adult, japanese, black messy short hair,
dark brown eyes, slim build, pale skin, rough linen shirt,
rough linen pants, upper body battle stance,
(nervous determined expression, hands up in guard pose,
slightly sweating, focus), warm guild interior lighting,
simple background, plain white background
```

---

### ステージ2（レイラ戦）- `char01_stg2_battle_XXX`

**衣装**: 麻の服＋革の胸当て＋ベルト＋革ポーチ

共通ベース:
```
masterpiece, best quality, very aesthetic, absurdres,
1boy, solo, young adult, japanese, black messy short hair,
dark brown eyes, slim build, pale skin, rough linen shirt,
leather chest armor, upper body shot, dim candle light,
simple background, plain white background
```

- char01_stg2_battle_001: `(confused struggling focus, warped vision effect, slow reflexes from poison, sweating)`
- char01_stg2_battle_002: `(shaken defeat reaction, eyes wandering unsure)`
- char01_stg2_battle_003: `(deeper confusion cold sweat, trying to focus but failing)`
- char01_stg2_battle_004: `(pale overwhelmed, holding head, defeat processing)`
- char01_stg2_battle_010: `(sharp focused tactician face, bayes-eye glowing subtly)`
- char01_stg2_battle_101: `(calm interrogator smile, ice-cold confidence, pisuke voice mode)`
- char01_stg2_battle_102〜103: `(cold relentless pressing finish, calculated dominance)`

---

### ステージ3（マグダレナ戦）- `char01_stg3_battle_XXX`

共通ベース:
```
masterpiece, best quality, very aesthetic, absurdres,
1boy, solo, young adult, japanese, black messy short hair,
dark brown eyes, slim build, pale skin, rough linen shirt,
leather armor, upper body shot, colorful stained glass light,
simple background, plain white background
```

- char01_stg3_battle_001: `(blinded squinting hand raised, lost in white light of faith)`
- char01_stg3_battle_002: `(defeated head lowered despair under light)`
- char01_stg3_battle_010: `(calm composed holding book up, prepared counter, knowing smile)`
- char01_stg3_battle_011: `(solemn revealing book to target, dramatic reveal)`
- char01_stg3_battle_012: `(cool confident bayes-eye active, tactical victory)`
- char01_stg3_battle_013: `(second book out, calm relentless)`
- char01_stg3_battle_014: `(third book out, finishing blow calm)`
- char01_stg3_battle_015: `(offering deal quiet resolve, firm but merciful)`

---

### ステージ4（セレス戦）- `char01_stg4_battle_XXX`

共通ベース:
```
masterpiece, best quality, very aesthetic, absurdres,
1boy, solo, young adult, japanese, black messy short hair,
dark brown eyes, slim build, pale skin, rough linen shirt,
leather armor, upper body shot, cold fluorescent lighting,
(magical chains visible on wrist for restriction scenes),
simple background, plain white background
```

- char01_stg4_battle_001: `(chains on wrists struggling, horrified restriction)`
- char01_stg4_battle_002: `(panic internal scream, locked into losing hand)`
- char01_stg4_battle_003: `(frantic sweating forced choice, desperate time pressure)`
- char01_stg4_battle_004: `(gritted teeth dead-end frustration)`
- char01_stg4_battle_010: `(focused minigame operator, side profile concentration)`
- char01_stg4_battle_011: `(calm command voice pisuke mode, cold tactician)`
- char01_stg4_battle_020: `(calm reading move bayes-eye active, chains gone)`

---

### ステージ5（フェリア戦）- `char01_stg5_battle_XXX`

共通ベース:
```
masterpiece, best quality, very aesthetic, absurdres,
1boy, solo, young adult, japanese, black messy short hair,
dark brown eyes, slim build, pale skin, rough linen shirt,
leather armor, upper body shot, outdoor sunlight training ground,
simple background, plain white background
```

- char01_stg5_battle_001: `(shocked helpless at platinum card override, platinum glow overwhelming)`
- char01_stg5_battle_002: `(gritting teeth second loss)`
- char01_stg5_battle_003: `(despair head down third loss, knees bending)`
- char01_stg5_battle_010: `(tense walk down corridor, anxious approaching arena)`
- char01_stg5_battle_011〜015: `(increasingly panicked face as mysterious cards appear, shouted confusion)`
- char01_stg5_battle_016〜018: `(panicked pisuke is operating, helpless protesting)`
- char01_stg5_battle_020: `(calm bayes-eye active, victorious reading without platinum)`
- char01_stg5_battle_021: `(calm executing deletion request, honorable cleanup)`

---

### ステージ6（王女戦）- `char01_stg6_battle_XXX`

**衣装**: 借り物の礼装（白シャツ＋ジャケット＋ボウタイ）。場面6の最悪マナーで裾めくり状態。

共通ベース（礼装）:
```
masterpiece, best quality, very aesthetic, absurdres,
1boy, solo, young adult, japanese, black messy short hair,
dark brown eyes, slim build, pale skin, borrowed formal attire,
white dress shirt, ill-fitting jacket, bow tie, upper body shot,
golden chandelier light, grand banquet hall atmosphere,
simple background, plain white background
```

- char01_stg6_battle_001〜001c: `(forced loss poses, increasingly despaired, "imperial decree" defeat)`
- char01_stg6_battle_010〜012: `(resolve-gauge minigame phase, intense concentration, memories flooding)`
- char01_stg6_battle_020〜022: `(post-taboo-manner battle, flushed but focused, bayes-eye active)`

---

### サブイベント系（`char01_sv3_battle_XXX`, `char01_sv4_battle_XXX`）

共通ベース:
```
masterpiece, best quality, very aesthetic, absurdres,
1boy, solo, young adult, japanese, black messy short hair,
dark brown eyes, slim build, pale skin, rough linen shirt,
leather armor, upper body shot, [場面照明],
simple background, plain white background
```

- char01_sv3_battle_001: `(focused fight against cursed armor, bayes-eye active, determined)`
- char01_sv4_battle_001: `(intense focus against receptionist, bayes-eye flicker, under pressure)`

---

## 備考

- サトシは男性キャラのため**脱衣段階なし**
- バトル立ち絵は「戦闘中の集中顔」と「勝利／敗北リアクション」が主
- 一部章では「ピー助声色モード」（冷静な指摘顔／操り人形風）が特殊
- 詳細は各シーンに応じて`character_sheet.md`のサトシ項＋シーン差分で生成
