# Character Sheet（主要キャラクター設定シート）

Tier 1 全キャラの**基本外観と共通設定**の索引。
各個別プロンプト（`portraits/main/*.md`, `portraits/battle/*.md`）は、
ここのキャラ設定を前提として個別シーンを記述する。

フォーマット:
- **呼称**: 作中呼称（地の文、他キャラから）
- **年齢感**: おおよそ
- **体型**: 身長感、肉付き
- **髪**: 色、長さ、質感、まとめ方
- **目**: 色、形状
- **肌**: 色、質感
- **基本衣装**: 章ごとに差分あり
- **敗北時（outfit_1）**: 素っ裸＋局部モザイク処理（`style_guide.md` 参照／共通ルール）
- **アクセサリ**: 常時帯同
- **雰囲気**: 一言で
- **NovelAIタグ例**: Danbooruタグのサンプル

**注記**: 以前は「下着」の色・意匠を指定していたが、現在は敗北時=素っ裸＋モザイクの
共通ルールに統一。キャラごとの下着デザインは不要（各ファイルで「下着」項目が残って
いる場合は無視、または将来の中間段階outfit_2 時の「残存する布片」の色味参考として扱う）。

---

## satoshi（サトシ）

- **呼称**: サトシ／「変態」（マチルダ命名）／「冒険者サトシ」／「要監視対象A」
- **年齢感**: 20代前半、大学3年生
- **体型**: 日本人男性、中肉、175cm程度、痩せ型寄り
- **髪**: 黒〜焦茶、癖毛、ぼさぼさのショート、前髪やや長め
- **目**: 黒〜焦茶、やや垂れ目、眉は薄め
- **肌**: やや白め、健康的な色
- **基本衣装**:
  - **プロローグ・大学編**: パーカー or シャツ＋ジーンズ（現代日本の大学生スタイル）
  - **加速器施設**: 白衣＋防護メガネ（pg_017 のみ）
  - **プロローグ・牢屋以降**: 麻の白シャツ＋麻のズボン＋粗い革靴（異世界転生後の支給品）
  - **ギルド加入後**: 麻シャツの上に革の胸当て＋ベルト、革のポーチ（冒険者装備）
  - **宮中晩餐会**: 借り物の礼装（白シャツ＋ジャケット＋ボウタイ、やや合わないサイズ感）
  - **エンディング**: 冒険者装備のまま、少し疲労感
  <!-- - **下着**: 男性キャラのため outfit_2/1 は該当しない（バトルで脱衣される側ではない）（廃止・モザイク処理に統一） -->
- **アクセサリ**: 
  - 場面9以降: 冒険者証（首から下げる or ポーチに入れる）
  - Stage1以降: 右肩付近にピー助（透明化中は見えない）
- **雰囲気**: 気弱な小心者、ムッツリスケベ、数学オタクの大学生
- **NovelAIタグ例**:
  ```
  1boy, young adult, japanese, black hair, messy short hair,
  dark brown eyes, slim build, soft facial features,
  nervous expression
  ```

---

## pisuke（ピー助）

- **呼称**: ピー助／「聖霊様」（自称）／「精霊」
- **正体**: 聖霊（自称）、見た目はヨウム
- **登場形態**:
  - **Stage1 前半のみ**: ヨウム姿で画面に登場（姿あり）
  - **Stage1 後半以降**: 透明化、**姿は描かれない**（声のみ）
- **ヨウム姿の外観**（stage1/char08_st1_XXX のみ）:
  - 中型のオウム／ヨウム
  - 灰色の羽毛、赤い尾羽
  - 黒い嘴、黄色い目
  - ちょっと悪そうな目つき（人間の悪知恵が宿っている感）
- **雰囲気**: 口が悪い、煽り耐性の塊、人の声色を真似る
- **NovelAIタグ例**（姿ある時のみ）:
  ```
  african grey parrot, grey feathers, red tail feathers, 
  black beak, yellow eyes, mischievous expression, no humans
  ```

---

## minori（みのり）

