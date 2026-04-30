# 汎用ランダム敵（バトル立ち絵プロンプト集）

**Tier**: 2
**参照**: `style_guide.md`、`character_sheet.md`

## 実装仕様（EncounterDatabase.gd / RandomBattleChapter.gd 準拠）

- **戦闘形式**: **1本勝負**（HP=1）、デッキサイズ 3枚
- **1敵あたり必要な画像 = 4点**:
  - `encounter`: 遭遇時の会話ポートレート（挨拶・挑発）
  - `battle`: 戦闘中の構えポートレート（デッキ台座前）
  - `farewell_win`: **プレイヤー勝利時＝敵の敗北リアクション**
  - `farewell_lose`: **プレイヤー敗北時＝敵の勝利リアクション**
- **成人向け表現（重要）**: **男女問わず** `farewell_win`（敗北）は**outfit_1相当＝素っ裸＋局部モザイク**で描写
  - 女性敵: 完全に裸、乳首露出、局部モザイク
  - **男性敵も同様**: 完全に裸、局部モザイク
  - タグ例: `completely nude, (mosaic censoring on genitals, censored pubic area), no underwear`
- **相手は全員人間**。モンスター・獣・精霊は登場しない
- **老若男女混合**で約50体を用意

**ネガティブプロンプト**（全敵共通）:
```
lowres, bad anatomy, bad hands, missing fingers, extra digits,
cropped, worst quality, low quality, jpeg artifacts,
signature, watermark, text, blurry, bad proportions, deformed,
multiple characters, monster, animal, creature, beast, slime,
goblin, orc, skeleton, demon, fantasy creature, non-human
```

## 画像パラメータ規約

各ポートレートは `simple background, plain white background` とし、
NovelAI生成後に背景除去スクリプトで立ち絵素材化する前提。

照明は「中性的な昼光」を基本とし、敵の種別（盗賊は夜／商人は酒場暖色 等）に応じて調整。

## `farewell_win`（敗北）生成ルール

**以下、各敵の `farewell_win` 差分タグに加えて、必ず以下の共通タグを付与する**:

```
completely nude, no underwear, bare body,
(mosaic censoring on genitals, censored pubic area),
[女性のみ: bare breasts, nipples visible]
```

本文中の各敵の `farewell_win` 記述（`(defeated kneeling, ...)` 等）は**表情・ポーズのみ**を示しており、衣装は上記の素っ裸＋モザイク共通タグで統一する。

- 男女問わず完全に裸
- 局部は必ずモザイク処理
- 女性は乳首露出OK（モザイクなし）
- 男性は上半身も全裸（胸毛・筋肉等はキャラ個性で描写）

---

## 既存登録済み敵（7体・既存実装あり）

以下は `EncounterDatabase.gd` に既に登録済み。画像ファイルも存在。
プロンプトは**再生成用の参考**として掲載。

### 1. thug_a（チンピラA）

**属性**: 若年男性 / ならず者
**設定**: ギルド通りで新人に絡む系。グー偏重脳筋。

共通ベース:
```
1man, solo, young adult, early twenties, western features,
unkempt short brown hair, narrow mean brown eyes, tanned skin,
muscular bulky build, worn leather vest, dirty tunic, rough pants,
worn boots, rough thug aesthetic,
simple background, plain white background
```

- **encounter**: `(leaning cocky stance arms crossed, sneering grin, mouth open taunting)`
- **battle**: `(battle stance fist clenched, aggressive grin, wide stance)`
- **farewell_win**: `(defeated kneeling, clutching head, cards scattered, shocked)`
- **farewell_lose**: `(triumphant gar-gar laugh, fist raised, cards in hand, mocking)`

### 2. thug_b（ゴロツキ）

**属性**: 若年男性 / ならず者2
**設定**: バランス型、嫌味な通行料屋。

共通ベース:
```
1man, solo, young adult, mid twenties, western features,
shaved sides, medium brown hair, stubble, mean green eyes,
weathered tanned skin, wiry muscular build, leather jacket,
grey shirt, worn pants, bandana around neck, chains,
punk thug aesthetic, simple background, plain white background
```

- **encounter**: `(blocking path hands in pockets, smug lopsided smirk, chin raised)`
- **battle**: `(cracking knuckles, nasty grin, ready stance)`
- **farewell_win**: `(slumped kneeling disbelief, hand through hair, cards lost)`
- **farewell_lose**: `(satisfied dismissive smirk, cards in hand, turning to leave)`

### 3. drunk（酔っ払い冒険者）

**属性**: 中年男性 / 酔っ払い
**設定**: チョキ偏重、ふらふら酔拳風。

共通ベース:
```
1man, solo, mature male, late thirties to forties, western features,
messy disheveled dark hair, flushed drunken red face, 
hazy unfocused brown eyes, weathered tanned skin, beer belly build,
(stained shirt open, worn adventurer leather, bottle or tankard in hand),
drunk veteran aesthetic,
simple background, plain white background
```

- **encounter**: `(swaying drunkenly, one hand on wall for support, slurred grin, bottle raised)`
- **battle**: `(unsteady fighting stance, half-lidded unfocused eyes, drunken confidence)`
- **farewell_win**: `(sobered up shocked, bottle fallen, pale and shaking)`
- **farewell_lose**: `(drunken celebration, tankard raised high, happy laugh)`

### 4. merchant（恰幅のいい商人）

**属性**: 中年男性 / 商人
**設定**: パー偏重、上質な衣服。

共通ベース:
```
1man, solo, mature male, late forties, western features,
neat brown hair with grey temples, small mustache, shrewd brown eyes,
pale well-fed skin, plump corpulent build, (fine merchant robe,
gold embroidery trim, silk sash, expensive rings, leather pouch),
prosperous merchant aesthetic,
simple background, plain white background
```

- **encounter**: `(bowing politely with hands clasped, fake friendly smile, commercial greeting)`
- **battle**: `(slight nervous smile but confident, hand extended over deck)`
- **farewell_win**: `(robe undone exposing undershirt, flustered embarrassed sweating,
  "please return my clothes" begging gesture, hands raised in plea)`
- **farewell_lose**: `(triumphant self-satisfied laugh, one hand on belly shaking,
  smug businessman victory, collecting opponent's cards)`

### 5. merchant2（怪しい商人）

