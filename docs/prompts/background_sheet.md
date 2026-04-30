# Background Sheet（背景設定シート）

全シナリオで使用される背景画像の基本定義。
背景はキャラ立ち絵とは別に単独生成する想定（キャラなし、風景・室内のみ）。

フォーマット:
- **背景ID / ファイル名**: 実装側ファイル名
- **場所**: 実世界モデル（あれば）
- **時間帯・光**: 昼／夕／夜、光源、色温度
- **主な配置**: 画面内の構図要素
- **雰囲気**: 醸し出す空気
- **使用章**: 登場シナリオ
- **NovelAIタグ例**

---

## プロローグ専用背景

### bg01_university.png（大学キャンパス）

- **場所**: 日本の国立大学キャンパス、春〜初夏
- **時間帯・光**: 昼、柔らかい自然光、暖色寄り
- **主な配置**: 桜並木 or 新緑の街路樹、中庭、石畳の通路、奥に校舎
- **雰囲気**: のどかな日常、学生生活
- **使用章**: プロローグ場面1・2
- **NovelAIタグ例**:
  ```
  japanese university campus, spring afternoon, cherry blossoms,
  stone paved path, background building, soft natural light,
  warm tones, peaceful daily life, no humans
  ```

### bg02_room.png（サトシの部屋）

- **場所**: 日本のワンルームマンション、雑然とした大学生の部屋
- **時間帯・光**: 夜、蛍光灯、やや黄色い室内光
- **主な配置**: 散らかったベッド、机の上にエロゲのパッケージと政治パンフ、
  床に教科書の雪崩、壁にポスター、ノートPC
- **雰囲気**: ダメ学生の生態、整理されていない日常
- **使用章**: プロローグ場面3
- **NovelAIタグ例**:
  ```
  messy japanese student room, single bed, cluttered desk,
  galge game packages, political pamphlets, textbook avalanche,
  posters on wall, laptop, fluorescent indoor light, night
  ```

### bg03-1_lab.png（加速器施設・通常）

- **場所**: 大型加速器実験施設（SPring-8 風）
- **時間帯・光**: 夜、蛍光灯、硬質な白色光
- **主な配置**: 巨大な円環加速器の一部、制御盤、ケーブルが束ねられた配線、
  青い非常灯、奥に鉛板、案内表示
- **雰囲気**: 無機質、ハイテク、SF感
- **使用章**: プロローグ場面4・5
- **NovelAIタグ例**:
  ```
  large particle accelerator facility, SPring-8 style, control panels,
  bundled cables, blue emergency lights, concrete walls,
  sci-fi industrial, cold white fluorescent light, no humans
  ```

### bg03-2_lab.png（加速器施設・暴走）

- **場所**: 同施設、事故発生時
- **時間帯・光**: 強烈な白色フラッシュ、一瞬の過剰光
- **主な配置**: 制御盤が白く飛ぶ、火花、警告灯が赤く点滅、空気が歪む
- **雰囲気**: 制御不能、パニック、光の渦
- **使用章**: プロローグ場面5
- **NovelAIタグ例**:
  ```
  particle accelerator malfunction, blinding white flash,
  red warning lights flashing, sparks, control panels overloading,
  distorted space, chaotic atmosphere, no humans
  ```

### bg04-1_teleport_square.png（転移中・空間1）

- **場所**: 異次元の転送空間
- **時間帯・光**: 光の渦、色は青〜紫〜金の虹彩
- **主な配置**: 落下する身体の軌跡（キャラは別素材）、渦巻く光の層
- **雰囲気**: 幻想、無重力、めまい
- **使用章**: プロローグ場面6
- **NovelAIタグ例**:
  ```
  interdimensional teleportation space, spiraling light vortex,
  iridescent colors, blue purple gold, floating particles,
  zero gravity abstract, ethereal atmosphere, no humans
  ```

### bg04-2_teleport_square2.png（転移後・王都アレクシア広場）

