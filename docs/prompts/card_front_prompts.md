# カード表面：生成プロンプト

全15種（3種類の手 × 5グレード）を収める、Nano Banana向け英語プロンプト集。
現在は、基準となるノーマルのグー・チョキ・パーだけを収録している。この3枚の構図と画風を確定した後、承認済みの各画像を参照画像として、同じファイルに上位4グレードのプロンプトを追記する。

## 共通方針

- 出力は**カード表面のデザイン1枚だけ**。人物、手札、机、背景、カードを持つ手、複数カードは入れない。
- カードは縦長2:3、正面視、全体が余白なく画面内に収まる。ゲームUIに直接使うフラットな2Dアセットにする。
- 裏面（`card_back.png`）と調和する、明るいアイボリー〜羊皮紙の地色、濃紺の枠、くすんだ深紅と控えめな古金のアクセントによる王家風トランプ意匠とする。
- ノーマルは最も素朴な格。上位グレードを作る余地を残し、過剰な金箔、宝石、強い発光、豪奢な装飾は使わない。
- 生成AIの文字崩れを避けるため、英単語・数字・ランク名・説明文・疑似文字は一切入れない。手の種類は中央絵だけで明確に判別できるようにする。

## グー：ノーマル（ベースデザイン比較）

明るい背景を基調にした5案。まず各案を個別に生成して1案を採用し、選んだ意匠をチョキ・パーと上位4グレードの共通基準にする。

### 案1：王国の紋章札

**コンセプト**: 王国公認の決闘札。端正な羊皮紙と王家の装飾による、もっとも正統派の基準案。

**画像ファイル候補**: `rock_normal.png`

```text
Create one complete front-face design for a NORMAL-grade fantasy rock-paper-scissors card representing ROCK. Portrait 2:3 trading-card proportion, the full card visible straight-on, no surrounding scene, no hand holding the card, no other cards. Flat 2D game UI asset, crisp anime-inspired fantasy illustration, clean ink lines, subtle paper texture.

Use a warm light-ivory parchment card field with subtle fibers and a gently aged printed texture. Add a midnight-navy outer border, a fine navy inner frame, restrained muted-crimson accent lines, and only small touches of dull antique gold. Match an elegant royal European playing-card aesthetic: simple corner ornaments and a large central illustration panel. Keep the frame identical in structure and visual weight to a matching SCISSORS card and PAPER card. The NORMAL grade must look humble and mass-issued: printed ink and aged card stock, no gemstones, no shiny gold foil, no glow, no ornate crown.

At the top center of the card, add one small, crisp, clearly readable uppercase serif title: "ROCK". This is the only text on the card. Do not include "NORMAL", any grade name, numbers, subtitles, or additional lettering.

In the center, depict one powerful closed fist made of rough gray stone, angled slightly upward, with a few small stone chips. The fist must be immediately recognizable as the rock hand gesture, not a weapon, not a character, not a realistic human hand. Give it a strong graphic silhouette and a restrained heraldic illustration style. Leave clean light parchment breathing room around the central motif. Do not place any red halo, red shadow, red glow, or colored backdrop behind the fist.

No text or letters except the exact title "ROCK" at the top. No "NORMAL", grade names, numbers, rank labels, readable runes, logos, watermarks, playing-card suits, crowns, characters, faces, full human bodies, weapons, scissors, parchment sheets, glowing magic, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### 案2：石版の拳

**コンセプト**: グーを「岩の力」として最も分かりやすく見せる。石灰岩の明るい地色と、石彫りの力強さを使う。

**画像ファイル候補**: `rock_normal_concept_2.png`

```text
Create one complete front-face design for a NORMAL-grade fantasy rock-paper-scissors card representing ROCK. Portrait 2:3 trading-card proportion, full card visible straight-on, no surrounding scene, no hand holding the card, no other cards. Flat 2D game UI asset, crisp anime-inspired fantasy illustration, clean dark ink lines, subtle print texture.

Use a pale limestone-gray and warm ivory background, like a lightly weathered carved stone tablet. Build a simple, slim midnight-navy frame with small flat engraved geometric marks at the corners, thin muted-crimson accent lines, and only a few dull antique-gold lines. The corner ornaments must be subtle 2D line engravings integrated into the border: no large beveled stone blocks, no chunky 3D corner caps, no heavy architectural frame. The NORMAL grade must feel sturdy, common, and practical: matte ink, worn card stock, no gems, no bright foil, no magical glow, no royal crown. Keep generous clear space and strong contrast so the card is readable at small size.

At the center, depict one large closed fist formed from layered rough gray stones, with a few controlled cracks and several small floating stone chips. It should clearly read as the rock hand gesture through its knuckle silhouette, while still feeling like a carved emblem. Use a limited palette of cool gray, charcoal, ivory, and a tiny muted-red accent. The central stone fist should be bold, graphic, centered, and enclosed by a subtle oval stone-carving panel.

No text, letters, numbers, rank labels, readable runes, logos, watermarks, playing-card suits, crowns, characters, faces, full human bodies, weapons, metal scissors, open palms, parchment sheets, glowing magic, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### 案3：騎士のガントレット

**コンセプト**: 決闘の正式さを、騎士の鉄籠手で表す。上品で人物カードにも馴染む意匠。

