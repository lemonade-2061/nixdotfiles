import QtQuick
import Quickshell
import "../shoji"

// 通知センター: ベルアイコン + 件数バッジ → 通知一覧ポップアップ
// Super+N (qs ipc call notifications toggle) でも開閉できる
Item {
  id: root
  required property var daemon
  anchors.verticalCenter: parent.verticalCenter
  width: 26
  height: parent ? parent.height : 32

  Connections {
    target: root.daemon
    function onTogglePanel() { root.togglePopup() }
  }

  function togglePopup() {
    popup.visible = !popup.visible
  }

  // --- ボタン ---
  Rectangle {
    id: btn
    anchors.verticalCenter: parent.verticalCenter
    width: 26
    height: 22
    radius: 11
    color: popup.visible ? "#556c7689"
         : ma.containsMouse ? "#886c7689"
         : "#5514171f"

    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
      anchors.centerIn: parent
      text: root.daemon.dnd ? "󰂛" : (root.daemon.count > 0 ? "󰂚" : "󰂜")
      color: popup.visible || ma.containsMouse ? "#7ebae4" : "#a3b8d8"
      font.pixelSize: 13
      font.family: "JetBrainsMono Nerd Font"

      Behavior on color { ColorAnimation { duration: 150 } }
    }

    // 件数バッジ
    Rectangle {
      visible: root.daemon.count > 0
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: -2
      anchors.topMargin: -3
      width: Math.max(12, badgeTxt.width + 6)
      height: 12
      radius: 6
      color: "#7ebae4"

      Text {
        id: badgeTxt
        anchors.centerIn: parent
        text: root.daemon.count > 9 ? "9+" : root.daemon.count
        color: "#14171f"
        font.pixelSize: 8
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
      }
    }
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.togglePopup()
  }

  // --- ポップアップ ---
  PopupWindow {
    id: popup
    visible: false
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    // 画面右端からはみ出さないようクランプ (Shoji.popupShiftX 参照)
    anchor.rect.x: popup.visible
      ? Shoji.popupShiftX(root, root.QsWindow.window, popup.implicitWidth)
      : 0
    implicitWidth: 340
    implicitHeight: panel.height + 16
    color: "transparent"

    Rectangle {
      id: panel
      anchors.horizontalCenter: parent.horizontalCenter
      y: popup.visible ? 8 : -height - 8
      width: 340
      height: content.height + 32
      radius: 12
      color: "#f014171f"
      border.color: "#336c7689"
      border.width: 1
      opacity: popup.visible ? 1 : 0

      Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
      Behavior on opacity { NumberAnimation { duration: 200 } }

      Column {
        id: content
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        // --- ヘッダー: タイトル + DND / 全消去 ---
        Item {
          width: 308
          height: 24

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // DND トグル
            Rectangle {
              width: 26; height: 22; radius: 11
              color: root.daemon.dnd ? "#7ebae4"
                   : dndMa.containsMouse ? "#446c7689" : "#226c7689"

              Behavior on color { ColorAnimation { duration: 150 } }

              Text {
                anchors.centerIn: parent
                text: "󰂛"
                color: root.daemon.dnd ? "#14171f" : "#a3b8d8"
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
              }

              MouseArea {
                id: dndMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.daemon.dnd = !root.daemon.dnd
              }
            }

            // 全消去
            Rectangle {
              width: 26; height: 22; radius: 11
              color: clrMa.containsMouse ? "#446c7689" : "#226c7689"

              Behavior on color { ColorAnimation { duration: 150 } }

              Text {
                anchors.centerIn: parent
                text: "󰩹"
                color: clrMa.containsMouse ? "#e48b7e" : "#a3b8d8"
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
              }

              MouseArea {
                id: clrMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.daemon.clearAll()
              }
            }
          }
        }

        // 区切り線
        Rectangle {
          width: 308; height: 1
          color: "#226c7689"
        }

        // --- 通知一覧 (新しい順 = 下から積んで上に表示) ---
        ListView {
          id: list
          width: 308
          height: Math.min(contentHeight, 400)
          visible: root.daemon.count > 0
          clip: true
          spacing: 8
          verticalLayoutDirection: ListView.BottomToTop
          model: root.daemon.server.trackedNotifications

          delegate: Rectangle {
            id: card
            required property var modelData

            width: list.width
            height: cardInner.height + 20
            radius: 10
            color: cardMa.containsMouse ? "#2a6c7689" : "#1a6c7689"

            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
              id: cardMa
              anchors.fill: parent
              hoverEnabled: true
            }

            Row {
              id: cardInner
              anchors.top: parent.top
              anchors.topMargin: 10
              anchors.left: parent.left
              anchors.leftMargin: 10
              anchors.right: parent.right
              anchors.rightMargin: 10
              spacing: 8

              Item {
                width: 28; height: 28

                Image {
                  id: cardIcon
                  anchors.fill: parent
                  source: root.daemon.iconFor(card.modelData)
                  sourceSize: Qt.size(56, 56)
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  visible: status === Image.Ready
                }

                Rectangle {
                  anchors.fill: parent
                  radius: 7
                  color: "#226c7689"
                  visible: cardIcon.status !== Image.Ready
                  Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    color: "#7ebae4"
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                  }
                }
              }

              Column {
                width: parent.width - 28 - 8 - 16 - 8
                spacing: 2

                Row {
                  width: parent.width
                  spacing: 6

                  Text {
                    text: card.modelData.appName || "app"
                    color: "#6c7689"
                    font.pixelSize: 9
                    font.family: "JetBrainsMono Nerd Font"
                  }
                  Text {
                    text: root.daemon.timeOf(card.modelData)
                    color: "#6c7689"
                    font.pixelSize: 9
                    font.family: "JetBrainsMono Nerd Font"
                  }
                }

                Text {
                  width: parent.width
                  text: card.modelData.summary
                  visible: text !== ""
                  color: "#ffffff"
                  font.pixelSize: 12
                  font.bold: true
                  font.family: "JetBrainsMono Nerd Font"
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: card.modelData.body
                  visible: text !== ""
                  color: "#a3b8d8"
                  font.pixelSize: 10
                  font.family: "JetBrainsMono Nerd Font"
                  textFormat: Text.PlainText
                  wrapMode: Text.Wrap
                  maximumLineCount: 4
                  elide: Text.ElideRight
                }
              }

              Text {
                text: "󰅖"
                color: cardXMa.containsMouse ? "#e48b7e" : "#6c7689"
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"

                MouseArea {
                  id: cardXMa
                  anchors.fill: parent
                  anchors.margins: -4
                  hoverEnabled: true
                  onClicked: card.modelData.dismiss()
                }
              }
            }
          }
        }

        // --- 空のとき ---
        Column {
          width: 308
          visible: root.daemon.count === 0
          spacing: 6

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰂜"
            color: "#336c7689"
            font.pixelSize: 28
            font.family: "JetBrainsMono Nerd Font"
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No notifications"
            color: "#6c7689"
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
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