- **場所**: 王都アレクシアの石畳の中央広場
- **時間帯・光**: 朝〜昼、明るい陽光
- **主な配置**: 石畳、中世ヨーロッパ風の建物、奥に噴水、城壁と塔、
  市民が行き交う広場（背景人物は薄く）
- **雰囲気**: 中世ファンタジー、異世界の活気
- **使用章**: プロローグ場面7
- **NovelAIタグ例**:
  ```
  medieval european fantasy town square, cobblestone ground,
  stone buildings, fountain in background, castle walls and tower,
  bright morning light, bustling atmosphere, no humans
  ```

### bg05_prison_cell.png（牢屋）

- **場所**: 王都アレクシアの地下牢屋
- **時間帯・光**: 松明の暖色光、暗めの陰影
- **主な配置**: 鉄格子、石壁、粗い藁の寝床、木製の小さな机、
  壁に掛かった鎖、通路側から松明の灯り
- **雰囲気**: 閉塞感、湿気、松明のオレンジ
- **使用章**: プロローグ場面8〜12C
- **NovelAIタグ例**:
  ```
  medieval prison cell, iron bars, stone walls, straw bed,
  wooden small table, chains on wall, torch light,
  warm orange flickering light, dim shadows, atmospheric, no humans
  ```

---

## ステージ1 / 汎用背景

### bg06_st1_001.png（王都アレクシア・ギルド通り）

- **場所**: 王都の冒険者ギルド周辺の石畳通り
- **時間帯・光**: 昼、自然光、活気のある色温度
- **主な配置**: 石畳、ギルドの看板、酒場、石造りの街並み、
  背景に行き交う冒険者のシルエット（薄く）
- **雰囲気**: 冒険者の街、活気、石と木の建築
- **使用章**: ステージ1 場面10〜11
- **NovelAIタグ例**:
  ```
  medieval fantasy town street, adventurer guild district,
  cobblestone road, stone and wood buildings, guild sign,
  tavern, bright afternoon light, lively atmosphere, no humans
  ```

### bg07_st1_001.png（冒険者ギルド内）

- **場所**: 冒険者ギルドの受付ホール
- **時間帯・光**: 昼〜夕方、木と石の暖色、天井から吊るされたシャンデリア
- **主な配置**: 木製の受付カウンター、奥の酒場エリア、壁に掛かった依頼掲示板、
  天井の梁、吊り照明、石壁、木のテーブル・椅子
- **雰囲気**: 温かみある内装、冒険者たちの集まる場所
- **使用章**: ステージ1 場面12・13、サブイベ1・2の受付、サブイベ3・4、
  stage3 場面2、stage4 場面1、stage6 場面1、stage7 場面2
  （最多使用背景）
- **NovelAIタグ例**:
  ```
  adventurer guild interior hall, wooden reception counter, tavern area,
  quest board on wall, wooden beams, hanging chandelier, stone walls,
  wooden tables and chairs, warm cozy atmosphere, afternoon light, no humans
  ```

### bg06_prison_arena.png（裏通り／アジト前／アジト内）

- **場所**: 王都の裏路地、盗賊団アジトの前、アジト内（同じ背景の使い回し）
- **時間帯・光**: 昼でも薄暗い、曇天 or 早朝／石壁の影が強め
- **主な配置**: 石造りの壁、狭い路地、古い扉、木の樽、積まれた箱
- **雰囲気**: 薄暗い、不穏、人目を避ける場所
- **使用章**: サブイベ1 場面2〜6、stage4 場面2
- **NovelAIタグ例**:
  ```
  medieval fantasy back alley, narrow stone passage, old wooden door,
  barrels, stacked crates, overcast sky, dim lighting,
  shadowy atmosphere, no humans
  ```

---

## サブイベント2・教会背景

### bg01_church_exterior.png（聖アレクシア教会・正面入り口）