- **呼称**: みのり（サトシ幼馴染／プロローグのみ）
- **年齢感**: 20代前半、有名私大の女子大生
- **体型**: 日本人女性、中肉、162cm程度、スレンダー
- **髪**: 黒〜濃い茶、セミロング、さらさらのストレート
- **目**: 黒〜焦茶、やや吊り目、意志の強い目
- **肌**: 白め、透明感
- **基本衣装**:
  - **プロローグ場面1・2（大学キャンパス）**: きちんとした女子大生スタイル。
    ブラウス＋カーディガン＋膝丈スカート、パンプス
  - **プロローグ場面3（スマホ画面越し）**: 同上、やや近距離の顔
  <!-- - **下着**: 出番なし（プロローグのみ・脱衣シーンなし）（廃止・モザイク処理に統一） -->
- **アクセサリ**: 小ぶりなピアス、学生鞄、スマホ
- **雰囲気**: 典型的なツンデレ、呆れ顔の基本。政治家志望で頭が切れる
- **NovelAIタグ例**:
  ```
  1girl, young adult, japanese, black hair, semi-long straight hair,
  dark brown eyes, slender, blouse, cardigan, knee-length skirt,
  slightly annoyed expression, tsundere
  ```

---

## matilda（マチルダ）

- **呼称**: マチルダ／牢番／「マチルダさん」（サトシ呼び）
- **年齢感**: 20代後半〜30代前半、姉御系
- **体型**: 西洋系、豊満、170cm程度、メリハリのあるボディ
- **髪**: 濃い赤〜ワインレッド、ロング、ウェーブがかった髪、ざっくり後ろでまとめる
- **目**: 緑〜ヘーゼル、鋭い切れ長、きつめ
- **肌**: 健康的な小麦色、野営・勤務の日焼け感
- **基本衣装**:
  - **outfit_3（フル装備）**: 牢番の制服。黒〜濃紺の革のコルセット＋白シャツ＋
    黒タイトスカート、黒ブーツ、腰にベルト・鍵束・小さな注射器
  - **outfit_2**: （半裸・中間段階）衣装の一部を失い上半身露出、下半身は破れた布片で隠れる。
    下着描写なし。style_guide.md 参照
  - **outfit_1**: （素っ裸＋モザイク）完全に裸、局部モザイク処理。乳首は露出OK。
    style_guide.md 参照。敗北ポーズはキャラ性格に応じる
  <!-- - **下着**: 黒〜深赤のレース、シック、大人っぽい（廃止・モザイク処理に統一） -->
- **アクセサリ**: 鍵束、ベルトポーチ、注射器（プロローグ特例チップ用）
- **雰囲気**: 姉御、気だるい迫力、獲物を見る目、敗北時は屈辱
- **NovelAIタグ例**:
  ```
  1girl, mature female, late twenties, western features,
  dark red long wavy hair, tied ponytail, hazel green eyes,
  tan skin, voluptuous body, black leather corset, white shirt,
  black skirt, black boots, belt with keys, confident smirk
  ```

---

## receptionist（受付嬢リーゼ）

- **呼称**: 受付嬢／リーゼ（本名、subevent4で判明）
- **年齢感**: 20代半ば
- **体型**: 西洋系、スレンダー、165cm程度、均整の取れたモデル体型
- **髪**: プラチナブロンド〜明るい金髪、ロング、きっちりハーフアップ or ポニーテール
- **目**: 氷青（アイスブルー）、切れ長、感情を出さない
- **肌**: 雪白、透明感、冷たい印象
- **基本衣装**:
  - **outfit_3（フル装備）**: ギルド制服。紺のベスト＋白ブラウス＋タイトな膝丈スカート、
    白タイ、白手袋、革の長靴、胸元にギルドのエンブレム
  - **outfit_2**: （半裸・中間段階）衣装の一部を失い上半身露出、下半身は破れた布片で隠れる。
    下着描写なし。style_guide.md 参照
  - **outfit_1**: （素っ裸＋モザイク）完全に裸、局部モザイク処理。乳首は露出OK。
    style_guide.md 参照。敗北ポーズはキャラ性格に応じる
  <!-- - **下着**: 白〜パール色のシルク、上品、機能的（廃止・モザイク処理に統一） -->