**属性**: 中年男性 / 詐欺師風商人
**設定**: 同じくパー偏重、裏取引系。

共通ベース:
```
1man, solo, mature male, mid forties, western features,
slicked back black hair, narrow sly black eyes, pale sickly skin,
thin wiry build, (dark merchant robe with hood, silver embroidery,
suspicious leather belt with pouches), shady merchant aesthetic,
simple background, plain white background
```

- **encounter**: `(creepy hand-rubbing gesture, sly grin, hood half-raised)`
- **battle**: `(nervous twitchy smile, cards hidden up sleeves ready)`
- **farewell_win**: `(robe pulled open revealing undergarments, desperate pleading,
  fake tears wailing, begging for clothes back)`
- **farewell_lose**: `(sneaky pleased chuckle, hood pulled low, collecting coins)`

### 6. sailor（荒くれ船乗り）

**属性**: 中年男性 / 船乗り
**設定**: グー偏重、海の男。

共通ベース:
```
1man, solo, mature male, late thirties, western features,
sun-bleached blonde hair, weathered scar on cheek, sharp blue eyes,
deeply tanned leathery skin, bulky muscular sailor build,
(striped sailor shirt open, rough canvas pants, anchor tattoo,
pirate bandana, rope belt), ocean weathered aesthetic,
simple background, plain white background
```

- **encounter**: `(imposing arms on hips, booming welcome, chest out)`
- **battle**: `(fists up sailor brawler stance, "gahaha" grin, wide ready stance)`
- **farewell_win**: `(dumbfounded scratching head, shirt torn open, salty curses)`
- **farewell_lose**: `(raucous sea-shanty laughter, tankard raised, arm around air)`

### 7. bandit（野盗）

**属性**: 若年〜中年男性 / 街道盗賊
**設定**: バランス型、城壁外の略奪者。

共通ベース:
```
1man, solo, adult male, twenties to thirties, western features,
long messy black hair tied back, scar across eye, amber eyes,
tanned rugged skin, muscular athletic build, (dark leather armor,
hood pulled up shadowing face, bandana mask around neck,
multiple daggers on belt, crossbow strapped to back),
highway bandit aesthetic,
simple background, plain white background
```

- **encounter**: `(dramatic appearing from shadow, dagger drawn threateningly, "kekeke" laugh)`
- **battle**: `(combat crouch ready to strike, dagger low, predatory grin)`
- **farewell_win**: `(injured clutching arm, hood fallen off, angry teeth-grit)`
- **farewell_lose**: `(hyena cackle of victory, counting stolen loot, sadistic grin)`

---

## 新規追加敵（43体・要新規実装）

### カテゴリー A：若年男性（5体）

### 8. novice_adventurer_male（新米冒険者・男）

**属性**: 若年男性（10代後半〜20代前半） / 冒険者
**設定**: ギルド登録したての新米、グー偏重。

共通ベース:
```
1boy, solo, late teens, young adult, western features,
short sandy blonde hair, bright green eyes, youthful face,
fair skin, slim average build, (simple leather vest over linen shirt,
rough trousers, short sword at belt, adventurer guild badge,
worn cloak), eager rookie adventurer aesthetic,
simple background, plain white background
```

- **encounter**: `(excited nervous wave, friendly introduction, hopeful smile)`
- **battle**: `(amateur fighting stance awkward, tense focused face)`
- **farewell_win**: `(shocked collapsed on knees, hand over heart, defeated breath)`
- **farewell_lose**: `(first victory celebration, fist pump, beaming grin)`

### 9. apprentice_mage_male（魔術師見習い・男）

**属性**: 若年男性 / 魔術師
**設定**: チョキ偏重、知的タイプ。

```
1boy, solo, late teens, young adult, western features,
neat black medium hair, glasses, intelligent sharp brown eyes,
pale scholar skin, slim build, (blue mage apprentice robe with silver trim,
wooden staff with small crystal, spell book at belt, pouch of reagents),
studious magic student aesthetic,
simple background, plain white background
```

- **encounter**: `(adjusting glasses with one hand, raising staff in polite challenge)`
- **battle**: `(staff held ready, focused reading magical currents, serious)`
- **farewell_win**: `(glasses askew, staff fallen, stunned at loss, tears in corner)`
- **farewell_lose**: `(proud scholarly smirk, staff raised in scholarly triumph)`

### 10. pickpocket_boy（スリ少年）

**属性**: 少年（10代前半） / スリ
**設定**: パー偏重、街のごろつき小僧。

```
1boy, solo, early teens, young child, western features,
messy dirty blonde hair under ragged cap, sly green eyes,
dirty fair skin, thin scrawny build, (ragged dirty tunic, 
cloth pants patched multiple times, no shoes, small pouch at waist,
dirty bandana), street urchin aesthetic,
simple background, plain white background
```

- **encounter**: `(sneaking close hand reaching out, mischievous grin, wink)`
- **battle**: `(quick nimble stance, tongue out playfully, ready to bolt)`
- **farewell_win**: `(caught red-handed shock, pockets turned out, tearful)`
- **farewell_lose**: `(jumping in victory, holding stolen coins high, laughing)`

### 11. stable_boy（厩舎番の若者）

**属性**: 若年男性 / 厩舎働き
**設定**: バランス型、素朴な若者。

```
1boy, solo, young adult, early twenties, western features,
shaggy brown hair, honest hazel eyes, tanned sun skin,
lean hardworking build, (simple stable-hand tunic with hay stains,
rough work pants, leather boots, pitchfork or shovel in hand),
humble stable worker aesthetic,
simple background, plain white background
```

- **encounter**: `(friendly open greeting, tipping cap, honest smile)`
- **battle**: `(honest ready stance, tool set aside, focused)`
- **farewell_win**: `(disappointed scratching head, cap in hands, humble defeat)`
- **farewell_lose**: `(genuine surprised cheer, awkward happy dance)`

### 12. young_guard（見習い衛兵）

**属性**: 若年男性 / 衛兵見習い
**設定**: グー偏重、規律重視。

```
1boy, solo, young adult, early twenties, western features,
short brown military cut hair, serious blue eyes, fair skin,
trim athletic build, (guard recruit uniform, blue tunic with silver trim,
leather chest plate, short sword, apprentice helm under arm),
rookie guard aesthetic, simple background, plain white background
```