- **場所**: 聖アレクシア教会の正面外観
- **時間帯・光**: 昼、明るい日差し、ステンドグラスが外から見える
- **主な配置**: 大きな石造りの教会、尖塔、ステンドグラスの丸窓、
  中央の大扉、石段、柱廊、十字架のシンボル
- **雰囲気**: 荘厳、威圧的、神聖
- **使用章**: サブイベ2 場面2
- **NovelAIタグ例**:
  ```
  grand stone cathedral exterior, gothic style, tall spire,
  large stained glass rose window, central double doors, stone steps,
  columns, christian cross, bright daylight, solemn atmosphere, no humans
  ```

### bg02_church_interior.png（教会・礼拝堂内部）

- **場所**: 教会内部の礼拝堂
- **時間帯・光**: 昼、ステンドグラス越しの彩り光、柔らかい
- **主な配置**: 長椅子の列、奥に祭壇、大きな十字架、高い天井、
  ステンドグラス、石柱、中央通路
- **雰囲気**: 神聖、静謐、光の彩り
- **使用章**: サブイベ2 場面3前半・5、stage3 場面3・4・8（流用想定）
- **NovelAIタグ例**:
  ```
  grand cathedral interior, rows of wooden pews, altar at back,
  large golden cross, high vaulted ceiling, stained glass windows,
  colorful light beams, stone columns, central aisle, solemn, no humans
  ```

### bg03_church_backyard.png（教会・裏庭）

- **場所**: 教会の裏庭、人目のつかない小庭
- **時間帯・光**: 昼、木漏れ日、柔らかい
- **主な配置**: 石壁、古い石のベンチ、小さな泉、薔薇の茂み、
  蔦の絡まった壁、小さな裏口の扉
- **雰囲気**: 静か、秘密の場所、人目を避ける相談所
- **使用章**: サブイベ2 場面3後半
- **NovelAIタグ例**:
  ```
  church backyard garden, secluded, stone walls, ivy covered walls,
  old stone bench, small fountain, rose bushes, wooden back door,
  dappled sunlight, peaceful hidden space, no humans
  ```

### bg04_church_corridor.png（教会・廊下）

- **場所**: 教会の奥の廊下
- **時間帯・光**: 薄暗い、窓からの薄い光、石の冷たい雰囲気
- **主な配置**: 石造りの長い廊下、両脇に木の扉、壁に掛かった蝋燭立て、
  石の天井アーチ
- **雰囲気**: 静か、厳か、やや不気味
- **使用章**: サブイベ2 場面4前半
- **NovelAIタグ例**:
  ```
  church corridor, stone walls, long hallway, wooden doors on sides,
  candle sconces on walls, stone arch ceiling, dim light from windows,
  quiet solemn atmosphere, no humans
  ```

### bg05_church_peep_room.png（特別礼拝室／覗き部屋）

- **場所**: 教会の「特別礼拝室」（裏の覗き部屋）
- **時間帯・光**: 薄暗い、蝋燭と小窓のわずかな光、隠微
- **主な配置**: 石壁、床に絨毯、奥の壁に小さな穴（覗き穴）、
  机の上に帳簿、椅子、小さな祈祷台（建前上）
- **雰囲気**: 隠微、後ろ暗い、秘密
- **使用章**: サブイベ2 場面4後半
- **NovelAIタグ例**:
  ```
  hidden secret chapel room, dim candle light, stone walls,
  small peephole on wall, old wooden desk with ledger book,
  small kneeling altar, carpet floor, secretive atmosphere, no humans
  ```

### bg06_church_dungeon.png（教会・地下牢）※未使用

- **場所**: 教会の地下牢獄
- **時間帯・光**: 暗い、微かな松明光
- **主な配置**: 石の壁、鉄格子、鎖、石の床、水たまり
- **雰囲気**: 冷たい、湿気、絶望
- **使用章**: 敗北ルート想定・現状未使用
- **NovelAIタグ例**:
  ```
  church dungeon basement, stone walls, iron bars, chains,
  wet stone floor, faint torchlight, cold damp atmosphere,
  oppressive, no humans
  ```