**画像ファイル候補**: `rock_normal_concept_3.png`

```text
Create one complete front-face design for a NORMAL-grade fantasy rock-paper-scissors card representing ROCK. Portrait 2:3 trading-card proportion, full card visible straight-on, no surrounding scene, no hand holding the card, no other cards. Flat 2D game UI asset, crisp anime-inspired fantasy illustration, clean ink lines, restrained parchment texture.

Use a soft cream and pale parchment background with a simple midnight-navy double-line frame. Add small muted-crimson diamond accents at the corners and very restrained dull-antique-gold details, matching an elegant royal European playing-card style. The NORMAL grade must look like an affordable standard issue card: flat printed inks, modest decoration, no gems, no polished gold foil, no glow, no ornate crown. Preserve wide light-colored negative space around the main illustration.

At the center, depict one closed fist wearing a plain medieval iron gauntlet with simple segmented knuckles and an ivory cloth cuff. The gauntlet is matte gray, slightly worn, and boldly outlined; it is an emblematic rock hand gesture, not a weapon and not attached to a visible person. Place it over a very subtle pale-blue shield-shaped backdrop, with a small muted-red ribbon-like ornamental mark beneath it. The result should feel heraldic, dignified, simple, and immediately readable.

No text, letters, numbers, rank labels, readable runes, logos, watermarks, playing-card suits, crowns, characters, faces, full human bodies, weapons, metal scissors, open palms, parchment sheets, glowing magic, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### 案4：ギルド印刷札

**コンセプト**: 冒険者ギルドで日常的に使われる、版画調の実用品。小さな表示でも拳の形が読み取りやすい。

**画像ファイル候補**: `rock_normal_concept_4.png`

```text
Create one complete front-face design for a NORMAL-grade fantasy rock-paper-scissors card representing ROCK. Portrait 2:3 trading-card proportion, full card visible straight-on, no surrounding scene, no hand holding the card, no other cards. Flat 2D game UI asset, bold vintage woodcut illustration, clean anime-inspired fantasy shapes, visible but subtle paper grain.

Use an unbleached light-cream paper background with dark forest-navy ink, a thick simple rectangular border, and sparse muted brick-red stamp-like accents. Add no more than a few dull brass-colored line details. The card should feel like a durable, widely circulated adventurers' guild game card printed with a wooden press: friendly, practical, slightly imperfect, and highly legible. The NORMAL grade must remain modest, with no gems, shiny foil, elaborate royal decoration, or magical glow.

At the center, depict one large simplified closed fist in a strong woodcut silhouette, made from solid charcoal-gray shapes with ivory highlight cuts. Frame it inside a simple octagonal guild-seal outline. Add two tiny decorative sprigs beneath the seal, but keep the composition open and uncluttered. The fist must unmistakably communicate the rock hand gesture, not a character, not a weapon, and not a realistic human hand study.

No text, letters, numbers, rank labels, readable runes, logos, watermarks, playing-card suits, crowns, characters, faces, full human bodies, weapons, metal scissors, open palms, parchment sheets, glowing magic, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### 案5：朝光の拳

**コンセプト**: 明るく神秘的なファンタジー感を持つ案。背景を乳白色〜淡い水色にして、ノーマルでも印象を残す。

**画像ファイル候補**: `rock_normal_concept_5.png`

```text
Create one complete front-face design for a NORMAL-grade fantasy rock-paper-scissors card representing ROCK. Portrait 2:3 trading-card proportion, full card visible straight-on, no surrounding scene, no hand holding the card, no other cards. Flat 2D game UI asset, crisp anime-inspired fantasy illustration, clean linework, soft printed-paper texture.

Use a luminous but non-glowing pearl-white and very pale sky-blue background, with a clean midnight-navy border and thin muted-crimson decorative accents. Add only small dull-antique-gold linework, like a restrained sunrise motif at the top and bottom of the frame. The NORMAL grade must remain simple and affordable: matte printed inks, modest ornament, no gemstones, no shiny gold foil, no bright magical effects, no ornate crown. Keep the background light, calm, and spacious.

At the center, depict one solid gray stone fist with a strong clear knuckle silhouette, raised slightly upward. Behind it, place a subtle pale-gold radial sunburst made of broad printed lines, not magical light. The stone fist remains the dominant element, and the radiating motif only provides an optimistic fantasy-card atmosphere. Use a graphic, emblem-like composition with enough empty space to stay readable at small UI size.

No text, letters, numbers, rank labels, readable runes, logos, watermarks, playing-card suits, crowns, characters, faces, full human bodies, weapons, metal scissors, open palms, parchment sheets, glowing magic, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

## チョキ：ノーマル（案1・案2）

### 案1：王国の紋章札

**画像ファイル候補**: `scissors_normal_concept_1.png`

```text
Using the attached approved NORMAL ROCK card as a mandatory visual reference, create its matching NORMAL-grade fantasy rock-paper-scissors card representing SCISSORS. Preserve the reference card's exact portrait 2:3 proportion, light parchment field, midnight-navy outer and inner border structure, corner ornaments, line weight, limited ivory/navy/muted-crimson/antique-gold palette, paper texture, and flat 2D anime-fantasy print style. Change only the central hand gesture from ROCK to SCISSORS. The full card must be visible straight-on, with no surrounding scene, no hand holding the card, and no other cards.

