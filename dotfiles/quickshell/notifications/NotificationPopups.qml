import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick

// トースト通知: 画面右上 (バーの下) に積む。
// クリックでトーストだけ閉じる (センターに残る)。󰅖 で通知ごと消す。
PanelWindow {
  id: win
  required property var daemon

  screen: Quickshell.screens[0]
  anchors { top: true; right: true }
  margins { top: 6; right: 10 }
  implicitWidth: 340
  implicitHeight: Math.max(1, col.height)
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0
  color: "transparent"
  visible: daemon.popups.length > 0
  WlrLayershell.layer: WlrLayer.Overlay

  Column {
    id: col
    width: parent.width
    spacing: 8

    Repeater {
      model: win.daemon.popups

      delegate: Rectangle {
        id: toast
        required property var modelData
        property bool critical: modelData.urgency === NotificationUrgency.Critical

        width: col.width
        height: inner.height + 24
        radius: 12
        color: "#f014171f"
        border.color: critical ? "#77e48b7e" : "#336c7689"
        border.width: 1
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: 180 } }

        // 自動で消えるタイマー (ホバー中は停止、critical は自動で消えない)
        Timer {
          interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout : 6000
          running: !toastMa.containsMouse && !toast.critical
          onTriggered: win.daemon.hidePopup(toast.modelData)
        }

        MouseArea {
          id: toastMa
          anchors.fill: parent
          hoverEnabled: true
          onClicked: win.daemon.hidePopup(toast.modelData)
        }

        Column {
          id: inner
          anchors.top: parent.top
          anchors.topMargin: 12
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.right: parent.right
          anchors.rightMargin: 12
          spacing: 8

          Row {
            width: parent.width
            spacing: 10

            Item {
              width: 32; height: 32

              Image {
                id: icon
                anchors.fill: parent
                source: win.daemon.iconFor(toast.modelData)
                sourceSize: Qt.size(64, 64)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
              }

              // アイコンが無い / 読めないときのフォールバック
              Rectangle {
                anchors.fill: parent
                radius: 8
                color: "#226c7689"
                visible: icon.status !== Image.Ready
                Text {
                  anchors.centerIn: parent
                  text: toast.critical ? "󰀪" : "󰂚"
                  color: toast.critical ? "#e48b7e" : "#7ebae4"
                  font.pixelSize: 16
                  font.family: "JetBrainsMono Nerd Font"
                }
              }
            }

            Column {
              width: parent.width - 32 - 10 - 18 - 10
              spacing: 2

              Text {
                width: parent.width
                text: toast.modelData.summary || toast.modelData.appName
                color: "#ffffff"
                font.pixelSize: 13
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: toast.modelData.body
                visible: text !== ""
                color: "#a3b8d8"
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
              }
            }

            // 通知ごと消す ✕
            Text {
              text: "󰅖"
              color: xMa.containsMouse ? "#e48b7e" : "#6c7689"
              font.pixelSize: 12
              font.family: "JetBrainsMono Nerd Font"

              MouseArea {
                id: xMa
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                onClicked: toast.modelData.dismiss()
              }
            }
          }

          // アクションボタン (Open 等)
          Row {
            spacing: 6
            visible: toast.modelData.actions.length > 0

            Repeater {
              model: toast.modelData.actions

              delegate: Rectangle {
                id: actBtn
                required property var modelData
                width: actTxt.width + 20
                height: 22
                radius: 11
                color: actMa.containsMouse ? "#446c7689" : "#226c7689"

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                  id: actTxt
                  anchors.centerIn: parent
                  text: actBtn.modelData.text || actBtn.modelData.identifier
                  color: "#a3b8d8"
                  font.pixelSize: 10
                  font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                  id: actMa
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    actBtn.modelData.invoke()
                    win.daemon.hidePopup(toast.modelData)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