- **encounter**: `(formal salute, rigid duty stance, polite official greeting)`
- **battle**: `(textbook guard combat stance, one hand on sword hilt)`
- **farewell_win**: `(disciplined bow of defeat, professional composure cracking, helmet drooping)`
- **farewell_lose**: `(restrained professional victory nod, small satisfied smile)`

---

### カテゴリー B：若年女性（5体）

### 13. novice_adventurer_female（新米冒険者・女）

**属性**: 若年女性（20代前半） / 冒険者
**設定**: チョキ偏重、元気系。

```
1girl, solo, young adult, early twenties, western features,
bright auburn long hair in ponytail, cheerful brown eyes,
fair slightly tanned skin, slim athletic figure, (leather armor 
over white blouse, short skirt, thigh-high boots, short sword,
adventurer's backpack), cheerful rookie aesthetic,
simple background, plain white background
```

- **encounter**: `(enthusiastic hand-wave greeting, bright happy smile)`
- **battle**: `(plucky determined stance, sword drawn amateur grip)`
- **farewell_win（outfit_1相当）**: `(topless with arms over breasts tightly, 
  no underwear, (mosaic censoring on genitals, censored pubic area), nipples obscured, tearful shame face,
  clothes scattered around feet), tasteful nudity`
- **farewell_lose**: `(victorious sparkle-eyed cheer, fist pump, bouncing joy)`

### 14. priestess_young（若い司祭）

**属性**: 若年女性 / 神官
**設定**: パー偏重、祈祷中心。

```
1girl, solo, young adult, early twenties, western features,
soft blonde wavy hair, gentle sky blue eyes, pale porcelain skin,
slim graceful figure, (white priestess robe with gold trim,
silver holy symbol necklace, white veil, wooden prayer beads,
holy staff with cross), young cleric aesthetic,
simple background, plain white background
```

- **encounter**: `(gentle prayer gesture, peaceful welcoming smile)`
- **battle**: `(holy staff raised protectively, soft focused expression)`
- **farewell_win（outfit_1相当）**: `(topless with one arm covering modestly,
  no underwear, (mosaic censoring on genitals, censored pubic area), holy symbol still on, flushed deep shame,
  robe pooled at feet), tasteful religious nudity`
- **farewell_lose**: `(gentle blessing gesture, benevolent smile of grace)`

### 15. female_swordswoman（若い女剣士）

**属性**: 若年女性 / 戦士
**設定**: グー偏重、凛々しい。

```
1girl, solo, young adult, mid twenties, western features,
short silver hair cut like a knight, sharp cobalt blue eyes,
fair skin with faint battle scars, athletic toned figure,
(leather armor over chain mail shirt, steel pauldrons, 
short skirt with metal plates, sword at hip, fingerless gloves),
female warrior aesthetic, simple background, plain white background
```

- **encounter**: `(chivalrous bow with hand on chest, respectful nod)`
- **battle**: `(sword drawn in proper knight stance, disciplined gaze)`
- **farewell_win（outfit_1相当）**: `(topless with one arm crossed over breasts,
  dark underwear only, warrior shame, pieces of armor scattered,
  gritted teeth biting back tears), tasteful warrior nudity`
- **farewell_lose**: `(victorious sword raised, warrior's cry, proud stance)`

### 16. barmaid（酒場の看板娘）

**属性**: 若年女性 / 店員
**設定**: バランス型、愛想系。

```
1girl, solo, young adult, early twenties, western features,
curly red hair in low ponytail, vibrant green eyes, fair freckled skin,
voluptuous curvy figure, (low-cut tavern blouse revealing cleavage,
corset cincher, short pleated skirt, apron, thigh-high stockings,
tankard or serving tray), bubbly barmaid aesthetic,
simple background, plain white background
```

- **encounter**: `(friendly tavern-girl wink, hand on hip, tray balanced)`
- **battle**: `(playful challenge stance, cards fanned out teasingly)`
- **farewell_win（outfit_1相当）**: `(topless with breasts partially exposed,
  no underwear, (mosaic censoring on genitals, censored pubic area), apron hanging loose, embarrassed but pouty,
  tongue out in playful defeat), tasteful tavern nudity`
- **farewell_lose**: `(gleeful tavern cheer, tankard raised, big smile)`

### 17. female_scholar（若い女学者）

**属性**: 若年女性 / 学者
**設定**: チョキ偏重、知識豊富。

```
1girl, solo, young adult, mid twenties, western features,
chestnut brown long hair in messy bun with pencils, glasses,
intelligent hazel eyes, pale scholar skin, slim delicate figure,
(professor's robe with academy emblem, white blouse, long skirt,
books under arm, quill in pocket, spectacles), academic scholar aesthetic,
simple background, plain white background
```

- **encounter**: `(adjusting glasses politely, academic nod, book half-open)`
- **battle**: `(analytical focused gaze over glasses, cards held calculating)`
- **farewell_win（outfit_1相当）**: `(topless hair covering breasts, glasses askew,
  no underwear, (mosaic censoring on genitals, censored pubic area), tearful scholarly humiliation, books fallen,
  flushed shame), tasteful academic nudity`
- **farewell_lose**: `(small triumphant smile adjusting glasses, dignified victory nod)`

---

### カテゴリー C：中年男性（5体）

### 18. veteran_adventurer_male（ベテラン冒険者・男）

**属性**: 中年男性 / 冒険者
**設定**: バランス型、経験豊富。

```
1man, solo, mature male, late thirties, western features,
short graying brown hair, full beard with grey, weathered blue eyes,
tanned battle-scarred skin, muscular athletic veteran build,
(worn leather armor over chainmail, long sword, traveling cloak,
multiple pouches, scars visible), veteran mercenary aesthetic,
simple background, plain white background
```

- **encounter**: `(nodding respectfully at opponent, gruff friendly greeting)`
- **battle**: `(experienced combat stance, sword drawn calmly, focused)`
- **farewell_win**: `(weary frustrated sigh, head down, hand through beard)`
- **farewell_lose**: `(gruff approving nod, short satisfied grunt, cards collected)`

### 19. innkeeper_male（宿屋の主人）

**属性**: 中年男性 / 宿屋主人
**設定**: パー偏重、大らか。

