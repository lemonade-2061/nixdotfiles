//
// Minimal Quickshell bar for Hyprland
// Docs: https://quickshell.outfoxxed.me/docs/
//
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Scope {
    // 既定オーディオシンクをバインド（音量の読み書きに必須）
    PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }

    // バッテリー sysfs（10秒ごとにリロード）
    FileView { id: batCap;    path: "/sys/class/power_supply/BAT0/capacity" }
    FileView { id: batStatus; path: "/sys/class/power_supply/BAT0/status" }
    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: { batCap.reload(); batStatus.reload() }
    }

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

            // --- 右: 音量 / バッテリー ---
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                // 音量: ホイールで増減 / クリックでミュート
                Text {
                    id: volText
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 12
                    font.bold: true

                    property var sink: Pipewire.defaultAudioSink
                    property var audio: sink && sink.ready ? sink.audio : null
                    property int vol: audio ? Math.round(audio.volume * 100) : 0
                    property bool muted: audio ? audio.muted : false

                    color: muted ? "#888888" : "#8fd0ff"
                    text: (muted ? "🔇 " : "🔊 ") + vol + "%"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (volText.audio) volText.audio.muted = !volText.audio.muted
                        onWheel: {
                            if (!volText.audio) return
                            var step = (wheel.angleDelta.y > 0 ? 0.05 : -0.05)
                            volText.audio.volume = Math.max(0, Math.min(1, volText.audio.volume + step))
                        }
                    }
                }

                // バッテリー: 残量で色分け、充電中は +
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 12
                    font.bold: true

                    property int pct: parseInt(batCap.text()) || 0
                    property string st: batStatus.text().trim()
                    property bool charging: st === "Charging" || st === "Full"

                    color: charging ? "#7bd88f" : (pct <= 15 ? "#ff5555" : (pct <= 30 ? "#f1fa8c" : "#cccccc"))
                    text: "🔋 " + pct + "%" + (charging ? "+" : "")
                }
            }
        }
    }
}
