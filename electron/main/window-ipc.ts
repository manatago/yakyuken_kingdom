import { BrowserWindow, ipcMain, type IpcMainInvokeEvent } from 'electron'

const authorizedWindows = new Set<number>()

export function authorizeWindow(window: BrowserWindow): void {
  const webContentsId = window.webContents.id
  authorizedWindows.add(webContentsId)
  window.once('closed', () => authorizedWindows.delete(webContentsId))
}

export function assertWindowRequest(
  event: IpcMainInvokeEvent,
  argumentsReceived: unknown[],
  expectedCount: number
): BrowserWindow {
  if (argumentsReceived.length !== expectedCount || !authorizedWindows.has(event.sender.id) ||
      event.senderFrame !== event.sender.mainFrame) {
    throw new Error('Unauthorized IPC request')
  }
  const window = BrowserWindow.fromWebContents(event.sender)
  if (!window || window.isDestroyed()) throw new Error('Unauthorized IPC request')
  return window
}

export function registerWindowHandlers(): void {
  ipcMain.handle('window:minimize', (event, ...args: unknown[]) => {
    assertWindowRequest(event, args, 0).minimize()
  })
  ipcMain.handle('window:toggle-maximize', (event, ...args: unknown[]) => {
    const window = assertWindowRequest(event, args, 0)
    if (window.isMaximized()) window.unmaximize()
    else window.maximize()
  })
  ipcMain.handle('window:close', (event, ...args: unknown[]) => {
    assertWindowRequest(event, args, 0).close()
  })
}