```
1man, solo, mature male, late forties, western features,
balding salt-and-pepper hair, thick mustache, warm brown eyes,
ruddy tanned skin, portly belly build, (apron over simple shirt,
rolled-up sleeves, cook's knife at belt, rag over shoulder),
friendly innkeeper aesthetic,
simple background, plain white background
```

- **encounter**: `(booming welcoming laugh, arms wide, hospitable greeting)`
- **battle**: `(bemused fighting stance with rolled sleeves, easy grin)`
- **farewell_win**: `(good-natured shrug of defeat, wiping sweat, chuckle)`
- **farewell_lose**: `(hearty innkeeper belly laugh, slapping knee, jovial)`

### 20. blacksmith_battler（戦う鍛冶屋）

**属性**: 中年男性 / 鍛冶屋
**設定**: グー偏重、筋骨隆々。

```
1man, solo, mature male, early forties, western features,
short black hair, thick stubble, fierce amber eyes, soot-streaked
tanned skin, heavily muscular broad shoulders, (leather apron over 
bare chest, heavy work gloves, iron hammer in hand, rough pants,
metal wristbands), brawny blacksmith aesthetic,
simple background, plain white background
```

- **encounter**: `(intimidating hammer shoulder rest, gruff challenge)`
- **battle**: `(massive fist raised, hammer in other hand, imposing stance)`
- **farewell_win**: `(bewildered massive shoulders slumped, hammer lowered, disbelief)`
- **farewell_lose**: `(roaring blacksmith victory, hammer raised high, triumph)`

### 21. mercenary_captain（傭兵隊長）

**属性**: 中年男性 / 傭兵
**設定**: チョキ偏重、戦術家。

```
1man, solo, mature male, mid forties, western features,
slicked-back dark hair, scar across nose, cold grey eyes,
weathered tanned skin, trim muscular disciplined build,
(full plate armor with mercenary insignia, dark red cape, 
longsword at hip, tactical belt with pouches, leather gloves),
mercenary captain aesthetic,
simple background, plain white background
```

- **encounter**: `(military salute, professional business proposition stance)`
- **battle**: `(trained fighter stance with sword drawn, tactical calm)`
- **farewell_win**: `(bitter professional defeat salute, teeth gritted, composed)`
- **farewell_lose**: `(cold professional victory nod, blade sheathed, dismissive)`

### 22. noble_merchant（中年貴族商人）

**属性**: 中年男性 / 貴族系商人
**設定**: パー偏重、洗練。

```
1man, solo, mature male, late forties, western features,
neat slicked-back black hair with silver temples, goatee beard,
calculating dark blue eyes, pale refined skin, elegant slim build,
(velvet noble coat with gold embroidery, silk cravat, leather gloves,
cane with gem topper, multiple rings), aristocratic merchant aesthetic,
simple background, plain white background
```

- **encounter**: `(refined bow with one hand behind back, elegant smile)`
- **battle**: `(composed noble stance, cane held ready, dignified)`
- **farewell_win**: `(pained dignified grimace, adjusting coat, composure cracked)`
- **farewell_lose**: `(satisfied aristocratic smile, bowing mockingly)`

---

### カテゴリー D：中年女性（5体）

### 23. veteran_adventurer_female（ベテラン女冒険者）

**属性**: 中年女性 / 冒険者
**設定**: バランス型、熟練。

```
1girl, solo, mature female, late thirties, western features,
long braided red hair with silver streaks, sharp hazel eyes,
weathered tanned skin with faint scars, fit mature curvy figure,
(studded leather armor over practical top, utility belt, long sword,
travel cloak, multiple rings), veteran adventurer aesthetic,
simple background, plain white background
```

- **encounter**: `(experienced friendly nod, warrior greeting, hand on hip)`
- **battle**: `(seasoned combat stance, sword drawn smoothly, focused eyes)`
- **farewell_win（outfit_1相当）**: `(topless with mature breasts partially covered by 
  hair, dark underwear only, gritted teeth of seasoned shame,
  tears held back, armor scattered), tasteful mature nudity`
- **farewell_lose**: `(experienced victorious smirk, short nod, cards pocketed)`

### 24. tavern_owner_female（中年酒場女将）

**属性**: 中年女性 / 酒場女将
**設定**: パー偏重、肝っ玉。

```
1girl, solo, mature female, early forties, western features,
voluminous reddish-brown hair tied up with scarf, knowing amber eyes,
pale ruddy skin, voluptuous mature hourglass figure, 
(low-cut dress with corset, apron, shawl, multiple gold hoop earrings,
holding mop or tankard), bold barkeeper aesthetic,
simple background, plain white background
```

- **encounter**: `(bold hands-on-hips greeting, knowing motherly smirk)`
- **battle**: `(confident hands-on-hips challenge, experienced amused gaze)`
- **farewell_win（outfit_1相当）**: `(topless with large mature breasts 
  partially exposed, no underwear, (mosaic censoring on genitals, censored pubic area), blushing but still dignified,
  apron fallen, corset loosened), tasteful mature nudity`
- **farewell_lose**: `(booming hearty laugh, tankard raised, warm victory)`

### 25. noblewoman_mature（中年貴婦人）

**属性**: 中年女性 / 貴族
**設定**: チョキ偏重、気位高め。

```
1girl, solo, mature female, mid forties, western features,
elaborate updo of dark hair, ornate jewels, cold ice blue eyes,
porcelain pale well-maintained skin, slim elegant regal figure,
(elaborate noble gown with lace, pearl necklaces, silk gloves,
hand fan, delicate tiara), aristocratic noblewoman aesthetic,
simple background, plain white background
```

- **encounter**: `(haughty noble greeting, fan raised, dismissive elegance)`
- **battle**: `(aristocratic composure, cards held with gloved fingers, calm)`
- **farewell_win（outfit_1相当）**: `(topless with regal long hair draped, 
  no underwear, (mosaic censoring on genitals, censored pubic area), jewels still on, mortified noble dignity,
  dress pooled at feet, hand trying to maintain grace), 
  tasteful aristocratic nudity`
- **farewell_lose**: `(cold satisfied smile, fan snapped closed, proud nod)`

### 26. female_mercenary（女傭兵）

**属性**: 中年女性 / 傭兵
**設定**: グー偏重、歴戦。

