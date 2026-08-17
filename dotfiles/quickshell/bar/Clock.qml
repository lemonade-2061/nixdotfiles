import QtQuick
import Quickshell
import "../shoji"

// 時計 + クリックでカレンダーポップアップ
// カレンダーは自前QML描画。外側クリック(PopupGrab; Hyprlandのみ)で閉じる。
Item {
  id: root
  anchors.centerIn: parent
  width: pill.width
  height: parent ? parent.height : 32

  property var now: new Date()
  readonly property var wdays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  // コンパクトなピル型: [ 8/6 Wed · 14:23 ]
  Rectangle {
    id: pill
    anchors.verticalCenter: parent.verticalCenter
    width: content.width + 24
    height: 22
    radius: 11
    color: popup.visible ? "#556c7689"
         : ma.containsMouse ? "#886c7689"
         : "#5514171f"

    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
      id: content
      anchors.centerIn: parent
      spacing: 7

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.now, "M/d")
        color: "#d2d9e8"
        font.pixelSize: 11
        font.family: "JetBrainsMono Nerd Font"
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.wdays[root.now.getDay()]
        color: root.now.getDay() === 0 ? "#e8a7ad"
             : root.now.getDay() === 6 ? "#7ebae4"
             : "#a3b8d8"
        font.pixelSize: 11
        font.family: "JetBrainsMono Nerd Font"
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 3; height: 3; radius: 1.5
        color: "#6c7689"
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.now, "HH:mm")
        color: popup.visible ? "#7ebae4" : "#ffffff"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        font.bold: true

        Behavior on color { ColorAnimation { duration: 150 } }
      }
    }
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    onClicked: {
      if (!popup.visible)
        cal.resetToToday()
      popup.visible = !popup.visible
    }
  }

  PopupWindow {
    id: popup
    visible: false
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    implicitWidth: 252
    implicitHeight: panel.height + 8
    color: "transparent"

    Rectangle {
      id: panel
      anchors.top: parent.top
      anchors.topMargin: 8   // バーとの隙間
      anchors.horizontalCenter: parent.horizontalCenter
      width: 252
      height: col.height + 20
      radius: 12
      color: "#f014171f"
      border.color: "#336c7689"
      border.width: 1

      Column {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        spacing: 6

        // --- ヘッダー: ‹ 2026年8月 › ---
        Item {
          id: cal
          width: 7 * 32
          height: 24

          property int shownYear: 2026
          property int shownMonth: 0   // 0-11

          function resetToToday() {
            const d = new Date()
            shownYear = d.getFullYear()
            shownMonth = d.getMonth()
          }

          function shift(n) {
            const d = new Date(shownYear, shownMonth + n, 1)
            shownYear = d.getFullYear()
            shownMonth = d.getMonth()
          }

          // 6週 x 7日ぶんのセルを生成
          function cells() {
            const first = new Date(shownYear, shownMonth, 1)
            const today = new Date()
            const out = []
            for (let i = 0; i < 42; i++) {
              const d = new Date(shownYear, shownMonth, 1 + i - first.getDay())
              out.push({
                day: d.getDate(),
                dow: d.getDay(),
                inMonth: d.getMonth() === shownMonth,
                isToday: d.getFullYear() === today.getFullYear()
                      && d.getMonth() === today.getMonth()
                      && d.getDate() === today.getDate()
              })
            }
            return out
          }

          Text {
            anchors.centerIn: parent
            text: cal.shownYear + "年" + (cal.shownMonth + 1) + "月"
            color: "#d2d9e8"
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            font.bold: true
          }

          Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 24; height: 20; radius: 6
            color: prevMa.containsMouse ? "#446c7689" : "transparent"
            Text { anchors.centerIn: parent; text: "‹"; color: "#a3b8d8"; font.pixelSize: 14; font.bold: true }
            MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; onClicked: cal.shift(-1) }
          }

          Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 24; height: 20; radius: 6
            color: nextMa.containsMouse ? "#446c7689" : "transparent"
            Text { anchors.centerIn: parent; text: "›"; color: "#a3b8d8"; font.pixelSize: 14; font.bold: true }
            MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; onClicked: cal.shift(1) }
          }
        }

        // --- 曜日ヘッダー ---
        Row {
          Repeater {
            model: ["日", "月", "火", "水", "木", "金", "土"]
            Item {
              required property var modelData
              required property int index
              width: 32; height: 18
              Text {
                anchors.centerIn: parent
                text: parent.modelData
                color: parent.index === 0 ? "#bf616a"
                     : parent.index === 6 ? "#7ebae4"
                     : "#6c7689"
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
              }
            }
          }
        }

        // --- 日付グリッド ---
        Grid {
          columns: 7
          Repeater {
            model: cal.cells()
            Item {
              required property var modelData
              width: 32; height: 26
              Rectangle {
                anchors.centerIn: parent
                width: 26; height: 22; radius: 6
                color: parent.modelData.isToday ? "#a3b8d8" : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: parent.parent.modelData.day
                  color: parent.parent.modelData.isToday ? "#14171f"
                       : parent.parent.modelData.dow === 0 ? "#bf616a"
                       : parent.parent.modelData.dow === 6 ? "#7ebae4"
                       : "#d2d9e8"
                  opacity: parent.parent.modelData.inMonth ? 1.0 : 0.25
                  font.pixelSize: 11
                  font.family: "JetBrainsMono Nerd Font"
                  font.bold: parent.parent.modelData.isToday
                }
              }
            }
          }
        }
      }
    }
  }

  PopupGrab {
    active: popup.visible
    windows: [popup]
    onCleared: popup.visible = false
  }
}