- **アクセサリ**: 羽ペン、帳面、眼鏡（時々）
- **雰囲気**: 冷徹、無表情、事務的、しかし内に元・王宮上位戦闘要員の矜持
- **NovelAIタグ例**:
  ```
  1girl, young adult, western features, platinum blonde long hair,
  half-up hairstyle, ice blue eyes, sharp eyes, pale skin,
  slender tall body, guild uniform, navy vest, white blouse,
  tight skirt, white gloves, expressionless face
  ```

---

## city_guard（番兵）

- **呼称**: 番兵／「あの番兵さん」／「露出狂の変態の連行役」
- **年齢感**: 30代半ば〜40代前半
- **体型**: 西洋系、がっしりした兵士体型、180cm程度、肩幅広め
- **髪**: 黒〜焦茶、短髪、兵士刈り
- **目**: 茶〜灰、鋭い、疲労の影
- **肌**: 日焼け、無精髭の剃り跡
- **基本衣装**: 王都の兵士制服。
  - 鉄のヘルメット（場面により脱ぐ）、革の胸当て、赤いマント、青の制服、
    腰に剣、手に槍、スカートアーマー
  <!-- - **下着**: 男性キャラのため outfit_2/1 は該当しない（戦闘対象でない）（廃止・モザイク処理に統一） -->
- **アクセサリ**: 王都の紋章（胸、マント）、呼子笛、巡回手帳
- **雰囲気**: 疲れきった中堅兵士、嫌味が冴える、呆れ顔が増えていく
- **NovelAIタグ例**:
  ```
  1man, mid thirties, western features, broad shoulders, 
  short black hair, military cut, brown eyes, tanned skin,
  city guard uniform, iron helmet, leather chest plate,
  red cape, spear, sword at waist, tired expression
  ```

---

## princess（王女アレクシア）

- **呼称**: 王女アレクシア／殿下／アレクシア様
- **年齢感**: 20代前半、聖君候補
- **体型**: 西洋系、スレンダー、167cm程度、高貴な佇まい
- **髪**: 金髪（淡いプラチナゴールド）、ロング、緩やかなウェーブ、
  前髪は分けてティアラを覗かせる
- **目**: 碧眼（明るいアイスブルー）、大きめ、涼やか
- **肌**: 雪白、磁器のような質感、手入れの行き届いた王族肌
- **基本衣装**:
  - **outfit_3（晩餐会ドレス）**: 絹のロイヤルブルーのドレス、ふんわりとしたAライン、
    胸元にレース装飾、金糸刺繍、小さなティアラ、白絹の肘上手袋、ネックレス
  - **outfit_2**: （半裸・中間段階）衣装の一部を失い上半身露出、下半身は破れた布片で隠れる。
    下着描写なし。style_guide.md 参照
  - **outfit_1**: （素っ裸＋モザイク）完全に裸、局部モザイク処理。乳首は露出OK。
    style_guide.md 参照。敗北ポーズはキャラ性格に応じる
  <!-- - **下着**: 純白シルク＋レース＋金糸刺繍（最高級）（廃止・モザイク処理に統一） -->
- **アクセサリ**: ティアラ、扇（晩餐会の威厳演出）、金のネックレス、ピアス
- **雰囲気**: 箱入り、聖君候補の穏やかな威厳、純真、動揺すると弱い
- **NovelAIタグ例**:
  ```
  1girl, young adult, royalty, pale platinum blonde long wavy hair,
  tiara, ice blue eyes, porcelain skin, slender elegant body,
  royal blue silk dress, lace decoration, gold embroidery,
  white silk gloves, graceful posture, gentle smile
  ```

---

## knight_commander（騎士団長フェリア）

