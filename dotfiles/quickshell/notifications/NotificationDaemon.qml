import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// 通知デーモン: org.freedesktop.Notifications を quickshell 側で実装する。
// tracked = センター一覧に残る通知 / popups = トースト表示中の通知。
// ※ mako 等の他の通知デーモンとは同時に動かせない (D-Bus 名の取り合いになる)
Scope {
  id: root

  property alias server: server
  property var popups: []     // トースト表示中の Notification
  property bool dnd: false    // Do Not Disturb: トーストを出さない (センターには残る)
  property var times: ({})    // notification id -> 受信時刻 "HH:mm"

  readonly property int count: server.trackedNotifications.values.length

  // Super+N (qs ipc call notifications toggle) → 各バーのパネル開閉
  signal togglePanel()

  NotificationServer {
    id: server
    keepOnReload: true
    actionsSupported: true
    bodySupported: true
    imageSupported: true
    persistenceSupported: true

    onNotification: notif => {
      notif.tracked = true
      root.times[notif.id] = Qt.formatTime(new Date(), "HH:mm")
      notif.closed.connect(() => {
        delete root.times[notif.id]
        root.hidePopup(notif)
      })
      if (!root.dnd)
        root.popups = root.popups.concat([notif])
    }
  }

  // トーストだけ閉じる (通知自体はセンターに残る)
  function hidePopup(notif) {
    root.popups = root.popups.filter(p => p !== notif)
  }

  function timeOf(notif) {
    return root.times[notif.id] || ""
  }

  function clearAll() {
    root.popups = []
    server.trackedNotifications.values.slice().forEach(n => n.dismiss())
  }

  // 表示用アイコン: 通知画像 > アプリアイコン (テーマ解決) > "" (フォールバック)
  function iconFor(notif) {
    if (notif.image)
      return notif.image
    if (notif.appIcon) {
      if (notif.appIcon.startsWith("file://"))
        return notif.appIcon
      if (notif.appIcon.startsWith("/"))
        return "file://" + notif.appIcon
      return Quickshell.iconPath(notif.appIcon, true)
    }
    return ""
  }

  IpcHandler {
    target: "notifications"
    function toggle(): void { root.togglePanel() }
  }
}