---

## ステージ2〜6の新規背景（仮）

### stage2/bg_moonleaf_dining.png（月の葉亭・食事処）

- **場所**: 古民家風の食事処、薄暗く妖しい
- **時間帯・光**: 夜、蝋燭の暖色光、薄暗い
- **主な配置**: 円卓、2人分の椅子、銀食器、ワイングラス、
  奥にデッキ台座、壁に蝋燭台、古びた木の梁
- **雰囲気**: 密室、妖艶、罠めいた静けさ
- **使用章**: ステージ2 場面2・6
- **NovelAIタグ例**:
  ```
  old-style dining establishment, dim candle light, round wooden table,
  two chairs, silver tableware, wine glasses, candlesticks on wall,
  wooden beams, secluded intimate atmosphere, no humans
  ```

### stage2/bg_guild_resting.png（ギルド休憩室）

- **場所**: ギルドの小さな休憩室／作戦会議室
- **時間帯・光**: 室内灯、暖色、落ち着いた
- **主な配置**: 木のテーブル、椅子、壁面に簡素な地図、ランプ、
  本棚、粗いコーヒーポット
- **雰囲気**: 落ち着き、作戦会議に適した地味な空間
- **使用章**: ステージ2 場面4・5、ステージ3 場面5、ステージ4 場面2.6・4.6・5、
  ステージ5 場面5
- **NovelAIタグ例**:
  ```
  small guild meeting room, wooden table and chairs, simple map on wall,
  warm lamp light, bookshelf, coffee pot, humble plain interior,
  tactical briefing atmosphere, no humans
  ```

---

### stage3/bg_inn_exterior.png（宿屋前）

- **場所**: 王都の石造りの安宿、表通り
- **時間帯・光**: 朝、朝靄がうっすら、柔らかい光
- **主な配置**: 古い石造の建物、木の扉、軒先のランプ、
  看板（手書き）、石畳、通り
- **雰囲気**: 庶民的、朝の静けさ
- **使用章**: ステージ3 場面1
- **NovelAIタグ例**:
  ```
  medieval inn exterior, morning light, faint mist, old stone building,
  wooden door, hanging lamp, hand painted sign, cobblestone street,
  humble quaint atmosphere, no humans
  ```

### stage3/bg_cathedral_interior.png（大聖堂内部）

- **場所**: 聖アレクシア大聖堂、野球拳決戦の場（長椅子、祭壇）
- **時間帯・光**: 昼、ステンドグラス越しの壮麗な光
- **主な配置**: 広い礼拝堂、長椅子多数、奥に大きな祭壇、巨大な十字架、
  高いステンドグラス、石柱が立ち並ぶ、中央通路
- **雰囲気**: 荘厳、厳粛、信徒の視線を意識させる大空間
- **使用章**: ステージ3 場面4・8
- **NovelAIタグ例**:
  ```
  grand cathedral interior, many wooden pews, massive altar with
  huge golden cross, towering stained glass windows, stone columns,
  central aisle, solemn grand atmosphere, dramatic light beams, no humans
  ```

### stage3/bg_cathedral_night.png（大聖堂・夜）

- **場所**: 同大聖堂、深夜
- **時間帯・光**: 夜、月光がステンドグラス越し、青系、蝋燭は消えている
- **主な配置**: 同上だが灯りなし、月光のみ
- **雰囲気**: 静寂、侵入者の緊張感、神聖だが別世界感
- **使用章**: ステージ3 場面6（深夜潜入）
- **NovelAIタグ例**:
  ```
  grand cathedral interior at night, moonlight through stained glass,
  dark blue tones, extinguished candles, empty pews, shadowy atmosphere,
  silent tense, no humans
  ```

### stage3/bg_magdalena_room.png（マグダレナの自室）