- **呼称**: 騎士団長フェリア／フェリア殿下／ヴェーレンベルク家当主候補
- **年齢感**: 20代後半、王女の幼なじみ
- **体型**: 西洋系、鍛え抜かれたアスリート体型、172cm程度、筋肉質だが女性らしさあり
- **髪**: 銀髪、長めのポニーテール、きっちり結ぶ
- **目**: 紫〜青紫（アメジスト）、鋭い、凛々しい
- **肌**: 白め、健康的、わずかに日焼け
- **基本衣装**:
  - **outfit_3（フル装備）**: 騎士団長の白銀の鎧、金装飾、赤の騎士マント、
    胸当て、肩当て、籠手、長剣、腰にプラチナ三種カードの収納ポーチ
  - **outfit_2**: （半裸・中間段階）衣装の一部を失い上半身露出、下半身は破れた布片で隠れる。
    下着描写なし。style_guide.md 参照
  - **outfit_1**: （素っ裸＋モザイク）完全に裸、局部モザイク処理。乳首は露出OK。
    style_guide.md 参照。敗北ポーズはキャラ性格に応じる
  <!-- - **下着**: 黒〜深紺、スポーティ、機能的（廃止・モザイク処理に統一） -->
- **アクセサリ**: 騎士団長の紋章、長剣、プラチナカード三種（outfit_3のみ）
- **雰囲気**: 冷静、凛々しい、王家への絶対の忠誠、動揺しても崩れにくい
- **NovelAIタグ例**:
  ```
  1girl, late twenties, western features, silver long ponytail,
  amethyst purple eyes, sharp eyes, athletic toned body,
  knight commander armor, white silver plate armor, gold decorations,
  red knight cape, pauldrons, gauntlets, longsword, stern expression
  ```

---

## mage_commander（魔法師団長セレス）

- **呼称**: 魔法師団長セレス／セレス殿／ソルヴェイグ卿
- **フルネーム**: セレス・ソルヴェイグ
- **年齢感**: 30代前半、国の最終兵器級魔術師
- **体型**: 西洋系、スレンダー、170cm程度、知的美人
- **髪**: 白銀（プラチナ）、超ロング、ストレート、サラサラ
- **目**: 薄紫〜ライラック、理知的で冷たい、眼鏡をかける時もある
- **肌**: 雪白、研究室暮らしで日焼け皆無
- **基本衣装**:
  - **outfit_3（参謀ローブ）**: 魔法師団の深紺×銀のローブ、銀の刺繍、魔導杖、
    首元にタイ、ローブ下にロングスカート、足元は革のロングブーツ、
    魔導記録具（腰のベルト）、片眼鏡
  - **outfit_2**: （半裸・中間段階）衣装の一部を失い上半身露出、下半身は破れた布片で隠れる。
    下着描写なし。style_guide.md 参照
  - **outfit_1**: （素っ裸＋モザイク）完全に裸、局部モザイク処理。乳首は露出OK。
    style_guide.md 参照。敗北ポーズはキャラ性格に応じる
  <!-- - **下着**: 黒のレース＋拘束具風ストラップ装飾（性癖が滲む）（廃止・モザイク処理に統一） -->
- **アクセサリ**: 魔導杖、片眼鏡、魔導記録具、魔法師団の紋章
- **雰囲気**: 冷徹、理知的、独身貴族、裏は倒錯的被虐嗜好
- **NovelAIタグ例**:
  ```
  1girl, early thirties, western features, platinum silver very long
  straight hair, lilac purple eyes, cold intellectual gaze,
  pale skin, slender tall body, deep navy mage commander robe,
  silver embroidery, monocle, magic staff, long leather boots
  ```

---

## high_priestess（大司祭マグダレナ）

- **呼称**: 大司祭マグダレナ／シスター姉／「祈の腹心」
- **年齢感**: 20代後半、シスター長の姉
- **体型**: 西洋系、豊満、168cm程度、聖母的な包容力のある体型
- **髪**: 金髪（深めのゴールド）、ロング、ヴェールの下にまとめる、
  前髪は分けて額を出す