Keep the frame and all non-central elements visually identical to the attached ROCK reference card. The NORMAL grade must look humble and mass-issued: printed ink and aged card stock, no gemstones, no shiny gold foil, no glow, no ornate crown.

At the top center of the card, add one small, crisp, clearly readable uppercase serif title: "SCISSORS". This is the only text on the card. Do not include "NORMAL", any grade name, numbers, subtitles, or additional lettering.

In the center, depict a clear V-shaped scissors hand gesture carved from rough gray stone: index finger and middle finger extended, the other fingers folded, with a simple stone cuff. Use the same chunky stone planes, controlled cracks, and graphic inked contours as the matching ROCK concept 1 card. The gesture must be immediately recognizable as scissors, not a metal cutting tool, not a weapon, not a character, not a glove, and not a realistic anatomical study. Give it a strong graphic silhouette and a restrained heraldic illustration style. Leave clean light parchment breathing room around the central motif. Do not place any red halo, red shadow, red glow, or colored backdrop behind the hand.

No text or letters except the exact title "SCISSORS" at the top. No "NORMAL", grade names, numbers, rank labels, readable runes, logos, watermarks, playing-card suits, crowns, characters, faces, full human bodies, weapons, metal scissors, stone fists, open palms, parchment sheets, glowing magic, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### 案2：石版の拳と同系統の石版札

**画像ファイル候補**: `scissors_normal_concept_2.png`

```text
Create one complete front-face design for a NORMAL-grade fantasy rock-paper-scissors card representing SCISSORS. Portrait 2:3 trading-card proportion, full card visible straight-on, no surrounding scene, no hand holding the card, no other cards. Flat 2D game UI asset, crisp anime-inspired fantasy illustration, clean dark ink lines, subtle print texture.

Use a pale limestone-gray and warm ivory background, like a lightly weathered carved stone tablet. Build a simple, slim midnight-navy frame with small flat engraved geometric marks at the corners, thin muted-crimson accent lines, and only a few dull antique-gold lines. The corner ornaments must be subtle 2D line engravings integrated into the border: no large beveled stone blocks, no chunky 3D corner caps, no heavy architectural frame. Keep the frame identical in structure and visual weight to the matching ROCK concept 2 card and PAPER concept 2 card. The NORMAL grade must feel sturdy, common, and practical: matte ink, worn card stock, no gems, no bright foil, no magical glow, no royal crown. Keep generous clear space and strong contrast so the card is readable at small size.

At the center, depict a clear V-shaped scissors hand gesture as a solid, raised stone sculpture: index finger and middle finger extended, other fingers folded. Use bold simplified faceted stone planes, a thick consistent dark outline, controlled cracks, and a few tiny stone chips, matching the visual weight of the ROCK concept 2 card. It must clearly read as the scissors hand gesture, not metal scissors, not a weapon, not a character, not a glove, and not an anatomical study. Enclose the motif in a subtle oval stone-carving panel with clean pale space behind the hand, without a red halo or colored backdrop.

No text, letters, numbers, rank labels, readable runes, logos, watermarks, playing-card suits, crowns, characters, faces, full human bodies, weapons, metal scissors, closed fists, open palms, parchment sheets, glowing magic, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

## パー：ノーマル（案1・案2）

### 案1：王国の紋章札

**画像ファイル候補**: `paper_normal_concept_1.png`

```text
Edit the attached approved NORMAL ROCK card image; do not create a new card from scratch. Preserve every part of the source image exactly: portrait 2:3 crop, outer and inner border, corner ornaments, parchment background, paper grain, colors, line weight, lighting, card edges, central panel size, and all spacing. Do not redesign, restyle, move, crop, add, or remove anything outside the two explicitly requested edits below.

Make only these two edits: (1) replace the top title "ROCK" with the exact uppercase serif title "PAPER", in exactly the same position, size, color, and type style; (2) replace only the central stone-fist illustration with the stone open-palm illustration specified below. This remains a humble NORMAL-grade card: no gems, no shiny gold foil, no glow, and no ornate crown.

In the center, depict one open palm carved from rough gray stone, facing forward, with five naturally spread fingers and a simple stone cuff, angled slightly upward. Use the same chunky stone planes, controlled cracks, and graphic inked contours as the matching ROCK concept 1 card. The gesture must be immediately recognizable as the paper hand gesture, not a parchment sheet, not a character, not a glove, and not a realistic anatomical study. Give it a strong graphic silhouette and a restrained heraldic illustration style. Leave clean light parchment breathing room around the central motif. Do not place any red halo, red shadow, red glow, or colored backdrop behind the hand.

No text or letters except the exact title "PAPER" at the top. No "NORMAL", grade names, numbers, rank labels, readable runes, logos, watermarks, playing-card suits, crowns, characters, faces, full human bodies, weapons, metal scissors, stone fists, V-shaped hand gestures, parchment sheets, glowing magic, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### 案2：石版の拳と同系統の石版札

**画像ファイル候補**: `paper_normal_concept_2.png`