```
1girl, solo, mature female, late thirties, western features,
short tousled platinum blonde hair, eyepatch over one eye, 
fierce grey eye visible, weathered tanned skin with scars,
athletic battle-hardened figure, (practical leather armor revealing 
battle scars, scarred skin, two swords crossed on back, trophy belt),
battle-hardened mercenary aesthetic,
simple background, plain white background
```

- **encounter**: `(cold professional assessment, eye narrowed, silent threat)`
- **battle**: `(twin swords drawn, battle-ready combat stance, deadly calm)`
- **farewell_win（outfit_1相当）**: `(topless with battle scars visible on torso,
  covering breasts with one arm, (mosaic censoring on genitals), no underwear, gritted 
  mercenary shame, armor dented and fallen), tasteful scarred warrior nudity`
- **farewell_lose**: `(cold mercenary victory sneer, blade sheathed, dismissive)`

### 27. female_priest（女司祭・中年）

**属性**: 中年女性 / 教会司祭
**設定**: パー偏重、説教好き。

```
1girl, solo, mature female, early forties, western features,
silver streaked brown hair under veil, gentle but firm green eyes,
pale skin with age lines, modest mature curvy figure, 
(dignified priestess robe with gold trim, large holy symbol,
prayer beads, long veil covering hair, staff with cross),
elder priestess aesthetic, simple background, plain white background
```

- **encounter**: `(gentle welcoming prayer gesture, wise motherly smile)`
- **battle**: `(holy staff raised in measured blessing, calm serenity)`
- **farewell_win（outfit_1相当）**: `(topless with modest mature breasts partially 
  covered by long veil, no underwear, (mosaic censoring on genitals, censored pubic area), prayer beads still on,
  devout shamed blush, robe pooled), tasteful sacred mature nudity`
- **farewell_lose**: `(serene blessing gesture, beatific smile of divine will)`

---

### カテゴリー E：老人男性（4体）

### 28. old_mage（老魔術師）

**属性**: 老年男性 / 魔術師
**設定**: チョキ偏重、杖と髭。

```
1oldman, solo, elderly male, seventies, western features,
long white beard, long white hair, wise pale blue eyes,
wrinkled weathered skin, thin frail robed frame,
(deep blue wizard robe with silver stars and moons, pointed wizard hat,
gnarled wooden staff with crystal orb top, rope belt, pouches),
classic archmage aesthetic, simple background, plain white background
```

- **encounter**: `(wise nod with staff planted, deep voice greeting)`
- **battle**: `(staff raised invoking, crystal glowing, scholarly focus)`
- **farewell_win**: `(collapsed onto staff, disbelieving wide eyes, wizard hat fallen)`
- **farewell_lose**: `(sagely chuckle, stroking long beard, satisfied wisdom)`

### 29. retired_knight（老騎士）

**属性**: 老年男性 / 引退騎士
**設定**: グー偏重、剣に頼る。

```
1oldman, solo, elderly male, late sixties, western features,
short white hair military cut, full white beard, stern blue eyes,
weathered scarred tanned skin, aging but still muscular frame,
(tarnished plate armor, faded red knight's cape, broadsword, 
tarnished signet ring, white cross on tunic), retired knight aesthetic,
simple background, plain white background
```

- **encounter**: `(formal knight's salute, dignified challenge, "old warrior" stance)`
- **battle**: `(traditional knight combat stance, sword high, honorable)`
- **farewell_win**: `(slumped on sword knee down, bitter knight defeat, weathered tears)`
- **farewell_lose**: `(dignified satisfied bow of honor, sword sheathed, noble)`

### 30. old_fisherman（老漁師）

**属性**: 老年男性 / 漁師
**設定**: バランス型、素朴。

```
1oldman, solo, elderly male, seventies, western features,
weathered bald head with white fringe, grizzled white beard, 
squinting tanned blue eyes, extremely weathered leathery skin,
thin wiry old build, (worn fisherman's vest, rolled-up canvas pants,
fishing net or rod in hand, pipe in mouth, straw hat, barefoot),
old sea-salt aesthetic, simple background, plain white background
```

- **encounter**: `(friendly wave with pipe, old fisherman's greeting)`
- **battle**: `(relaxed old-man stance, pipe in one hand, cards in other)`
- **farewell_win**: `(dumbfounded pipe falling, "well I'll be" shocked expression)`
- **farewell_lose**: `(old-timer chuckle, pipe still in mouth, sagely nod)`

### 31. old_priest（老司祭）

**属性**: 老年男性 / 教会司祭
**設定**: パー偏重、説教を垂れる。

```
1oldman, solo, elderly male, late sixties, western features,
short grey-white hair, neat trimmed white beard, kind deep brown eyes,
wrinkled pale skin, slight thin frame, (white clerical robe 
with gold trim, large silver cross pendant, rosary, priestly cap),
elderly priest aesthetic, simple background, plain white background
```

- **encounter**: `(priestly blessing gesture, warm paternal smile)`
- **battle**: `(calm holy stance, cross raised, serene focus)`
- **farewell_win**: `(bewildered crossing himself, "lord have mercy" expression)`
- **farewell_lose**: `(beatific priestly blessing, "god's will" smile)`

---

### カテゴリー F：老人女性（4体）

### 32. old_witch（老魔女）

**属性**: 老年女性 / 魔女
**設定**: チョキ偏重、怪しげ。

```
1oldwoman, solo, elderly female, seventies, western features,
long stringy grey hair, crooked nose, piercing green eyes,
wrinkled pale skin, hunched thin frame, (dark purple witch robe,
tall pointed witch hat, gnarled staff with skull, bone necklace,
multiple rings with gems, spellbook at hip), classic witch aesthetic,
simple background, plain white background
```

- **encounter**: `(cackling welcome with crooked finger, hunched menacing bow)`
- **battle**: `(staff raised with bony hand, witch cackle, eyes glowing)`
- **farewell_win**: `(screaming curses, hat falling off, furious defeat)`
- **farewell_lose**: `(triumphant cackling, staff banging ground, witch glee)`

### 33. kindly_grandma（優しいお婆さん）

**属性**: 老年女性 / 一般人
**設定**: パー偏重、穏やか。

