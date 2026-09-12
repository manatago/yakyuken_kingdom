# カード裏面デザイン比較用プロンプト

Nano Bananaで4案を比較するためのプロンプト集。全案とも**カードのグレードや手の種類を示さない共通裏面**である。

## 共通の生成条件

- 出力はカードの裏面デザインだけ。人物、手札、卓上、背景、カードを持つ手は入れない。
- 縦長のトレーディングカード比率（2:3）。カード全体を正面から、余白なく収める。
- 中央線を軸に完全な左右対称。上下どちらから見ても成立する、伝統的なカード裏面の構図。
- 裏面はじゃんけんの手を連想させない、世界観を示す汎用的な意匠にする。数字、文字、ロゴ、カードの種類やグレードを示す印は使わない。
- 枠、中央紋章、背景パターンを明確に分離し、小さく表示されても判別できる太さ・コントラストにする。
- 仕上がりはゲーム用の2Dアセット。アニメ調ファンタジーのセルシェードだが、印刷された実在の札に見える質感を優先する。

## 案A：王国公認の決闘札

**意図**: 王国が公認した正式な決闘用カード。最も格式が高く、物語中で「藍地に王国の決闘紋を刷った札」と自然に描写できる。

**プロンプト**:

```text
Create a single universal fantasy playing-card back design for an officially sanctioned royal duel card. Portrait 2:3 trading-card proportion, full card visible front-on, no scene around it. A deep midnight-blue dyed paper background with subtle fibers and lightly worn printed texture. Strictly symmetrical on both vertical and horizontal axes, readable upside down like a traditional playing-card back.

Use an elegant ivory and muted antique-gold line-art border: a thick outer frame, a fine inner frame, restrained corner filigree, and a large centered royal heraldic emblem. The emblem combines a dignified crown above a simple shield, encircled by symmetrical laurel branches. Add small decorative stars and fleur-de-lis-like ornaments integrated into the linework. The design should feel like a real, mass-issued yet prestigious card used throughout a medieval fantasy kingdom: refined printmaking, heraldic, tactile, durable, elegant, highly legible at small size.

No text, letters, numbers, readable runes, logos, character art, hands, rock-paper-scissors imagery, individual playing-card suits, grade indicators, or different rarities. No glowing magic, no photorealistic mockup, no card stack, no perspective. Flat 2D game asset, clean silhouette, detailed but not overly busy.
```

## 案B：冒険者ギルドの登録札

**意図**: 冒険者ギルドが発行・流通させる実用品。使い込まれた世界の道具としての手触りを強める。

**プロンプト**:

```text
Create a single universal fantasy playing-card back design for an adventurers' guild registration and duel card. Portrait 2:3 trading-card proportion, full card visible front-on, no scene around it. Strict symmetry on vertical and horizontal axes, readable upside down like a traditional playing-card back.

The card is sturdy warm parchment with a deep forest-green ink field and a dark brown leather-like outer edge, subtly scuffed by normal use but still well cared for. Build a bold guild-seal composition: a round central wax-seal-inspired emblem containing a simple compass rose and a small mountain silhouette, surrounded by a rope border, small brass rivet motifs, and restrained decorative knots. The card should feel practical, trusted, and widely used by adventurers in a European medieval fantasy guild hall—handcrafted print texture, embossed seal impression, strong readable shapes, warm material detail.

No text, letters, numbers, readable runes, logos, character art, hands, rock-paper-scissors imagery, individual playing-card suits, grade indicators, or different rarities. No luminous magic, no photorealistic mockup, no card stack, no perspective. Flat 2D game asset, elegant and clear at small size.
```

## 案C：魔導工芸のカード

**意図**: 魔術が生活に根付いた世界の決闘札。対戦演出の暗い背景にも映えるが、派手すぎない神秘性を持たせる。

**プロンプト**:

```text
Create a single universal fantasy playing-card back design made by master arcane artisans. Portrait 2:3 trading-card proportion, full card visible front-on, no scene around it. Strictly symmetrical on vertical and horizontal axes, readable upside down like a traditional playing-card back.

Use matte black-indigo paper with a restrained cool-blue and pale-silver ink design. A double circular arcane diagram sits at the center, enclosed by a refined geometric border with repeating diamond and star motifs. At the core is a symmetrical eight-pointed star surrounding a crescent moon and a small faceted crystal, all rendered as clean ornamental symbols rather than literal objects. Use delicate non-readable decorative glyph-like marks only as texture, never as text. Add very subtle pale cyan magical luminescence within a few etched lines, like dormant enchantment in printed foil, not bright neon. The result should feel like a real enchanted dueling card in an anime-inspired medieval fantasy world: precise, mysterious, premium, and clearly readable at small size.

No text, letters, numbers, readable runes, logos, character art, hands, rock-paper-scissors imagery, individual playing-card suits, grade indicators, or different rarities. No spell effects outside the card, no photorealistic mockup, no card stack, no perspective. Flat 2D game asset, clean and usable in a UI.
```

## 案D：王家のトランプ風

**意図**: 「カードゲームをしている」印象を最優先する、華やかな伝統的トランプ調。ファンタジーの宮廷文化にも合う。

**プロンプト**:

```text
Create a single universal fantasy playing-card back design in a luxurious royal playing-card style. Portrait 2:3 trading-card proportion, full card visible front-on, no scene around it. Strictly symmetrical on vertical and horizontal axes, readable upside down like a traditional ornate card back.

Use a rich near-black navy background, ivory ornamental linework, muted crimson accents, and small antique-gold details. Design a strong layered frame: bold outer border, repeating ornamental curls, diamond-shaped corner ornaments, and an elaborate centered flower-shaped medallion. The medallion contains a symmetrical rosette with a small crown-shaped flourish at its center, woven into a classical heraldic pattern. The composition should resemble a refined classic European deck reimagined for a fantasy royal court: decorative, crisp, playful but dignified, with clean high-contrast shapes that remain recognizable when the card is small.

No text, letters, numbers, readable runes, logos, character art, hands, rock-paper-scissors imagery, individual playing-card suits, grade indicators, or different rarities. No glowing magic, no photorealistic mockup, no card stack, no perspective. Flat 2D game asset with symmetrical print design.
```

## 比較時の確認項目

1. 200×300程度まで縮小しても、中央紋章と外枠が認識できるか。
2. じゃんけんや表面の手を連想させる情報が、裏面に含まれていないか。
3. 文字や意味を持つ疑似文字が混入していないか。
4. 左右・上下の対称性が十分で、カードを回転しても不自然でないか。
5. 実物のカードらしさと、ゲームUIでの読みやすさが両立しているか。