```text
Create one complete front-face design for a NORMAL-grade fantasy rock-paper-scissors card representing PAPER. Portrait 2:3 trading-card proportion, full card visible straight-on, no surrounding scene, no hand holding the card, no other cards. Flat 2D game UI asset, crisp anime-inspired fantasy illustration, clean dark ink lines, subtle print texture.

Use a pale limestone-gray and warm ivory background, like a lightly weathered carved stone tablet. Build a simple, slim midnight-navy frame with small flat engraved geometric marks at the corners, thin muted-crimson accent lines, and only a few dull antique-gold lines. The corner ornaments must be subtle 2D line engravings integrated into the border: no large beveled stone blocks, no chunky 3D corner caps, no heavy architectural frame. Keep the frame identical in structure and visual weight to the matching ROCK concept 2 card and SCISSORS concept 2 card. The NORMAL grade must feel sturdy, common, and practical: matte ink, worn card stock, no gems, no bright foil, no magical glow, no royal crown. Keep generous clear space and strong contrast so the card is readable at small size.

At the center, depict one open palm facing forward as a solid, raised stone sculpture, with five clearly separated naturally spread fingers and a simple stone cuff. Use bold simplified faceted stone planes, a thick consistent dark outline, controlled cracks, and a few tiny stone chips, matching the visual weight of the ROCK concept 2 card. It must clearly read as the paper hand gesture, not a parchment sheet, not a character, not a glove, and not an anatomical study. Enclose the motif in a subtle oval stone-carving panel that matches the other concept 2 cards. Keep clean pale space behind the palm, with no red halo or colored backdrop.

No text, letters, numbers, rank labels, readable runes, logos, watermarks, playing-card suits, crowns, characters, faces, full human bodies, weapons, metal scissors, closed fists, V-shaped hand gestures, parchment sheets, glowing magic, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

## ノーマル格章の追加（編集）

各ノーマルカードに、下部中央の1個の灰色菱形格章だけを追加するための編集プロンプト。まずグーで位置・大きさ・見え方を確定し、採用後にチョキとパーへ同じ編集を行う。

### グー：ノーマル格章

```text
Edit the attached approved NORMAL ROCK card image; do not create a new card from scratch. Preserve every existing part of the source image exactly: the portrait 2:3 crop, the "ROCK" title and its typography, all outer and inner borders, corner ornaments, parchment background, stone fist, floating stone chips, color palette, line weight, texture, lighting, and spacing. Do not redraw, move, resize, recolor, restyle, add, or remove anything else.

Make exactly one change: add one very small, flat slate-gray diamond-shaped rank emblem in the open parchment area below the stone fist. Center it horizontally, position it clearly above the bottom inner navy border with a visible gap of at least two emblem heights, and do not let it touch or overlap any frame line. The emblem must be a compact vertical rhombus: sharply pointed at the top and bottom, with a height about 1.4 times its width. It must not be a square and must not be a horizontal lozenge. Make it only about 3 percent of the total card height, with a thin dark-navy outline and a subtle matte stone texture. It must read as a quiet, independent single rank badge, not as a border decoration, text, a jewel, a button, a playing-card suit, or a glowing magical symbol. Leave sufficient blank space to its left and right for future higher-grade cards to display additional matching vertical diamonds in a horizontal row. Match the existing card's printed illustration style.

No text or letters other than the existing exact title "ROCK". Do not add "NORMAL", "BRONZE", numbers, grade names, subtitles, extra symbols, extra diamonds, gold, silver, glow, shadows outside the card, cropped edges, or multiple cards.
```

### チョキ：ノーマル格章

```text
Edit the attached approved NORMAL SCISSORS card image; do not create a new card from scratch. Preserve every existing part of the source image exactly: the portrait 2:3 crop, the "SCISSORS" title and its typography, all outer and inner borders, corner ornaments, parchment background, stone scissors-hand, floating stone chips, color palette, line weight, texture, lighting, and spacing. Do not redraw, move, resize, recolor, restyle, add, or remove anything else.

Make exactly one change: add one very small, flat slate-gray diamond-shaped rank emblem in the open parchment area below the stone scissors hand. Center it horizontally, position it clearly above the bottom inner navy border with a visible gap of at least two emblem heights, and do not let it touch or overlap any frame line. The emblem must be a compact vertical rhombus: sharply pointed at the top and bottom, with a height about 1.4 times its width. It must not be a square and must not be a horizontal lozenge. Make it only about 3 percent of the total card height, with a thin dark-navy outline and a subtle matte stone texture. It must read as a quiet, independent single rank badge, not as a border decoration, text, a jewel, a button, a playing-card suit, or a glowing magical symbol. Leave sufficient blank space to its left and right for future higher-grade cards to display additional matching vertical diamonds in a horizontal row. Match the existing card's printed illustration style.

No text or letters other than the existing exact title "SCISSORS". Do not add "NORMAL", "BRONZE", numbers, grade names, subtitles, extra symbols, extra diamonds, gold, silver, glow, shadows outside the card, cropped edges, or multiple cards.
```

### パー：ノーマル格章

```text
Edit the attached approved NORMAL PAPER card image; do not create a new card from scratch. Preserve every existing part of the source image exactly: the portrait 2:3 crop, the "PAPER" title and its typography, all outer and inner borders, corner ornaments, parchment background, stone open-palm, floating stone chips, color palette, line weight, texture, lighting, and spacing. Do not redraw, move, resize, recolor, restyle, add, or remove anything else.

