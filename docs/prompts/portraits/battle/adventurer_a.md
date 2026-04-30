# 冒険者A（バトル立ち絵プロンプト集）

**キャラID**: `adventurer_a`
**Tier**: 2（固有名あり・ランダムバトル／チュートリアル相手）
**参照**: `style_guide.md`
**登場範囲**: ステージ1・ギルド入口でのチュートリアルバトル相手。

**ネガティブプロンプト**（共通）:
```
lowres, bad anatomy, bad hands, cropped, worst quality, low quality,
jpeg artifacts, signature, watermark, text, blurry, deformed,
multiple men, girl, woman, female, child, handsome, elegant, refined
```

---

## 基本タグ

```
1man, solo, adult male, mid twenties, western features,
(unkempt short brown hair, slight stubble beard),
brown dull eyes, tanned rough skin, bulky muscular build,
(worn leather vest over dirty tunic, rough cotton pants,
worn leather boots), rough adventurer attire,
thug-like brute aesthetic, gar-like presence
```

---

## outfit_3（ガラ悪装備・フル）

**衣装**: 汚れた革ベスト＋粗い綿チュニック＋綿ズボン＋革ブーツ。

### char09_st1_001（登場・立ちふさがる）

**シーン**: ギルド入口でサトシに絡む。

```
masterpiece, best quality, very aesthetic, absurdres,
1man, solo, adult male, mid twenties, unkempt brown hair,
brown eyes, tanned skin, bulky muscular, 
worn leather vest, dirty tunic, rough pants, leather boots,
full body, (imposing blocking stance, arms crossed over chest,
sneering intimidating grin, thug-like gar-gar laugh),
warm guild interior lighting,
simple background, plain white background
```

### char09_st1_002（「俺とじゃんけんして」・下品なガハハ）

```
masterpiece, best quality, very aesthetic, absurdres,
1man, solo, adult male, mid twenties, unkempt brown hair,
brown eyes, tanned skin, bulky muscular, leather vest, tunic,
upper body shot, (coarse laughing face, mouth wide open showing
yellow teeth, one finger pointed at opponent mockingly,
brutish "gahaha" laugh), warm guild lighting,
simple background, plain white background
```

### char09_st1_003（「今なんつった」・睨む）

```
masterpiece, best quality, very aesthetic, absurdres,
1man, solo, adult male, mid twenties, unkempt brown hair,
brown eyes bulging, tanned skin, bulky muscular, leather vest, tunic,
upper body shot, (angry glare, bulging eyes, teeth bared, 
leaning forward menacingly, rage rising), warm guild lighting,
simple background, plain white background
```

### char09_st1_004（「上等だ」・戦意満々）

```
masterpiece, best quality, very aesthetic, absurdres,
1man, solo, adult male, mid twenties, unkempt brown hair,
brown eyes fierce, tanned skin, bulky muscular, leather vest, tunic,
upper body shot, (teeth bared in combative grin, cracking knuckles,
battle-ready pose, muscle-head confidence),
warm guild lighting, simple background, plain white background
```

### char09_st1_battle_001（バトル構え）

```
masterpiece, best quality, very aesthetic, absurdres,
1man, solo, adult male, mid twenties, unkempt brown hair,
brown eyes, tanned skin, bulky muscular, leather vest, tunic,
upper body battle stance, (ready to play janken, one fist up,
smug dominant expression, muscle-head confidence),
warm guild lighting, simple background, plain white background
```

### char09_st1_005（敗北・「俺の手が読まれてる」）

```
masterpiece, best quality, very aesthetic, absurdres,
1man, solo, adult male, mid twenties, unkempt brown hair disheveled,
brown eyes wide in disbelief, tanned skin, bulky muscular,
(leather vest unbuttoned from outfit loss, dirty tunic loose),
upper body shot facing right (flipped), (stunned defeated expression,
sweat pouring, mouth agape in shock, clutching head in disbelief),
warm guild lighting, simple background, plain white background
```

---

## outfit_2（1枚脱いだ・パンツ・・とか？）

**備考**: 冒険者Aは男性キャラのため、outfit_2/1 の描写はシナリオ上なし。
ステージ1 の冒険者A戦は HP=1 の1本勝負で、装備1段階のみ。
敗北で恥をかく演出はシナリオベースで「衣装が乱れる」程度。

実装上は `char09_st1_battle_001`（戦闘立ち絵）と `char09_st1_005`（敗北）のみ使用。

---

## 補足

男性モブキャラのため、outfit_2 以下の描画は不要。
`random_encounters.md` に登録される汎用ランダム敵として、ベース画像を使い回す可能性あり。