```
1oldwoman, solo, elderly female, seventies, western features,
neat silver hair in bun, round spectacles, gentle blue eyes,
wrinkled pink soft skin, plump grandma figure, (simple woolen dress,
apron, shawl over shoulders, wicker basket with bread, 
knitting in hand), warm grandmother aesthetic,
simple background, plain white background
```

- **encounter**: `(kindly beckoning with a cookie, grandma's smile)`
- **battle**: `(unlikely-but-determined grandma stance, cards in wrinkled hand)`
- **farewell_win**: `(sad grandma "oh dear" expression, fanning herself with apron)`
- **farewell_lose**: `(proud satisfied grandma smile, patting own head in glee)`

### 34. old_fortune_teller（老占い師）

**属性**: 老年女性 / 占い師
**設定**: バランス型、神秘的。

```
1oldwoman, solo, elderly female, seventies, western features,
long dark hair with silver streaks, heavy dark makeup, 
knowing piercing purple eyes, pale mysterious skin, thin regal frame,
(colorful gypsy robes with elaborate patterns, many bangles, 
crystal ball or tarot cards, head scarf with coins, multiple necklaces),
fortune teller aesthetic, simple background, plain white background
```

- **encounter**: `(mysterious hand gestures over crystal, knowing sly smile)`
- **battle**: `(prophetic gaze, shuffling tarot cards, calm certainty)`
- **farewell_win**: `(dramatic "the stars betrayed me!" anguished pose, scarves flying)`
- **farewell_lose**: `(knowing "as foretold" smile, mystical satisfied gesture)`

### 35. retired_veteran_female（老女傭兵）

**属性**: 老年女性 / 引退傭兵
**設定**: グー偏重、頑固。

```
1oldwoman, solo, elderly female, late sixties, western features,
short cropped grey-white hair, numerous scars on face,
sharp cold grey eyes, leathery weathered skin, still-fit 
wiry old warrior frame, (tarnished leather armor over simple tunic,
battered sword at belt, old mercenary insignia, calloused hands),
retired warrior aesthetic, simple background, plain white background
```

- **encounter**: `(grizzled assessing stare, gruff nod of challenge)`
- **battle**: `(old warrior fighting stance, sword drawn despite age, fierce)`
- **farewell_win**: `(angry grizzled curse, grey head shaking, pride wounded)`
- **farewell_lose**: `(old warrior satisfied grunt, "still got it" nod)`

---

### カテゴリー G：貴族男女（6体）

### 36. young_noble_male（若貴族男）

**属性**: 若年男性 / 貴族
**設定**: パー偏重、傲慢。

```
1boy, solo, young adult, early twenties, western features,
perfectly coiffed blonde hair, haughty blue eyes, pale fine skin,
slim effeminate noble frame, (elegant blue noble coat with silver trim,
lace cravat, velvet breeches, polished boots, ceremonial rapier,
family signet ring), pampered aristocrat aesthetic,
simple background, plain white background
```

- **encounter**: `(haughty noble sneer, hand on chest mockingly, looking down)`
- **battle**: `(effete noble fencing stance, rapier drawn delicately)`
- **farewell_win**: `(horrified noble dignity shattered, hair mussed, tearful outrage)`
- **farewell_lose**: `(satisfied aristocratic smirk, mock-bow of victory)`

### 37. young_noble_female（若貴族女）

**属性**: 若年女性 / 貴族
**設定**: チョキ偏重、お嬢様。

```
1girl, solo, young adult, early twenties, western features,
pink blonde curls in elaborate ringlets, vibrant violet eyes,
porcelain pale skin, slim refined figure, (ornate pastel pink noble 
dress with lace and ribbons, parasol, pearl necklace, silk gloves,
delicate jewels, dainty shoes), pampered young lady aesthetic,
simple background, plain white background
```

- **encounter**: `(delicate haughty curtsy, parasol twirling, condescending)`
- **battle**: `(prim ladylike stance, cards held gracefully, refined)`
- **farewell_win（outfit_1相当）**: `(topless with pink long curls covering breasts,
  no underwear, (mosaic censoring on genitals, censored pubic area), deep aristocratic mortification, parasol fallen,
  dress pooled around feet), tasteful noble nudity`
- **farewell_lose**: `(triumphant delicate giggle, hand daintily over mouth)`

### 38. mature_noble_male（壮年貴族男）

**属性**: 中年男性 / 貴族
**設定**: バランス型、威厳。

```
1man, solo, mature male, fifties, western features,
neat silver-streaked dark hair, well-groomed goatee, 
shrewd hazel eyes, refined pale skin, stately imposing frame,
(lavish velvet burgundy coat with gold brocade, ornate cravat,
heavy signet rings, gold watch chain, cane with gem), 
lord aristocrat aesthetic, simple background, plain white background
```

- **encounter**: `(stately noble bow, dignified greeting, cane tapping)`
- **battle**: `(aristocratic composure, cards held precisely, calm confidence)`
- **farewell_win**: `(strained noble composure, teeth gritted dignity, adjusting coat)`
- **farewell_lose**: `(satisfied lord's smile, slight dignified nod of victory)`

### 39. mature_noble_female（壮年貴婦人）

**属性**: 中年女性 / 貴族（前述 noblewoman_mature と別個体、色違い）
**設定**: パー偏重、冷徹。

```
1girl, solo, mature female, late forties, western features,
jet black hair in severe updo with jewels, cold emerald eyes,
pale flawless skin, slim severe elegant figure, (dark green 
noble gown with black lace, emerald necklace, long black gloves,
mourning veil optional, fan, elaborate hair ornaments),
cold aristocratic dowager aesthetic,
simple background, plain white background
```

- **encounter**: `(cold haughty assessment, fan raised imperiously)`
- **battle**: `(glacial composed stance, calm calculating stare)`
- **farewell_win（outfit_1相当）**: `(topless with mature breasts covered by long 
  black hair, no underwear, (mosaic censoring on genitals, censored pubic area), frigid aristocratic humiliation,
  jewels still intact, emerald necklace glinting), tasteful dowager nudity`
- **farewell_lose**: `(icy pleased smile, fan snapped sharply, triumph)`

### 40. male_baron（中年貴族男2・領主）

**属性**: 中年男性 / 領主貴族
**設定**: グー偏重、横柄。

