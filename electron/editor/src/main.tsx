import { createRoot } from 'react-dom/client'
import { DeveloperTools } from './DeveloperTools'
import '../../renderer/src/style.css'
import './style.css'
import { setEditorImageCatalog } from './image-resolver'
import type { EditorApi } from '../../preload/api'

const api = (globalThis as typeof globalThis & { janken: EditorApi }).janken
void api.content.imageCatalog!().then(setEditorImageCatalog).catch(() => {})

createRoot(document.getElementById('root')!).render(<DeveloperTools />)
