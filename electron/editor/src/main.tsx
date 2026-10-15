import { createRoot } from 'react-dom/client'
import { LayoutEditor } from './LayoutEditor'
import '../../renderer/src/style.css'
import './style.css'

createRoot(document.getElementById('root')!).render(<LayoutEditor />)
