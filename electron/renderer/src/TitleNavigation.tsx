import { useState } from 'react'
import { developerJumpTarget, developerTools, eventBattleTargets, createDeveloperEventSave, createDeveloperJumpSave } from '../../../packages/developer/jump'
import type { SaveData } from '../../../packages/domain/save'
import type { EditorView } from '../../preload/api'

export type TitleMenu = 'title' | 'jump' | 'events' | 'edit' | 'portraits'

export function TitleNavigation({ menu, onMenu, onPlay, onEditor, disabled }: {
  menu: Exclude<TitleMenu, 'title'>; onMenu(menu: TitleMenu): void
  onPlay(save: SaveData, origin: 'jump' | 'events'): void
  onEditor(view: EditorView): Promise<void>; disabled: boolean
}) {
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  async function open(view: EditorView) {
    if (busy || disabled) return
    setBusy(true); setError('')
    try { await onEditor(view) } catch { setError('編集アプリを開けませんでした。既に開いている編集アプリを閉じてから再度選んでください。未ビルドの場合はゲームとエディタを両方ビルドしてください。') }
    finally { setBusy(false) }
  }
  function play(factory: () => SaveData, origin: 'jump' | 'events') {
    try { setError(''); onPlay(factory(), origin) } catch { setError('開始データを作成できませんでした。原本との接続を確認してください。') }
  }
  const locked = disabled || busy
  return <section className="title-submenu" aria-label="開始メニュー">
    <h2>{menu === 'jump' ? 'ジャンプ先を選択' : menu === 'events' ? 'イベントバトル' : menu === 'portraits' ? 'バトル立ち絵編集' : '編集モード'}</h2>
    <button disabled={locked} onClick={() => onMenu(menu === 'portraits' ? 'edit' : 'title')}>戻る</button>
    {menu === 'jump' && <><p>場面を選ぶと、その場面から開始します。通常の保存データは変更しません。</p>
      <div className="title-scene-list">{developerTools.jump_points.map((point, index) => {
        const target = developerJumpTarget(index)
        return point.name.startsWith('---') ? <h3 key={index}>{point.name.replaceAll('---', '').trim()}</h3>
          : <div key={index}><button disabled={locked || !target.available} onClick={() => play(() => createDeveloperJumpSave(index), 'jump')}>{point.name}</button>
            {!target.available && <small>{target.reason}</small>}</div>
      })}</div></>}
    {menu === 'events' && <><p>原本の通常イベント戦を選択します。所持金1000G・初期カードで開始し、通常の保存データは変更しません。</p>
      <div className="title-scene-list">{eventBattleTargets.map(target => <button key={target.id} disabled={locked}
        onClick={() => play(() => createDeveloperEventSave(target.id), 'events')}>{target.name}</button>)}</div></>}
    {menu === 'edit' && <div className="title-menu-list">
      <button disabled={locked} onClick={() => onMenu('portraits')}>バトル立ち絵編集</button>
      <button disabled title="移植作業中です">バトルシステム確認（移植中）</button>
      <button disabled={locked} onClick={() => void open('slides')}>紙芝居編集（敗北シーン）</button>
      <button disabled={locked} onClick={() => void open('story')}>ストーリー編集</button>
      <p>編集機能は別ビルドの開発用アプリで開きます。</p>
    </div>}
    {menu === 'portraits' && <div className="title-menu-list">
      <button disabled title="移植作業中です">ランダムバトル（移植中）</button>
      <button disabled={locked} onClick={() => void open('battle')}>イベントバトル</button>
    </div>}
    {error && <p role="alert">{error}</p>}
  </section>
}