- **場所**: 教会奥の大司祭の私室
- **時間帯・光**: 夜、小さなランプ、薄暗い
- **主な配置**: 書棚、机、絨毯、奥にベッド、祈祷用小コーナー、
  壁に十字架、床板（後で剥がされる場所）
- **雰囲気**: 整頓されて上品、裏の秘密を隠す感
- **使用章**: ステージ3 場面6
- **NovelAIタグ例**:
  ```
  high priestess private chamber at night, bookshelf, wooden desk,
  ornate rug, bed in background, small prayer corner, cross on wall,
  wooden floor, dim lamp light, tidy but mysterious, no humans
  ```

---

### stage4/bg_military_back_wall.png（魔法師団本部・裏手）

- **場所**: 魔法師団本部の外壁の死角
- **時間帯・光**: 深夜、月光、青系寒色
- **主な配置**: 高い石壁、魔法陣の彫り込み（壁面）、衛兵の巡回跡、
  裏路地との境界、薄く漂う魔力光
- **雰囲気**: 緊張、警備厳重、魔導的警戒
- **使用章**: ステージ4 場面2.5
- **NovelAIタグ例**:
  ```
  military headquarters back wall at night, tall stone wall,
  magical runes carved on wall, faint magical glow, moonlight,
  cold blue tones, tense guarded atmosphere, no humans
  ```

### stage4/bg_dojo_third.png（第三演習場）

- **場所**: 魔法師団の第三演習場、広く高い天井
- **時間帯・光**: 昼〜屋内光、天窓から差す光、冷たい
- **主な配置**: 石造りの広い床、床に魔法陣の彫り込み、中央に玉座状の魔導椅子、
  天井アーチ、壁に魔導記録具の並び、師団員の席（奥）
- **雰囲気**: 威圧、試験会場、魔導装置の集積
- **使用章**: ステージ4 場面3・4・7
- **NovelAIタグ例**:
  ```
  large magical training hall, stone floor with magical circles,
  throne-like magical chair in center, high arched ceiling,
  skylights, magical recording devices on walls, intimidating, no humans
  ```

---

### stage5/bg_royal_street.png（王都大通り）

- **場所**: 王都の中心大通り
- **時間帯・光**: 昼、明るい陽光
- **主な配置**: 広い石畳、露店の並び、王宮方向の塔、行き交う人のシルエット（薄く）、
  噴水、旗
- **雰囲気**: 活気、公的、王都の表玄関
- **使用章**: ステージ5 場面1
- **NovelAIタグ例**:
  ```
  royal capital main street, wide cobblestone road, market stalls,
  royal palace tower in distance, fountain, flags, bright daylight,
  bustling public atmosphere, no humans
  ```

### stage5/bg_interrogation_room.png（取調室）

- **場所**: 騎士団本部の取調室
- **時間帯・光**: 窓なし、蝋燭と油灯、暖色だが陰鬱
- **主な配置**: 石造りの狭い部屋、中央の木製机、机上に水晶球（心鏡の珠）、
  両脇に騎士団員の待機位置、奥の椅子、壁に拷問具風の道具（威圧用）
- **雰囲気**: 威圧、密室、逃げ場なし
- **使用章**: ステージ5 場面3
- **NovelAIタグ例**:
  ```
  medieval interrogation room, stone walls, no windows, wooden table
  in center, crystal ball on table, candle light, oil lamps,
  oppressive small chamber, shadowy corners, no humans
  ```

### stage5/bg_training_ground.png（中央訓練場）

- **場所**: 騎士団本部の中央訓練場、屋外
- **時間帯・光**: 昼、強い日差し、白砂の反射
- **主な配置**: 白砂の広場、周囲に騎士団の列席用石ベンチ、旗が並ぶ、
  中央にデッキ台座、石造りの柱が等間隔に、奥に練武場の建物
- **雰囲気**: 公的、決闘の場、規律
- **使用章**: ステージ5 場面4・8
- **NovelAIタグ例**:
  ```
  knight order training ground, white sand arena, stone benches around,
  banners, stone pillars, central platform, training hall in background,
  bright sunlight, formal dueling atmosphere, no humans
  ```