- **目**: 深い青緑（エメラルド寄り）、慈悲深く見せて内側は冷たい
- **肌**: 透き通るような白、聖女オーラ
- **基本衣装**:
  - **outfit_3（法衣）**: 白の聖職者ローブ、金縁、胸元に大きな十字架、
    頭にはヴェール、腰に組紐、両手首にロザリオ
  - **outfit_2**: （半裸・中間段階）衣装の一部を失い上半身露出、下半身は破れた布片で隠れる。
    下着描写なし。style_guide.md 参照
  - **outfit_1**: （素っ裸＋モザイク）完全に裸、局部モザイク処理。乳首は露出OK。
    style_guide.md 参照。敗北ポーズはキャラ性格に応じる
  <!-- - **下着**: 純白のレース＋聖なるモチーフ刺繍（十字架の細部など）（廃止・モザイク処理に統一） -->
- **アクセサリ**: 大きな十字架（胸）、小さなロザリオ（手首）、ヴェール
- **雰囲気**: 表は慈悲深い聖女、裏は筋肉BL愛好家、嫌がらせの手腕は冷徹
- **NovelAIタグ例**:
  ```
  1girl, late twenties, western features, deep gold long hair,
  white veil, emerald green eyes, gentle motherly gaze,
  pale translucent skin, voluptuous body, white high priestess robe,
  gold trim, large golden cross, rosary on wrist, serene smile
  ```

---

## assassin（アサシンレイラ）

- **呼称**: レイラ／暗部調査部門のレイラ／「影の腹心」
- **年齢感**: 20代半ば
- **体型**: 西洋系、しなやかな戦闘体型、165cm程度、妖艶だが機能美
- **髪**: 栗色（チェスナット）、ロング、ゆるくまとめる（夜会）／ポニーテール（訓練時）
- **目**: 薄い緑〜ヘーゼル、長い睫毛、伏し目気味
- **肌**: やや褐色、健康的、しなやか
- **基本衣装**:
  - **outfit_3（夜会ドレス）**: 暗い赤〜ワインレッドの露出多めの夜会ドレス、
    肩出し、深いスリット、首元にチョーカー、ヒール、手首に細い金のブレス
  - **outfit_2**: （半裸・中間段階）衣装の一部を失い上半身露出、下半身は破れた布片で隠れる。
    下着描写なし。style_guide.md 参照
  - **outfit_1**: （素っ裸＋モザイク）完全に裸、局部モザイク処理。乳首は露出OK。
    style_guide.md 参照。敗北ポーズはキャラ性格に応じる
  <!-- - **下着**: 深赤〜黒のレース（妖艶デザイン）＋初々しさ（廃止・モザイク処理に統一） -->
- **アクセサリ**: チョーカー、隠し武器（夜会ではドレスに隠す）、金のブレス
- **雰囲気**: 表は妖艶な完璧な色仕掛け、裏は超純情・実戦ゼロの初心
- **NovelAIタグ例**:
  ```
  1girl, mid twenties, western features, chestnut long hair,
  loosely tied hair, hazel green eyes, long eyelashes,
  tan skin, lithe body, dark red evening dress, bare shoulders,
  deep slit, black choker, seductive pose, subtle blush
  ```

---

## thief_chief（盗賊団首領ベルカ）

- **呼称**: ベルカ／ベルカ・マニエラ／シルキーファングの首領
- **年齢感**: 10代後半〜20代前半（小柄だが元A級冒険者）
- **体型**: 西洋系、小柄、150cm程度、華奢だが引き締まった
- **髪**: プラチナブロンド〜銀髪、ショートカット、ツンツン跳ねる
- **目**: 緑、細めの吊り目、いたずらっぽい
- **肌**: 白め、野営生活で若干日焼け
- **基本衣装**:
  - **outfit_3（盗賊装備）**: ダボっとした黒の盗賊コート、中にグレーのタンクトップ、
    太ももまでのボリュームあるブーツ、黒い革の手袋、スカーフを首に、
    腰にナイフ数本、**ブーツは床を鳴らす**
  - **outfit_2**: （半裸・中間段階）衣装の一部を失い上半身露出、下半身は破れた布片で隠れる。
    下着描写なし。style_guide.md 参照
  - **outfit_1**: （素っ裸＋モザイク）完全に裸、局部モザイク処理。乳首は露出OK。
    style_guide.md 参照。敗北ポーズはキャラ性格に応じる
  <!-- - **下着**: 黒のスポーツブラ＋黒コットンのパンティ（ボーイッシュ）（廃止・モザイク処理に統一） -->