Make exactly one change: add one very small, flat slate-gray diamond-shaped rank emblem in the open parchment area below the stone open palm. Center it horizontally, position it clearly above the bottom inner navy border with a visible gap of at least two emblem heights, and do not let it touch or overlap any frame line. The emblem must be a compact vertical rhombus: sharply pointed at the top and bottom, with a height about 1.4 times its width. It must not be a square and must not be a horizontal lozenge. Make it only about 3 percent of the total card height, with a thin dark-navy outline and a subtle matte stone texture. It must read as a quiet, independent single rank badge, not as a border decoration, text, a jewel, a button, a playing-card suit, or a glowing magical symbol. Leave sufficient blank space to its left and right for future higher-grade cards to display additional matching vertical diamonds in a horizontal row. Match the existing card's printed illustration style.

No text or letters other than the existing exact title "PAPER". Do not add "NORMAL", "BRONZE", numbers, grade names, subtitles, extra symbols, extra diamonds, gold, silver, glow, shadows outside the card, cropped edges, or multiple cards.
```

## ブロンズ（ノーマルカードからの派生）

ノーマルの採用画像をそれぞれ参照画像として添付し、中央の石像・タイトル・構図を変えずにブロンズ版へ編集する。グレード名は文字にせず、温かみのある青銅の枠と控えめな緑青で識別する。

### グー：ブロンズ

**画像ファイル候補**: `rock_bronze.png`

```text
Edit the attached approved NORMAL ROCK card image; do not create a new card from scratch. Preserve the source image's exact portrait 2:3 crop, title "ROCK" and its placement, central stone-fist illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. Do not change the hand gesture, title, illustration size, or card composition.

Make only these two grade changes. First, turn the existing border details into a restrained aged-bronze treatment: preserve all existing border-line positions and ornament shapes, but replace the red accent lines and small gold-toned ornaments with warm copper-brown bronze, subtle engraved metal texture, dark navy shadow lines, and only tiny traces of dark teal-green patina in recessed details. Do not make the border thick, chunky, jewel-encrusted, or more ornate than the normal card. Second, remove the single slate-gray vertical rank diamond below the fist and replace it with exactly two identical small vertical bronze diamonds in a horizontal row. Each diamond must be compact and vertically oriented, with a height about 1.4 times its width, a thin dark-navy outline, matte copper-brown fill, and a very small gap between the two diamonds. Keep the pair centered below the fist, clearly above the bottom inner border, with no overlap with frame lines.

No new text or letters. Do not add "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly two, gems, bright gold, silver, platinum, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### チョキ：ブロンズ

**画像ファイル候補**: `scissors_bronze.png`

```text
Use two attached reference images. The NORMAL SCISSORS card is the structural source: preserve its exact portrait 2:3 crop, title "SCISSORS" and its placement, central stone scissors-hand illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. The approved BRONZE ROCK card is the mandatory style reference: match its bronze border treatment and its two-diamond rank badge exactly. Do not create a new card from scratch, and do not change the scissors hand gesture, title, illustration size, or card composition.

Make only these two grade changes to the NORMAL SCISSORS source. First, match the BRONZE ROCK reference's border exactly: preserve all existing border-line positions and ornament shapes, but replace the red accent lines and small gold-toned ornaments with the same warm copper-brown bronze, engraved metal texture, dark navy shadow lines, and restrained dark teal-green patina. Do not make the border thick, chunky, jewel-encrusted, or more ornate than the BRONZE ROCK reference. Second, remove the single slate-gray vertical rank diamond below the scissors hand and replace it with exactly two identical small vertical bronze diamonds in a horizontal row, matching the BRONZE ROCK reference in shape, size, color, spacing, and position. Keep the pair centered below the hand and clearly above the bottom inner border.

No new text or letters. Do not add "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly two, gems, bright gold, silver, platinum, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### パー：ブロンズ

**画像ファイル候補**: `paper_bronze.png`

```text
Use two attached reference images. The NORMAL PAPER card is the structural source: preserve its exact portrait 2:3 crop, title "PAPER" and its placement, central stone open-palm illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. The approved BRONZE ROCK card is the mandatory style reference: match its bronze border treatment and its two-diamond rank badge exactly. Do not create a new card from scratch, and do not change the open-palm gesture, title, illustration size, or card composition.

Make only these two grade changes to the NORMAL PAPER source. First, match the BRONZE ROCK reference's border exactly: preserve all existing border-line positions and ornament shapes, but replace the red accent lines and small gold-toned ornaments with the same warm copper-brown bronze, engraved metal texture, dark navy shadow lines, and restrained dark teal-green patina. Do not make the border thick, chunky, jewel-encrusted, or more ornate than the BRONZE ROCK reference. Second, remove the single slate-gray vertical rank diamond below the open palm and replace it with exactly two identical small vertical bronze diamonds in a horizontal row, matching the BRONZE ROCK reference in shape, size, color, spacing, and position. Keep the pair centered below the hand and clearly above the bottom inner border.

No new text or letters. Do not add "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly two, gems, bright gold, silver, platinum, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