```
1man, solo, mature male, early forties, western features,
receding black hair, thick mustache, piercing dark brown eyes,
ruddy refined skin, portly noble frame, (royal blue dukedom coat,
gold shoulder ornaments, heavy chain of office, polished boots,
ceremonial sword, ring of rank), pompous baron aesthetic,
simple background, plain white background
```

- **encounter**: `(pompous chest-thrust greeting, dismissive wave)`
- **battle**: `(entitled fighting stance, cards flashed boastfully)`
- **farewell_win**: `(indignant fuming purple-red face, cards ruined, outraged)`
- **farewell_lose**: `(puffed-up baron victory, chain of office rattled)`

### 41. female_duchess（若女公爵）

**属性**: 若年女性 / 公爵家令嬢
**設定**: チョキ偏重、気高い。

```
1girl, solo, young adult, early twenties, western features,
flowing platinum blonde hair with silver tiara, piercing sapphire eyes,
flawless porcelain skin, slim aristocratic statuesque figure,
(elegant silver and blue gown, fur-trimmed cape, silver tiara,
diamond jewelry, white opera gloves), young duchess aesthetic,
simple background, plain white background
```

- **encounter**: `(regal formal curtsy, cold aristocratic acknowledgment)`
- **battle**: `(poised duelist stance, gloved hand raised, calm)`
- **farewell_win（outfit_1相当）**: `(topless with long platinum hair draped,
  (mosaic censoring on genitals), no underwear, tiara still on,
  aristocratic devastation, gown in graceful collapse), 
  tasteful duchess nudity`
- **farewell_lose**: `(regal cold satisfied smile, slight graceful nod)`

---

### カテゴリー H：神官・宗教系男女（4体）

### 42. male_monk（男性修道士）

**属性**: 中年男性 / 修道士
**設定**: グー偏重、格闘派。

```
1man, solo, mature male, late thirties, western features,
shaved bald head, stern dark eyes, weathered tanned skin,
heavily muscular disciplined frame, (simple brown monastic robe 
tied with rope, prayer beads around neck, bare feet, fighting stance 
fists ready, quarterstaff optional), warrior monk aesthetic,
simple background, plain white background
```

- **encounter**: `(formal martial bow, fist to open palm, solemn greeting)`
- **battle**: `(martial arts stance, disciplined focused gaze, zen calm)`
- **farewell_win**: `(reflective disappointed monk, meditative loss posture)`
- **farewell_lose**: `(solemn bow of respect, "the discipline prevails" face)`

### 43. nun_mid（中年シスター）

**属性**: 中年女性 / シスター
**設定**: パー偏重、慈愛。

```
1girl, solo, mature female, late thirties, western features,
hidden hair under full habit, gentle grey eyes, pale skin,
modest curvy figure, (full traditional nun habit, white wimple,
black veil, large rosary, wooden cross, prayer beads), 
sister aesthetic, simple background, plain white background
```

- **encounter**: `(gentle cross sign, peaceful welcoming pose)`
- **battle**: `(hands folded in prayer yet ready, serene focus)`
- **farewell_win（outfit_1相当）**: `(topless with modest breasts covered by long 
  hair now visible, simple no underwear, (mosaic censoring on genitals, censored pubic area), rosary still on,
  profound religious shame, habit fallen into a pile), tasteful nun nudity`
- **farewell_lose**: `(blessing gesture, serene divine smile)`

### 44. priest_mid（中年神父）

**属性**: 中年男性 / 神父
**設定**: バランス型、説教と剣。

```
1man, solo, mature male, early forties, western features,
neat short brown hair, kind but sharp blue eyes, pale priestly skin,
fit disciplined frame, (black priest's cassock with white collar,
large pectoral cross, prayer book, rosary at hip, sometimes with 
hidden blade), priest warrior aesthetic,
simple background, plain white background
```

- **encounter**: `(sign of cross blessing, paternal smile of challenge)`
- **battle**: `(priestly composed stance, cross pendant held, calm faith)`
- **farewell_win**: `(questioning faith, hand to forehead, troubled priest)`
- **farewell_lose**: `(serene priestly victory, blessing the opponent)`

### 45. shrine_maiden（神社の巫女風神官）

**属性**: 若年女性 / 神官
**設定**: チョキ偏重、神秘的。

```
1girl, solo, young adult, early twenties, western features but exotic,
long straight black hair, mystic red eyes, pale porcelain skin,
slim graceful figure, (white and red shrine maiden inspired robe,
long white sleeves, red hakama skirt, traditional ribbons in hair,
purification staff with paper streamers), exotic shrine maiden aesthetic,
simple background, plain white background
```

- **encounter**: `(ceremonial bow, waving purification staff, mystical greeting)`
- **battle**: `(ritual dance-like stance, staff raised, streaming paper)`
- **farewell_win（outfit_1相当）**: `(topless with long black hair covering breasts,
  no underwear, (mosaic censoring on genitals, censored pubic area), hair ribbons still on, mortified sacred 
  shame, robes fallen, maiden virginal shame), tasteful sacred nudity`
- **farewell_lose**: `(serene mystical smile, staff raised in blessing)`

---

### カテゴリー I：盗賊・犯罪者男女（4体）

### 46. female_thief（女盗賊・一般）

**属性**: 若年女性 / 盗賊
**設定**: チョキ偏重、敏捷。

```
1girl, solo, young adult, mid twenties, western features,
short choppy dark hair, mischievous amber eyes, fair skin 
with small scar on cheek, slim agile figure, (dark leather 
armor revealing midriff, leather cropped pants, dark knee-high boots,
daggers on thighs, fingerless gloves, bandana mask around neck),
sexy female thief aesthetic, simple background, plain white background
```

- **encounter**: `(sly crouched approach, finger to lips, "shh" pose)`
- **battle**: `(acrobatic ready stance, daggers drawn, predatory grin)`
- **farewell_win（outfit_1相当）**: `(topless with arms over medium breasts,
  no underwear, (mosaic censoring on genitals, censored pubic area), nipples partially obscured, angry fox-like defeat,
  armor scattered around feet, tomboyish shame), tasteful thief nudity`
- **farewell_lose**: `(mischievous wink of victory, dagger tossed and caught)`

### 47. thief_oldman（老盗賊）

**属性**: 老年男性 / 盗賊
**設定**: パー偏重、狡猾。