- **アクセサリ**: スカーフ、ナイフ、鍵開けツール、シルキーファングの紋章
- **雰囲気**: ボクっ娘、小柄な元A級冒険者、パンツコレクターの美学、軽妙
- **NovelAIタグ例**:
  ```
  1girl, late teens, western features, petite, short platinum blonde hair,
  spiky short hair, green sharp eyes, fair skin, small build,
  baggy black thief coat, grey tank top, long leather boots,
  black gloves, scarf, playful smirk, tomboy
  ```

---

## young_sister（若いシスター／シスターA）

- **呼称**: シスターA／「若いシスター」（サブイベ2の内部告発者）
- **年齢感**: 20歳前後、シスター見習い
- **体型**: 西洋系、小柄、158cm程度、華奢
- **髪**: 栗色（ライトチェスナット）、セミロング、**白いヴェールの下にまとめる**
- **目**: 薄い緑、大きめ、怯えた表情が多い
- **肌**: 白、透明感、修道院育ちの清廉
- **基本衣装**: シスターの修道服。
  - 白のワンピース＋黒のスカプラリオ、白いヴェール、木のロザリオ、
    腰に組紐、革のサンダル
  <!-- - **下着**: 出番なし（バトル対象ではない、脱衣シーンなし）（廃止・モザイク処理に統一） -->
- **アクセサリ**: 木のロザリオ、小さな聖書
- **雰囲気**: 怯え、内部告発の勇気を振り絞った、しかしサブイベ2後は新シスター長
- **NovelAIタグ例**:
  ```
  1girl, young adult, western features, light chestnut semi-long hair,
  white veil, pale green large eyes, pale skin, petite slender,
  nun habit, white dress, black scapular, wooden rosary,
  timid expression
  ```

---

## noble_lady（エドモンド家令嬢フィオナ）

- **呼称**: フィオナ／フィオナ様／エドモンド家ご令嬢
- **年齢感**: 10代後半、貴族の若い令嬢
- **体型**: 西洋系、華奢、160cm程度
- **髪**: 栗色、ロング、ゆるく波打つ、普段は凝ったハーフアップ、
  **呪いの鎧内では乱れて汗ばむ**
- **目**: 紫〜青紫（アメジスト）、大きめ、極度のシャイで視線を合わせない
- **肌**: 雪白、絹のような質感、貴族の箱入り
- **基本衣装**:
  - **場面1〜6（呪われた鎧装着中）**: 漆黒の甲冑「ヴァニティ・チェイン」、
    全身を覆うヘルム付き、肩から脛まで黒鉄、胸と腰に鎖装飾、
    動くたびに金属音、表情はヘルムの隙間のみ
  - **場面7〜8（鎧崩壊後）**: 一か月鎧下で擦れ続けたボロボロの肌着、
    汗ばんだ肌、乱れた栗色の髪、羞恥で真っ赤、**上半身カットで慎ましく**
  <!-- - **下着**: 場面7で見える範囲は**色褪せたベージュ／くたびれた綿**（廃止・モザイク処理に統一） -->
  （一ヶ月洗えず状態、鎧崩壊後の羞恥描写）
- **アクセサリ**: （鎧装着時）なし。（鎧崩壊後）脱ぎ捨てたヘルムの残骸
- **雰囲気**: 極度のシャイ、貴族のプライド、羞恥が命取り、ヘルムの内側で震える
- **NovelAIタグ例**（鎧姿）:
  ```
  1girl, late teens, western features, cursed black armor full body,
  black iron helmet, chain decorations, intimidating armor silhouette,
  dim light from helmet slit
  ```
- **NovelAIタグ例**（鎧崩壊後）:
  ```
  1girl, late teens, western features, chestnut long wavy hair,
  messy disheveled hair, amethyst eyes, tearful, pale skin,
  tattered worn camisole, ragged underwear, sweaty skin,
  deep blush of shame, small slender body
  ```

---

## butler（エドモンド家執事セバス）