## シルバー（ブロンズカードからの派生）

### グー：シルバー

**画像ファイル候補**: `rock_silver.png`

```text
Edit the attached approved BRONZE ROCK card image; do not create a new card from scratch. Preserve the source image's exact portrait 2:3 crop, title "ROCK" and its placement, central stone-fist illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. Do not change the hand gesture, title, illustration size, or card composition.

Make only these two grade changes. First, transform the bronze border treatment into refined aged silver: preserve all existing border-line positions and ornament shapes, but replace every copper-brown bronze surface with cool silver-gray metal, fine engraved linework, soft blue-gray shadows, and very subtle pale icy-blue highlights only along the metal edges. The silver frame should appear clearly more valuable than bronze while remaining restrained and practical. Do not add gems, bright white glow, or excessive decoration. Second, remove the two bronze vertical rank diamonds below the fist and replace them with exactly three identical small vertical silver diamonds in a horizontal row. Each diamond must match the bronze card's compact vertical shape and size, with a thin dark-navy outline, matte silver-gray fill, subtle blue-gray edge shading, and even small gaps between the three diamonds. Keep the row centered below the fist and clearly above the bottom inner border.

No new text or letters. Do not add "SILVER", "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly three, gold, platinum, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### チョキ：シルバー

**画像ファイル候補**: `scissors_silver.png`

```text
Use two attached reference images. The BRONZE SCISSORS card is the structural source: preserve its exact portrait 2:3 crop, title "SCISSORS" and its placement, central stone scissors-hand illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. The approved SILVER ROCK card is the mandatory style reference: match its silver border treatment and its three-diamond rank badge exactly. Do not create a new card from scratch, and do not change the scissors hand gesture, title, illustration size, or card composition.

Make only these two grade changes to the BRONZE SCISSORS source. First, match the SILVER ROCK reference's border exactly: preserve all existing border-line positions and ornament shapes, but replace every copper-brown bronze surface with the same cool silver-gray metal, fine engraved linework, soft blue-gray shadows, and subtle pale icy-blue metal-edge highlights. Do not add gems, bright white glow, or more ornate decoration than the SILVER ROCK reference. Second, remove the two bronze vertical rank diamonds below the scissors hand and replace them with exactly three identical small vertical silver diamonds in a horizontal row, matching the SILVER ROCK reference in shape, size, color, spacing, and position. Keep the row centered below the hand and clearly above the bottom inner border.

No new text or letters. Do not add "SILVER", "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly three, gold, platinum, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### パー：シルバー

**画像ファイル候補**: `paper_silver.png`

```text
Use two attached reference images. The BRONZE PAPER card is the structural source: preserve its exact portrait 2:3 crop, title "PAPER" and its placement, central stone open-palm illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. The approved SILVER ROCK card is the mandatory style reference: match its silver border treatment and its three-diamond rank badge exactly. Do not create a new card from scratch, and do not change the open-palm gesture, title, illustration size, or card composition.

Make only these two grade changes to the BRONZE PAPER source. First, match the SILVER ROCK reference's border exactly: preserve all existing border-line positions and ornament shapes, but replace every copper-brown bronze surface with the same cool silver-gray metal, fine engraved linework, soft blue-gray shadows, and subtle pale icy-blue metal-edge highlights. Do not add gems, bright white glow, or more ornate decoration than the SILVER ROCK reference. Second, remove the two bronze vertical rank diamonds below the open palm and replace them with exactly three identical small vertical silver diamonds in a horizontal row, matching the SILVER ROCK reference in shape, size, color, spacing, and position. Keep the row centered below the hand and clearly above the bottom inner border.

No new text or letters. Do not add "SILVER", "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly three, gold, platinum, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

## ゴールド（シルバーカードからの派生）

### グー：ゴールド

**画像ファイル候補**: `rock_gold.png`

```text
Edit the attached approved SILVER ROCK card image; do not create a new card from scratch. Preserve the source image's exact portrait 2:3 crop, title "ROCK" and its placement, central stone-fist illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. Do not change the hand gesture, title, illustration size, or card composition.

Make only these two grade changes. First, transform the silver border treatment into refined aged gold: preserve all existing border-line positions and ornament shapes, but replace every silver-gray surface with warm antique gold, fine engraved linework, rich umber shadows, and restrained pale gold highlights only along the metal edges. The gold frame should feel clearly more prestigious than silver, like a polished royal artifact, but must remain elegant rather than gaudy. Do not add jewels, bright yellow glare, flames, or excessive decoration. Second, remove the three silver vertical rank diamonds below the fist and replace them with exactly four identical small vertical gold diamonds in a horizontal row. Each diamond must match the silver card's compact vertical shape and size, with a thin dark-navy outline, matte antique-gold fill, subtle warm edge shading, and even small gaps between all four diamonds. Keep the row centered below the fist and clearly above the bottom inner border.

No new text or letters. Do not add "GOLD", "SILVER", "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly four, platinum, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### チョキ：ゴールド

**画像ファイル候補**: `scissors_gold.png`

