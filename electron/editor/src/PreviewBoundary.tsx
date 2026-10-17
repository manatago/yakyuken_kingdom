import { Component, type ReactNode } from 'react'

export class PreviewBoundary extends Component<{ children: ReactNode }, { failed: boolean }> {
  state = { failed: false }
  static getDerivedStateFromError() { return { failed: true } }
  render() {
    return this.state.failed ? <p role="alert">プレビューできません。画像参照と表示パラメータを確認してください。入力内容は保持しています。</p> : this.props.children
  }
}
