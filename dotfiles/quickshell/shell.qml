//
// Minimal Quickshell bar for Hyprland
// Docs: https://quickshell.outfoxxed.me/docs/
//
import Quickshell
import Quickshell.Hyprland
import QtQuick

Scope {
    // 1 バーを全モニターに出す
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 32
            color: "#1a1a1aee"

            // --- 左: ワークスペース ---
            Row {
                id: workspaces
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: Hyprland.workspaces

                    Rectangle {
                        required property var modelData
                        width: 24
                        height: 20
                        radius: 6
                        color: modelData.focused ? "#33ccff" : "#333333"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name
                            color: modelData.focused ? "#000000" : "#cccccc"
                            font.pixelSize: 12
                            font.bold: modelData.focused
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + modelData.id)
                        }
                    }
                }
            }

            // --- 中央: 時計 ---
            Text {
                id: clock
                anchors.centerIn: parent
                color: "#ffffff"
                font.pixelSize: 13
                font.bold: true

                property var now: new Date()
                text: Qt.formatDateTime(now, "ddd  yyyy-MM-dd  HH:mm:ss")

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clock.now = new Date()
                }
            }

            // --- 右: 予約枠（今後 音量/電池/トレイ を足す） ---
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: "#888888"
                font.pixelSize: 12
                text: Quickshell.screens.length > 1 ? modelData.name : ""
            }
        }
    }
}