```
1oldman, solo, elderly male, late sixties, western features,
greying long hair in ponytail, scarred weathered face, 
cunning dark eyes, tanned leathery skin, thin wiry agile old frame,
(worn dark leather vest, patched rogue's cloak with many pockets,
lockpicks visible, daggers, grizzled mustache, gold tooth), 
veteran rogue aesthetic, simple background, plain white background
```

- **encounter**: `(cunning half-bow, gold tooth grin, experienced rogue greeting)`
- **battle**: `(experienced sly fighting stance, dagger drawn slowly)`
- **farewell_win**: `(bitter aged rogue "outfoxed" grimace, crooked back)`
- **farewell_lose**: `(aged cackle of victory, pocketing cards, winking)`

### 48. assassin_minor（下級暗殺者）

**属性**: 若年男性 / 暗殺者
**設定**: グー偏重、冷静。

```
1man, solo, young adult, mid twenties, western features,
short black hair, cold calculating blue eyes, pale skin,
slim trained athletic frame, (fitted black assassin outfit, 
hooded cloak, face mask pulled down around chin, multiple daggers,
wrist blades, dark leather gloves), lower assassin aesthetic,
simple background, plain white background
```

- **encounter**: `(emerging from shadow, hood low, cold professional nod)`
- **battle**: `(deadly trained stance, hidden blades revealed, silent focus)`
- **farewell_win**: `(disbelieving cold shock, hood falling, professional composure lost)`
- **farewell_lose**: `(cold professional victory, sheathing blade silently)`

### 49. poison_herbalist（毒草使い女）

**属性**: 中年女性 / 毒草使い
**設定**: バランス型、妖しい。

```
1girl, solo, mature female, early thirties, western features,
long wavy dark green-black hair, hypnotic purple eyes,
pale slightly green-tinged skin, slim seductive figure, 
(tight dark green dress with herb pouches, poison vials at belt,
sharp dagger, necklace of vials, herbs in hair), herbalist witch aesthetic,
simple background, plain white background
```

- **encounter**: `(seductive hypnotic smile, vial raised alluringly)`
- **battle**: `(swaying seductive combat stance, dagger dipped in poison)`
- **farewell_win（outfit_1相当）**: `(topless with mature breasts mostly exposed,
  no underwear, (mosaic censoring on genitals, censored pubic area), vials still attached to thigh strap,
  furious poisoner defeat, dress pooled, green-tinged skin flushed),
  tasteful seductress nudity`
- **farewell_lose**: `(triumphant poisoner smile, licking lips victoriously)`

---

### カテゴリー J：その他の市井人（1体で50体到達）

### 50. traveling_bard（旅の吟遊詩人・男）

**属性**: 若年〜中年男性 / 吟遊詩人
**設定**: パー偏重、口八丁。

```
1man, solo, young adult to mid twenties, western features,
long brown hair tied back with ribbon, twinkling green eyes,
fair skin, slim lean frame, (colorful bard's tunic with puffy sleeves,
leather belt, lute slung on back, feathered cap, traveler's boots,
multiple rings), flamboyant bard aesthetic,
simple background, plain white background
```

- **encounter**: `(flamboyant bow with hat-sweep, charming smile, lute ready)`
- **battle**: `(theatrical "ta-da" pose, strumming lute challenge, flourishing)`
- **farewell_win**: `(dramatic stage-fall of defeat, lute clutched to chest, tearful ballad)`
- **farewell_lose**: `(victorious bardic flourish, strumming triumph song)`

---

## サマリ

| カテゴリー | 人数 | ID例 |
|---|---|---|
| 既存登録（実装済み） | 7 | thug_a, thug_b, drunk, merchant, merchant2, sailor, bandit |
| 若年男性 | 5 | novice_adventurer_male, apprentice_mage_male, pickpocket_boy, stable_boy, young_guard |
| 若年女性 | 5 | novice_adventurer_female, priestess_young, female_swordswoman, barmaid, female_scholar |
| 中年男性 | 5 | veteran_adventurer_male, innkeeper_male, blacksmith_battler, mercenary_captain, noble_merchant |
| 中年女性 | 5 | veteran_adventurer_female, tavern_owner_female, noblewoman_mature, female_mercenary, female_priest |
| 老年男性 | 4 | old_mage, retired_knight, old_fisherman, old_priest |
| 老年女性 | 4 | old_witch, kindly_grandma, old_fortune_teller, retired_veteran_female |
| 貴族男女 | 6 | young_noble_male, young_noble_female, mature_noble_male, mature_noble_female, male_baron, female_duchess |
| 神官系男女 | 4 | male_monk, nun_mid, priest_mid, shrine_maiden |
| 盗賊系男女 | 4 | female_thief, thief_oldman, assassin_minor, poison_herbalist |
| その他 | 1 | traveling_bard |
| **合計** | **50** | |

---

## 画像生成時のチェックリスト

- [ ] 4ポートレート（encounter / battle / farewell_win / farewell_lose）全て揃える
- [ ] 女性敵の `farewell_win` は **outfit_1 相当（パンティのみ、乳房露出）**
- [ ] 男性敵の `farewell_win` は衣装乱れ・屈辱で表現（全裸描写なし）
- [ ] 全敵 `simple background, plain white background` で後工程の背景除去に対応
- [ ] ネガティブプロンプトに **`monster, animal, creature, beast` 等の非人間タグ**を必ず含める
- [ ] 年齢表記を明確に（`young adult`, `mature`, `elderly` 等でモデルガード対策）

---

## EncounterDatabase.gd への登録（実装タスク）

新規43体を `EncounterDatabase.gd` に登録する場合、以下のフォーマットに従う:

```gdscript
"<id>": {
    "id": "<id>",
    "name": "<日本語名>",
    "portraits": {
        "encounter": {"path": "res://assets/characters/random_battle/<id>_encounter.png", ...},
        "battle": {"path": "res://assets/characters/random_battle/<id>_battle.png", ...},
        "farewell_win": {"path": "res://assets/characters/random_battle/<id>_win.png", ...},
        "farewell_lose": {"path": "res://assets/characters/random_battle/<id>_lose.png", ...},
    },
    "lines": { ... },
    "hand": [...],
    "tendency": {...},
    "gold_reward": {"min": X, "max": Y},
},
```

セリフ（`lines`）はシナリオ作成時に別途追加する。本ファイルは画像プロンプトのみを扱う。