### stage5/bg_royal_corridor_night.png（王宮回廊・夜）

- **場所**: 王宮の回廊、夜間潜入時
- **時間帯・光**: 深夜、月光が窓から差し込む、青系
- **主な配置**: 高い天井の石造り回廊、両脇にアーチ窓、壁に絵画、
  赤い絨毯、装飾的な燭台（消えている）、重厚な扉
- **雰囲気**: 荘厳、誰もいない静寂、緊張
- **使用章**: ステージ5 場面6
- **NovelAIタグ例**:
  ```
  royal palace corridor at night, tall arched windows, moonlight,
  red carpet, extinguished candelabras, portraits on walls,
  heavy ornate doors, silent grand atmosphere, no humans
  ```

### stage5/bg_feria_room.png（騎士団長私室）

- **場所**: フェリアの私室、騎士団本部最上階
- **時間帯・光**: 夜、ランプの暖色、落ち着いた
- **主な配置**: 重厚な扉、壁一面の書物、奥に鎧架（白銀の騎士鎧）、
  書き物机、奥の一枚扉の向こうにベッドルーム、剣架
- **雰囲気**: 騎士団長の威厳、整頓、しかし秘密がある
- **使用章**: ステージ5 場面6
- **NovelAIタグ例**:
  ```
  knight commander private chamber, heavy wooden door, bookshelves
  along walls, armor stand with silver knight armor, writing desk,
  sword rack, door to bedroom, warm lamp light, dignified orderly, no humans
  ```

### stage5/bg_outer_wall_night.png（外塀・夜）

- **場所**: 騎士団本部の外塀付近
- **時間帯・光**: 深夜、月光、影深め
- **主な配置**: 石の高い塀、植え込み、石畳、遠くに王宮の塔のシルエット
- **雰囲気**: 撤退、潜伏、緊張の緩和
- **使用章**: ステージ5 場面6.5
- **NovelAIタグ例**:
  ```
  castle outer wall at night, tall stone wall, hedges, cobblestone,
  distant palace tower silhouette, moonlight, deep shadows,
  tense post-infiltration atmosphere, no humans
  ```

### stage5/bg_back_street_evening.png（石畳・夕暮れ）

- **場所**: 騎士団本部の外、夕暮れの石畳通り
- **時間帯・光**: 夕方、オレンジの夕日、影長め
- **主な配置**: 石畳、街灯、建物の壁、遠くに塔のシルエット
- **雰囲気**: 日が落ちる静けさ、感慨
- **使用章**: ステージ5 場面9.5
- **NovelAIタグ例**:
  ```
  medieval cobblestone street at sunset, orange evening light,
  long shadows, street lamps, stone building walls, distant tower,
  quiet contemplative atmosphere, no humans
  ```

---

### stage6/bg_royal_hall.png（宮中・大広間）

- **場所**: 宮中の大広間、王女の玉座がある正式な場
- **時間帯・光**: 夜、シャンデリアの金色光、壮麗
- **主な配置**: シャンデリア、長いテーブル（白布、銀食器）、奥に王女の玉座、
  両脇に貴族席、赤い絨毯、大きな柱、装飾的な壁、天井画
- **雰囲気**: 荘厳、威圧、王族の格式
- **使用章**: ステージ6 全場面、ステージ7 場面1
- **NovelAIタグ例**:
  ```
  royal palace grand hall, crystal chandeliers, long banquet table,
  white tablecloth, silver tableware, throne at back, noble seats
  on sides, red carpet, grand columns, ornate walls, ceiling paintings,
  golden light, majestic formal atmosphere, no humans
  ```

### stage6/bg_side_room.png（控えの間）

- **場所**: 大広間の隅の小さな休憩室
- **時間帯・光**: 夜、ランプ、暖色
- **主な配置**: 小さなテーブル、椅子、水差しとグラス、柔らかいソファ、
  隅の燭台、小窓
