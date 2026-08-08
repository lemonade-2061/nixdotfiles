import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// 壁紙ピッカー
// super+W (binds.lua) → `qs ipc call wallpaper toggle` で開閉。
// ~/Pictures/wallpaper の画像を平行四辺形の縦長ストリップとして横に並べ、
// ホバー/矢印キーで選択(幅が広がる)、クリック/Enter で `awww img` に投げる。
// ストリップ自体を shear 変換し、中の画像に逆 shear をかけることで
// 「枠は斜め・画像は正立」のまま平行四辺形にクリップしている。
// 配色は theme.lua のグレーブルーパレットに合わせる。
Scope {
  id: root

  readonly property string wallDir: Quickshell.env("HOME") + "/Pictures/wallpaper"
  property string currentWall: ""

  function toggle() {
    if (win.visible) {
      win.visible = false
      return
    }
    // フォーカス中のモニターに出す
    const mon = Hyprland.focusedMonitor
    const scr = Quickshell.screens.find(s => s.name === (mon ? mon.name : "")) ?? null
    if (scr !== null)
      win.screen = scr
    queryProc.running = true
    win.visible = true
  }

  function apply(path) {
    root.currentWall = path
    Quickshell.execDetached([
      "awww", "img", path,
      "-t", "grow",
      "--transition-duration", "0.8",
      "--transition-fps", "60"
    ])
    win.visible = false
  }

  IpcHandler {
    target: "wallpaper"
    function toggle(): void { root.toggle() }
  }

  // 現在の壁紙を問い合わせて選択初期位置とバッジに使う
  Process {
    id: queryProc
    command: ["awww", "query"]
    stdout: StdioCollector {
      onStreamFinished: {
        const m = this.text.match(/image: (.+)/)
        root.currentWall = m ? m[1].trim() : ""
        for (let i = 0; i < rep.count; i++) {
          const it = rep.itemAt(i)
          if (it && it.isCurrent) { win.selIndex = i; break }
        }
      }
    }
  }

  FolderListModel {
    id: wallpapers
    folder: "file://" + root.wallDir
    nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif"]
    showDirs: false
  }

  PanelWindow {
    id: win
    visible: false
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive
                                         : WlrKeyboardFocus.None

    property int selIndex: 0

    readonly property real shear: 0.22               // 傾き (tan≈12.4°)
    readonly property int stripH: Math.min(Math.round(height * 0.55), 460)
    readonly property real overhang: shear * stripH  // 傾きぶんの水平張り出し
    readonly property int stripW: Math.max(90, Math.min(190,
      Math.round((width * 0.82 - overhang) / Math.max(1, wallpapers.count) - 14)))

    function applySelected() {
      const it = rep.itemAt(selIndex)
      if (it)
        root.apply(it.path)
    }

    // 背景を暗くして、外側クリックで閉じる
    MouseArea {
      anchors.fill: parent
      onClicked: win.visible = false
      Rectangle { anchors.fill: parent; color: "#9914171f" }
    }

    Item {
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: win.visible = false
      Keys.onReturnPressed: win.applySelected()
      Keys.onLeftPressed:  win.selIndex = Math.max(0, win.selIndex - 1)
      Keys.onRightPressed: win.selIndex = Math.min(wallpapers.count - 1, win.selIndex + 1)

      Row {
        id: strips
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -24
        spacing: 14

        Repeater {
          id: rep
          model: wallpapers

          // 平行四辺形ストリップ本体 (これ自体が shear されている)
          Item {
            id: cell
            required property string fileName
            required property string filePath
            required property url fileUrl
            required property int index

            readonly property string path: filePath
            readonly property bool isCurrent: filePath === root.currentWall
            readonly property bool selected: win.selIndex === index

            width: selected ? Math.round(win.stripW * 1.35) : win.stripW
            height: win.stripH
            // clip:true は shear された Item だと AABB でしか切れないので、
            // layer でテクスチャ化してレイヤー境界 (=平行四辺形) で切り抜く
            layer.enabled: true
            layer.smooth: true
            layer.samples: 4

            // x' = x - k*y + k*h/2 … 上端が右に張り出す "/" 型
            transform: Matrix4x4 {
              matrix: Qt.matrix4x4(
                1, -win.shear, 0, win.shear * cell.height / 2,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1)
            }

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            // 画像は逆 shear で正立させたままクリップだけ受ける
            Image {
              width: cell.width + win.overhang
              height: cell.height
              x: -win.overhang / 2
              source: cell.fileUrl
              sourceSize: Qt.size(480, 720)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true

              transform: Matrix4x4 {
                matrix: Qt.matrix4x4(
                  1, win.shear, 0, -win.shear * cell.height / 2,
                  0, 1, 0, 0,
                  0, 0, 1, 0,
                  0, 0, 0, 1)
              }
            }

            // 非選択は暗く沈める
            Rectangle {
              anchors.fill: parent
              color: "#14171f"
              opacity: cell.selected ? 0.0 : ma.containsMouse ? 0.2 : 0.45
              Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // 枠 (shear ごと平行四辺形になる)
            Rectangle {
              anchors.fill: parent
              color: "transparent"
              border.width: 2
              border.color: cell.selected ? "#a3b8d8"
                          : cell.isCurrent ? "#7ebae4"
                          : "#55434c5e"
              Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: ma
              anchors.fill: parent
              hoverEnabled: true
              onEntered: win.selIndex = cell.index
              onClicked: root.apply(cell.path)
            }
          }
        }
      }

      // 選択中のファイル名 + 使用中チップ
      Row {
        anchors.top: strips.bottom
        anchors.topMargin: 26
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        readonly property var selItem: rep.itemAt(win.selIndex)

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: parent.selItem ? parent.selItem.fileName : ""
          color: "#d2d9e8"
          font.pixelSize: 13
          font.family: "JetBrainsMono Nerd Font"
          font.bold: true
        }

        Rectangle {
          visible: parent.selItem ? parent.selItem.isCurrent : false
          anchors.verticalCenter: parent.verticalCenter
          width: useLabel.width + 14
          height: 17
          radius: height / 2
          color: "#7ebae4"
          Text {
            id: useLabel
            anchors.centerIn: parent
            text: "使用中"
            color: "#14171f"
            font.pixelSize: 9
            font.family: "JetBrainsMono Nerd Font"
            font.bold: true
          }
        }
      }
    }
  }
}
