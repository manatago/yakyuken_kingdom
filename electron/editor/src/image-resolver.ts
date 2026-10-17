import { configureOriginalAssetResolver } from '../../renderer/src/original-assets'

export function setEditorImageCatalog(paths: readonly string[]) {
  const images = new Set(paths)
  configureOriginalAssetResolver(path => images.has(path)
    ? `janken-project-image://project/?path=${encodeURIComponent(path)}` : undefined)
}