- **雰囲気**: 短い休息、王女との対戦間の束の間
- **使用章**: ステージ6 場面4.5
- **NovelAIタグ例**:
  ```
  small palace side room, lamp light, small table with water pitcher,
  soft chair, candleholder, small window, warm intimate light,
  brief respite atmosphere, no humans
  ```

---

### stage7/bg_capital_sunset.png（王都・夕暮れ）

- **場所**: 王都の通り、王宮の塔を望む
- **時間帯・光**: 夕暮れ、オレンジ〜ピンクの空、夕日が塔を照らす
- **主な配置**: 石畳の通り、遠景に夕陽を受けた王宮の塔、
  建物の壁が暖色に染まる、遠くの民家の煙
- **雰囲気**: 感慨、新たな日常への歩み、希望と諦めの混じり
- **使用章**: ステージ7 場面2終わり
- **NovelAIタグ例**:
  ```
  royal capital at sunset, orange pink sky, distant palace tower
  silhouette glowing in evening light, cobblestone street, warm tones,
  buildings bathed in sunset, smoke from distant chimneys, 
  contemplative hopeful atmosphere, no humans
  ```

---

### subevent3/bg_blacksmith.png（鍛冶師の工房）

- **場所**: 鍛冶屋の工房内
- **時間帯・光**: 火床の赤橙光、他は薄暗い
- **主な配置**: 火床、金床、ハンマー各種、鉄製品の棚、煤けた天井、
  金属片の散らばる床、奥に水桶
- **雰囲気**: 煙、鉄の匂い、職人の空気
- **使用章**: サブイベ3 場面2
- **NovelAIタグ例**:
  ```
  blacksmith workshop interior, glowing forge, anvil, various hammers,
  shelves of metal goods, soot stained ceiling, scattered metal scraps,
  water barrel, red orange firelight, dim corners, artisan atmosphere,
  no humans
  ```

### subevent3/bg_noble_room.png（エドモンド邸・奥の間）

- **場所**: 貴族屋敷の奥にある来客の通らぬ一室
- **時間帯・光**: 室内灯、暖色、落ち着いた
- **主な配置**: 木製の壁、絨毯、中央に椅子、奥にベッド、
  家紋の絵画、本棚、小さな台（水晶球を置く場所）
- **雰囲気**: プライベート、秘密の相談所、上品だが物々しい
- **使用章**: サブイベ3 場面3〜7
- **NovelAIタグ例**:
  ```
  noble mansion private chamber, wooden walls, ornate rug, 
  central chair, bed in background, family crest painting,
  bookshelf, small pedestal, warm interior lamp light,
  private discreet atmosphere, no humans
  ```

---

## 背景の光と立ち絵の整合

各背景には「この背景前でキャラ立ち絵を描く場合の照明タグ」を推奨する。

| 背景 | 立ち絵側の照明タグ |
|---|---|
| bg01_university.png | `warm natural daylight, soft shadows` |
| bg02_room.png | `indoor fluorescent light, slight yellow tint` |
| bg03-1_lab.png | `cold white fluorescent light, sharp shadows` |
| bg05_prison_cell.png | `warm torchlight from side, strong shadows` |
| bg07_st1_001.png | `warm cozy interior light, soft ambient` |
| bg_moonleaf_dining.png | `dim candle light, dramatic shadows` |
| bg_cathedral_interior.png | `colorful stained glass light, divine beams` |
| bg_cathedral_night.png | `moonlight, cold blue, deep shadows` |
| bg_royal_hall.png | `golden chandelier light, warm but formal` |
| bg_capital_sunset.png | `orange sunset light, long shadows` |

---

## 注意事項

- 背景画像を生成する時は **`no humans` タグを必ず含める**（キャラは別素材）
- シーンの時間帯・色調はキャラ立ち絵の光源と一致させる
- 背景の書き込み密度はキャラの存在感を邪魔しない程度に（細部より空気感）
