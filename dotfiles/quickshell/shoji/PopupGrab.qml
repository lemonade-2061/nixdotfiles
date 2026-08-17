import QtQuick
import Quickshell
import Quickshell.Hyprland

// HyprlandFocusGrab 互換ラッパー。
// Hyprland では本物の FocusGrab (外側クリックで cleared)。
// ShojiWM にはグラブ相当が無いので no-op — ポップアップは
// トグルボタンの再クリックで閉じる。
Scope {
  id: root

  property bool active: false
  property var windows: []
  signal cleared()

  LazyLoader {
    active: !Shoji.active && root.active

    HyprlandFocusGrab {
      active: true
      windows: root.windows
      onCleared: root.cleared()
    }
  }
}