```text
Use two attached reference images. The SILVER SCISSORS card is the structural source: preserve its exact portrait 2:3 crop, title "SCISSORS" and its placement, central stone scissors-hand illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. The approved GOLD ROCK card is the mandatory style reference: match its aged-gold border treatment and its four-diamond rank badge exactly. Do not create a new card from scratch, and do not change the scissors hand gesture, title, illustration size, or card composition.

Make only these two grade changes to the SILVER SCISSORS source. First, match the GOLD ROCK reference's border exactly: preserve all existing border-line positions and ornament shapes, but replace every silver-gray surface with the same warm antique gold, fine engraved linework, rich umber shadows, and restrained pale-gold metal-edge highlights. Do not add jewels, bright yellow glare, flames, crowns, or more ornate decoration than the GOLD ROCK reference. Second, remove the three silver vertical rank diamonds below the scissors hand and replace them with exactly four identical small vertical gold diamonds in a horizontal row, matching the GOLD ROCK reference in shape, size, color, spacing, and position. Keep the row centered below the hand and clearly above the bottom inner border.

No new text or letters. Do not add "GOLD", "SILVER", "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly four, platinum, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### パー：ゴールド

**画像ファイル候補**: `paper_gold.png`

```text
Use two attached reference images. The SILVER PAPER card is the structural source: preserve its exact portrait 2:3 crop, title "PAPER" and its placement, central stone open-palm illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. The approved GOLD ROCK card is the mandatory style reference: match its aged-gold border treatment and its four-diamond rank badge exactly. Do not create a new card from scratch, and do not change the open-palm gesture, title, illustration size, or card composition.

Make only these two grade changes to the SILVER PAPER source. First, match the GOLD ROCK reference's border exactly: preserve all existing border-line positions and ornament shapes, but replace every silver-gray surface with the same warm antique gold, fine engraved linework, rich umber shadows, and restrained pale-gold metal-edge highlights. Do not add jewels, bright yellow glare, flames, crowns, or more ornate decoration than the GOLD ROCK reference. Second, remove the three silver vertical rank diamonds below the open palm and replace them with exactly four identical small vertical gold diamonds in a horizontal row, matching the GOLD ROCK reference in shape, size, color, spacing, and position. Keep the row centered below the hand and clearly above the bottom inner border.

No new text or letters. Do not add "GOLD", "SILVER", "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly four, platinum, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

## プラチナ（ゴールドカードからの派生）

### 格章数の修正（6個版から5個版へ）

現在生成済みのプラチナカードを1枚ずつ添付し、対応する下記プロンプトを使う。新規生成ではなく、添付画像の格章部分だけを修正するための指示である。

#### グー：5個へ修正

```text
Edit the attached PLATINUM ROCK card image. This is a precise correction, not a redesign. Preserve absolutely everything in the image unchanged: the exact portrait 2:3 crop, title "ROCK", stone fist, stone chips, parchment background, platinum frame, all ornament positions, line weight, colors, lighting, texture, card layout, and spacing.

Make exactly one change: the horizontal rank badge below the fist currently has six vertical platinum diamonds. Replace that six-diamond row with exactly five identical small vertical platinum diamonds. The five diamonds must keep the same individual shape, size, platinum-white fill, icy-blue edge tint, thin dark-navy outline, and visual style as the attached six diamonds. Center the five-diamond row in the same badge area, use even small gaps, and keep it clearly above the bottom inner border. Do not enlarge the diamonds to fill the former row width.

No other edits. Do not add or remove any text, ornaments, highlights, effects, symbols, hands, cards, borders, or background details. Do not leave six diamonds and do not create four, seven, or any other number: exactly five diamonds only.
```

#### チョキ：5個へ修正

```text
Edit the attached PLATINUM SCISSORS card image. This is a precise correction, not a redesign. Preserve absolutely everything in the image unchanged: the exact portrait 2:3 crop, title "SCISSORS", stone scissors-hand, stone chips, parchment background, platinum frame, all ornament positions, line weight, colors, lighting, texture, card layout, and spacing.

Make exactly one change: the horizontal rank badge below the scissors hand currently has six vertical platinum diamonds. Replace that six-diamond row with exactly five identical small vertical platinum diamonds. The five diamonds must keep the same individual shape, size, platinum-white fill, icy-blue edge tint, thin dark-navy outline, and visual style as the attached six diamonds. Center the five-diamond row in the same badge area, use even small gaps, and keep it clearly above the bottom inner border. Do not enlarge the diamonds to fill the former row width.

No other edits. Do not add or remove any text, ornaments, highlights, effects, symbols, hands, cards, borders, or background details. Do not leave six diamonds and do not create four, seven, or any other number: exactly five diamonds only.
```

#### パー：5個へ修正

```text
Edit the attached PLATINUM PAPER card image. This is a precise correction, not a redesign. Preserve absolutely everything in the image unchanged: the exact portrait 2:3 crop, title "PAPER", stone open palm, stone chips, parchment background, platinum frame, all ornament positions, line weight, colors, lighting, texture, card layout, and spacing.

Make exactly one change: the horizontal rank badge below the open palm currently has six vertical platinum diamonds. Replace that six-diamond row with exactly five identical small vertical platinum diamonds. The five diamonds must keep the same individual shape, size, platinum-white fill, icy-blue edge tint, thin dark-navy outline, and visual style as the attached six diamonds. Center the five-diamond row in the same badge area, use even small gaps, and keep it clearly above the bottom inner border. Do not enlarge the diamonds to fill the former row width.

No other edits. Do not add or remove any text, ornaments, highlights, effects, symbols, hands, cards, borders, or background details. Do not leave six diamonds and do not create four, seven, or any other number: exactly five diamonds only.
```