- **呼称**: セバス／執事／「老執事」
- **年齢感**: 60代〜70代、初老
- **体型**: 西洋系、痩身、175cm程度、背筋は伸びる
- **髪**: 白髪、短く整えた白、きちんと撫でつける
- **目**: 灰〜薄青、冷静だが奥に情熱、眉は白く濃い
- **肌**: 年齢相応のシワ、手入れされた白肌
- **基本衣装**: 古風な執事服。
  - 黒の燕尾服、白シャツ、白手袋、黒ベスト、懐中時計の鎖、
    銀縁眼鏡（時々）、革靴、胸元にエドモンド家紋のピンバッジ
  <!-- - **下着**: 男性キャラのため outfit_2/1 は該当しない（廃止・モザイク処理に統一） -->
- **アクセサリ**: 懐中時計、銀縁眼鏡、白手袋、家紋ピン
- **雰囲気**: 古風、忠実、威厳、お嬢様への絶対の愛情、決定打で絶叫
- **NovelAIタグ例**:
  ```
  1oldman, sixties, western features, white short hair, slicked back,
  grey eyes, wrinkled dignified face, tall slim frame,
  black tailcoat butler uniform, white gloves, pocket watch,
  silver spectacles, dignified posture
  ```

---

## blacksmith（鍛冶師ゴルン）

- **呼称**: ゴルン／鍛冶師ゴルン／「老鍛冶」
- **年齢感**: 60代後半、老齢の職人
- **体型**: 西洋系、がっしり、170cm程度、元は筋骨隆々だが老いで痩せ気味
- **髪**: 白髪、もじゃもじゃの白髭、髪は短く刈り込む
- **目**: 琥珀〜黄、細く光る、炎に照らされた経験
- **肌**: 日焼けと煤で褐色、手は荒れてごつごつ
- **基本衣装**: 鍛冶屋の作業着。
  - 汚れた白シャツ（袖まくり）、茶色の革の前掛け、黒のズボン、
    革のブーツ、右手に鍛冶ハンマー、腰にタオル
  <!-- - **下着**: 男性キャラのため outfit_2/1 は該当しない（廃止・モザイク処理に統一） -->
- **アクセサリ**: 鍛冶ハンマー、煤けたバンダナ、真言の水晶球（subevent3）
- **雰囲気**: 老獪、過去のトラウマ（女房に工房全焼）、遠い目、警句
- **NovelAIタグ例**:
  ```
  1oldman, late sixties, western features, white beard, bushy beard,
  short grey hair, amber eyes, tanned weathered skin, muscular 
  but aging frame, dirty white shirt, brown leather apron,
  blacksmith hammer, soot stained bandana
  ```

---

## guild_staff（ギルド職員B）

- **呼称**: ギルド職員B／B嬢／「華奢な美人タイプ」
- **年齢感**: 20代前半、受付補佐
- **体型**: 西洋系、華奢、158cm程度、小柄で細身
- **髪**: 明るい茶〜亜麻色、ミディアム、きちんとハーフアップ、小さなリボン
- **目**: 青〜ペールブルー、大きめ、涙目になりやすい
- **肌**: 白、透明感、事務職の色白
- **基本衣装**: ギルド職員の補佐服（受付嬢と類似だが簡素）。
  - 紺のベスト＋白ブラウス＋膝丈スカート、白手袋、白タイツ、
  - 左手の薬指に**祖母の形見の銀の指輪**（stage2 の要素／盗難事件で一時紛失）
  <!-- - **下着**: 出番なし（バトル対象ではない）（廃止・モザイク処理に統一） -->
- **アクセサリ**: 銀の指輪（祖母の形見）、書類、羽ペン、胸元のギルドエンブレム
- **雰囲気**: 華奢で儚げ、涙目になりやすい、しかしstage2終盤から棘のある言葉
- **NovelAIタグ例**:
  ```
  1girl, young adult, western features, light brown medium hair,
  half-up hairstyle, small ribbon, pale blue large eyes, tearful,
  pale skin, petite slender, guild assistant uniform, navy vest,
  white blouse, silver ring on ring finger
  ```
