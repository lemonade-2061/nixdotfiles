pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ShojiWM アダプタ。
// ShojiWM の設定 (~/.config/shojiwm/src/index.tsx) が開いている
// NDJSON IPC ソケット ($XDG_RUNTIME_DIR/shojiwm-$WAYLAND_DISPLAY.sock) に接続し、
//   workspaces.get / workspaces.changed → view (WorkspacesView)
//   workspaces.activate / windows.activate → コマンド送信
// を提供する。Hyprland 上では active=false で何もしない。
Singleton {
  id: root

  readonly property bool active:
    Quickshell.env("XDG_CURRENT_DESKTOP") === "ShojiWM"

  // ShojiWM 側 viewForIpc() の形:
  // { currentMonitor, monitors: [{ name, active, workspaces: [{ index, windowCount, isTiled, active, windows }] }] }
  property var view: ({ currentMonitor: "", monitors: [] })

  function monitorWorkspaces(name) {
    const monitors = root.view.monitors ?? []
    const mon = monitors.find(m => m.name === name)
    return mon ? mon.workspaces : []
  }

  function activate(monitor, index) {
    send({ method: "workspaces.activate", params: { monitor: monitor, index: index } })
  }

  function activateWindow(windowId) {
    send({ method: "windows.activate", params: { windowId: windowId } })
  }

  function refresh() {
    send({ id: 1, method: "workspaces.get" })
  }

  function send(obj) {
    if (socket.connected)
      socket.write(JSON.stringify(obj) + "\n")
  }

  // バー右端のボタン等にぶら下がる中央寄せ PopupWindow が画面外へ
  // はみ出さないようにする anchor.rect.x 補正量。Hyprland は compositor が
  // xdg_positioner のスライド調整で画面内に収めてくれるが ShojiWM はやらないので
  // クライアント側でクランプする (Hyprland 上でも同じ計算で無害)。
  //   item: アンカー元 (ボタンの root Item)
  //   win:  item を含むバーの QsWindow (呼び出し側で root.QsWindow.window を渡す)
  //   popupWidth: ポップアップの幅
  function popupShiftX(item, win, popupWidth) {
    if (!win || !win.contentItem)
      return 0
    const pos = item.mapToItem(win.contentItem, 0, 0)
    const center = pos.x + item.width / 2
    const margin = 8
    let shift = 0
    const right = center + popupWidth / 2
    const left = center - popupWidth / 2
    if (right > win.width - margin)
      shift = (win.width - margin) - right
    if (left + shift < margin)
      shift = margin - left
    return shift
  }

  Socket {
    id: socket
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/shojiwm-"
          + Quickshell.env("WAYLAND_DISPLAY") + ".sock"
    connected: root.active

    onConnectedChanged: {
      if (connected)
        root.refresh()
    }

    parser: SplitParser {
      onRead: message => {
        if (message.trim().length === 0)
          return
        let obj
        try {
          obj = JSON.parse(message)
        } catch (e) {
          return
        }
        if (obj.event === "workspaces.changed")
          root.view = obj.payload
        else if (obj.id === 1 && obj.result !== undefined)
          root.view = obj.result
      }
    }
  }

  // WM 設定のホットリロードでソケットが閉じた場合の再接続
  Timer {
    interval: 2000
    repeat: true
    running: root.active && !socket.connected
    onTriggered: socket.connected = true
  }
}