### グー：プラチナ

**画像ファイル候補**: `rock_platinum.png`

```text
Edit the attached approved GOLD ROCK card image; do not create a new card from scratch. Preserve the source image's exact portrait 2:3 crop, title "ROCK" and its placement, central stone-fist illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. Do not change the hand gesture, title, illustration size, or card composition.

Make only these two grade changes. First, transform the aged-gold border treatment into a premium platinum frame: preserve all existing border-line positions and ornament shapes, but replace every antique-gold surface with pale platinum-white metal, fine engraved linework, cool blue-gray shadows, and restrained icy-cyan enamel inlays recessed into a few existing ornamental grooves. The platinum frame should feel rarer and more refined than gold—clean, luminous in material quality, and aristocratic—but must not emit light or become magical. Do not add gems, white glare, rainbow iridescence, flames, or excessive ornamentation. Second, remove the four gold vertical rank diamonds below the fist and replace them with exactly five identical small vertical platinum diamonds in a horizontal row. Each diamond must match the gold card's compact vertical shape and size, with a thin dark-navy outline, pale platinum-white fill, a subtle icy-blue edge tint, and even small gaps between all five diamonds. Keep the row centered below the fist and clearly above the bottom inner border.

No new text or letters. Do not add "PLATINUM", "GOLD", "SILVER", "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly five, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### チョキ：プラチナ

**画像ファイル候補**: `scissors_platinum.png`

```text
Use two attached reference images. The GOLD SCISSORS card is the structural source: preserve its exact portrait 2:3 crop, title "SCISSORS" and its placement, central stone scissors-hand illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. The approved PLATINUM ROCK card is the mandatory style reference: match its platinum border treatment and its five-diamond rank badge exactly. Do not create a new card from scratch, and do not change the scissors hand gesture, title, illustration size, or card composition.

Make only these two grade changes to the GOLD SCISSORS source. First, match the PLATINUM ROCK reference's border exactly: preserve all existing border-line positions and ornament shapes, but replace every antique-gold surface with the same pale platinum-white metal, fine engraved linework, cool blue-gray shadows, and restrained icy-cyan enamel inlays in a few existing ornamental grooves. Do not add gems, white glare, rainbow iridescence, flames, magical effects, or more ornate decoration than the PLATINUM ROCK reference. Second, remove the four gold vertical rank diamonds below the scissors hand and replace them with exactly five identical small vertical platinum diamonds in a horizontal row, matching the PLATINUM ROCK reference in shape, size, color, spacing, and position. Keep the row centered below the hand and clearly above the bottom inner border.

No new text or letters. Do not add "PLATINUM", "GOLD", "SILVER", "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly five, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

### パー：プラチナ

**画像ファイル候補**: `paper_platinum.png`

```text
Use two attached reference images. The GOLD PAPER card is the structural source: preserve its exact portrait 2:3 crop, title "PAPER" and its placement, central stone open-palm illustration, hand silhouette, stone chips, parchment background, card layout, line weight, and all spacing. The approved PLATINUM ROCK card is the mandatory style reference: match its platinum border treatment and its five-diamond rank badge exactly. Do not create a new card from scratch, and do not change the open-palm gesture, title, illustration size, or card composition.

Make only these two grade changes to the GOLD PAPER source. First, match the PLATINUM ROCK reference's border exactly: preserve all existing border-line positions and ornament shapes, but replace every antique-gold surface with the same pale platinum-white metal, fine engraved linework, cool blue-gray shadows, and restrained icy-cyan enamel inlays in a few existing ornamental grooves. Do not add gems, white glare, rainbow iridescence, flames, magical effects, or more ornate decoration than the PLATINUM ROCK reference. Second, remove the four gold vertical rank diamonds below the open palm and replace them with exactly five identical small vertical platinum diamonds in a horizontal row, matching the PLATINUM ROCK reference in shape, size, color, spacing, and position. Keep the row centered below the hand and clearly above the bottom inner border.

No new text or letters. Do not add "PLATINUM", "GOLD", "SILVER", "BRONZE", "NORMAL", numbers, grade names, extra rank diamonds beyond exactly five, strong glow, magical effects, crowns, weapons, extra hands, altered anatomy, photorealistic mockups, perspective, cast shadows outside the card, cropped edges, or multiple cards.
```

## 生成・選定手順

1. 各プロンプトを個別に貼り付け、1回につきカードを1枚だけ生成する。
2. 案1はグー・チョキ・パーの3枚、案2も同じく3枚を横に並べ、各案の統一感を比較する。
3. 枠の太さ、明るい地色の見やすさ、中央モチーフの大きさ、手の判別しやすさを基準に、1つの意匠系列を選ぶ。
4. 大きく外れたカードだけ再生成し、3枚のデザインを1枚にまとめて生成しない。
5. 採用した各ノーマルカードを保存し、後続のブロンズ〜プラチナ生成では対応するノーマル画像を参照画像に指定する。
