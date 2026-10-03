import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('guild completes Jin, Marco, and Gald, resumes Gald, and persists the item rewards', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-subevent1-jin-'))
  const defeatData = await mkdtemp(join(tmpdir(), 'janken-subevent1-belka-defeat-'))
  const target = join(data, 'janken-save.json')
  const cards = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
  const original = { save_version: 1, player: { inventory: cards, deck: cards, money: 30 },
    progress: { checkpoint_id: 'guild.home', guild_return_checkpoint: 'matilda.normal.end',
      flags: ['matilda.tutorial.completed', 'matilda.normal.started'],
      tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
      fixed_battle: { battle_id: 'battle.matilda.normal', player_deck: cards,
        rounds: [6, 7, 8].map((player_index, opponent_index) => ({ player_index, opponent_index })),
        acknowledged: 3, settled: true, balance_before: 20, gold_delta: 10 },
      jin_draft: [cards[0], cards[3], cards[6]] } }
  let app, defeatApp
  try {
    await writeFile(target, JSON.stringify(original))
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    let page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    await page.getByRole('button', { name: 'サブイベント1を開始（解放条件なし）', exact: true }).click()
    await page.getByRole('heading', { name: 'サブイベント1：盗賊団討伐', exact: true }).waitFor()
    await page.getByText('へっ、来たな冒険者。アジトの場所を嗅ぎつけるとは、やるじゃねえか。だが、ここから先は通さねえぜ。', { exact: true }).waitFor()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('heading', { name: '盗賊ジン戦', exact: true }).waitFor()
    assert.equal((await readFile(target, 'utf8')).includes('subevent1.jin.await'), true)
    await page.evaluate(() => { Math.random = () => 0.5 })
    await page.getByRole('button', { name: '選択 グー N', exact: true }).click()
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByTestId('jin-result').waitFor()
    await page.getByRole('button', { name: '結果を確定', exact: true }).click()
    await page.getByTestId('jin-settled').waitFor()
    assert.equal((await readFile(target, 'utf8')).includes('battle.subevent1.jin'), true)
    await page.getByRole('button', { name: '物語を続ける', exact: true }).click()
    for (let index = 0; index < 5; index++) await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('heading', { name: '盗賊マルコ戦', exact: true }).waitFor()
    assert.equal((await readFile(target, 'utf8')).includes('subevent1.marco.await'), true)
    await app.close()
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('heading', { name: '盗賊マルコ戦', exact: true }).waitFor()
    await page.evaluate(() => { Math.random = () => 0.5 })
    await page.getByRole('button', { name: '選択 グー N', exact: true }).click()
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByTestId('jin-result').waitFor()
    await page.getByRole('button', { name: '結果を確定', exact: true }).click()
    await page.getByTestId('jin-settled').waitFor()
    const savedMarco = JSON.parse(await readFile(target, 'utf8'))
    assert.equal(savedMarco.progress.subevent1_marco_battle.battle_id, 'battle.subevent1.marco')
    assert.equal(savedMarco.progress.subevent1_marco_battle.settled, true)
    await page.getByRole('button', { name: '物語を続ける', exact: true }).click()
    for (let index = 0; index < 6; index++) await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('heading', { name: '盗賊ガルド戦', exact: true }).waitFor()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).progress.checkpoint_id, 'subevent1.gald.await')
    await app.close()
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('heading', { name: '盗賊ガルド戦', exact: true }).waitFor()
    await page.evaluate(() => { Math.random = () => 0.2 })
    await page.getByRole('button', { name: '選択 パー N', exact: true }).click()
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByRole('button', { name: '結果を確定', exact: true }).click()
    await page.getByTestId('jin-settled').waitFor()
    const savedGald = JSON.parse(await readFile(target, 'utf8'))
    assert.deepEqual(savedGald.player.items, ['scissors_attract_white', 'paper_seal_white'])
    await page.getByRole('button', { name: '物語を続ける', exact: true }).click()
    for (let index = 0; index < 4; index++) await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('heading', { name: 'サブイベント1：ベルカ戦', exact: true }).waitFor()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).progress.checkpoint_id, 'subevent1.belka.await')
    await app.close()
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('heading', { name: 'サブイベント1：ベルカ戦', exact: true }).waitFor()
    await page.evaluate(() => { Math.random = () => 0.9 })
    const belkaStart = JSON.parse(await readFile(target, 'utf8'))
    await writeFile(join(defeatData, 'janken-save.json'), JSON.stringify(belkaStart))
    defeatApp = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${defeatData}`] })
    const defeatPage = await defeatApp.firstWindow()
    await defeatPage.getByRole('button', { name: 'つづきから', exact: true }).click()
    await defeatPage.getByRole('heading', { name: 'サブイベント1：ベルカ戦', exact: true }).waitFor()
    await defeatPage.evaluate(() => { Math.random = () => 0.99 })
    for (const cardIndex of [0, 1, 2]) {
      await defeatPage.locator('[data-testid="subevent1-belka-deck"] button').nth(cardIndex).click()
      await defeatPage.getByRole('button', { name: '勝負！', exact: true }).click()
      await defeatPage.getByTestId('subevent1-belka-result').waitFor()
      if (cardIndex !== 2) await defeatPage.getByRole('button', { name: '次の勝負へ', exact: true }).click()
    }
    await defeatPage.getByRole('button', { name: '結果を確定', exact: true }).click()
    await defeatPage.getByTestId('subevent1-belka-settled').waitFor()
    await defeatPage.getByText('サトシはベルカに敗北した。盗賊団のアジトから撤退するしかない...', { exact: true }).waitFor()
    const defeatedSave = JSON.parse(await readFile(join(defeatData, 'janken-save.json'), 'utf8'))
    assert.equal(defeatedSave.progress.subevent1_belka_battle.settled, true)
    assert.equal(defeatedSave.player.inventory.length, belkaStart.player.inventory.length - 3)
    assert.deepEqual(defeatedSave.player.items, belkaStart.player.items)
    await defeatPage.getByRole('button', { name: 'ギルドホームに戻る', exact: true }).click()
    await defeatPage.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    await defeatApp.close()
    defeatApp = undefined
    for (const cardIndex of [3, 4, 5]) {
      await page.locator('[data-testid="subevent1-belka-deck"] button').nth(cardIndex).click()
      await page.getByRole('button', { name: '勝負！', exact: true }).click()
      await page.getByTestId('subevent1-belka-result').waitFor()
      if (cardIndex !== 5) await page.getByRole('button', { name: '次の勝負へ', exact: true }).click()
    }
    await page.getByRole('button', { name: '物語を続ける', exact: true }).click()
    await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === 'subevent1.belka.after',
      { timeout: 3000 }).catch(async () => { throw new Error(`Belka continuation failed: ${await page.locator('body').innerText()}`) })
    let savedBelka = JSON.parse(await readFile(target, 'utf8'))
    assert.equal(savedBelka.progress.subevent1_belka_battle.battle_id, 'battle.subevent1.belka')
    assert.equal(savedBelka.progress.subevent1_belka_battle.settled, false)
    assert.equal(savedBelka.player.money, belkaStart.player.money)
    assert.deepEqual(savedBelka.player.items, belkaStart.player.items)
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByText('しばらくして、通報を受けた番兵が駆けつけてきた。', { exact: true }).waitFor()
    await app.close()
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('heading', { name: 'サブイベント1：盗賊団討伐', exact: true }).waitFor()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).progress.checkpoint_id, 'subevent1.belka.guard-arrives')
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByText('...お前、あの時の露出狂の変態じゃねえか！', { exact: true }).waitFor()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.evaluate(() => { Math.random = () => 0.9 })
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByText('サトシ様。盗賊団討伐の報酬です。金貨58枚。...お見事でした。', { exact: true }).waitFor()
    await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === 'subevent1.belka.report',
      { timeout: 3000 }).catch(async () => { throw new Error(`Reception report did not load: ${await page.locator('body').innerText()}`) })
    savedBelka = JSON.parse(await readFile(target, 'utf8'))
    assert.equal(savedBelka.progress.subevent1_belka_battle.settled, true)
    assert.equal(savedBelka.progress.subevent1_belka_battle.gold_delta, 58)
    assert.equal(savedBelka.player.money, belkaStart.player.money + savedBelka.progress.subevent1_belka_battle.gold_delta)
    assert.ok(savedBelka.progress.subevent1_belka_battle.gold_delta >= 40)
    assert.ok(savedBelka.progress.subevent1_belka_battle.gold_delta <= 60)
    assert.deepEqual(savedBelka.player.items, ['scissors_attract_white', 'paper_seal_white', 'greed_ring', 'rock_attract_crimson'])
    const settledMoney = savedBelka.player.money
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByText('...それと、騎士団から報告書が届いています。ベルカと番兵の所見から、サトシ様は「要注意人物」として記録されたそうです。', { exact: true }).waitFor()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByText('違うんです！ 全部誤解で！', { exact: true }).waitFor()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByText('...金貨58枚、確かにお渡ししました。次の依頼もお待ちしております。...犯罪歴がつかない範囲で。', { exact: true }).waitFor()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).player.money, settledMoney)
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === 'subevent1.belka.end',
      { timeout: 3000 }).catch(async () => { throw new Error(`Belka aftermath did not finish: ${await page.locator('body').innerText()}`) })
    await page.getByRole('heading', { name: 'サブイベント1 前半終了', exact: true }).waitFor()
    await page.getByRole('button', { name: 'ギルドホームへ戻る', exact: true }).click()
    await page.getByText('刃招きの珠・白紋', { exact: true }).waitFor()
    await page.getByText('紙封じの栞・白紋', { exact: true }).waitFor()
    const finalSave = JSON.parse(await readFile(target, 'utf8'))
    assert.equal(finalSave.progress.checkpoint_id, 'guild.home')
    assert.equal(finalSave.player.items.length, 4)
    assert.equal(finalSave.progress.subevent1_jin_battle.rounds.length, 1)
    assert.equal(finalSave.progress.subevent1_marco_battle.rounds.length, 1)
    assert.equal(finalSave.progress.subevent1_gald_battle.rounds.length, 1)
    assert.equal(finalSave.player.inventory.length, cards.length + 6)
    assert.equal(finalSave.progress.subevent1_belka_battle.rounds.length, 3)

    await writeFile(target, JSON.stringify({ ...finalSave,
      progress: { ...finalSave.progress, checkpoint_id: 'subevent1.belka.await' } }))
    await app.close()
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('subevent1-belka-settled').waitFor()
    await page.getByText(new RegExp(`依頼報酬は精算済み：\\+${finalSave.progress.subevent1_belka_battle.gold_delta}G。受付へ報告に向かいます。`),
      { exact: true }).waitFor()
  } finally {
    try { if (defeatApp) await defeatApp.close() }
    finally {
      try { if (app) await app.close() }
      finally {
        await rm(defeatData, { recursive: true, force: true })
        await rm(data, { recursive: true, force: true })
      }
    }
  }
})
