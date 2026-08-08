import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick
import "./bar"
import "./wallpaper"

Scope {
    // 既定オーディオシンクをバインド（音量の読み書きに必須）
    PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }

    // 壁紙ピッカー (super+W → qs ipc call wallpaper toggle)
    WallpaperPicker {}

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
            color: "#77889eaf"

            // --- 左: ランチャー / ワークスペース / CPU・メモリ ---
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                NixLauncher{}

                Workspace{}

                Stats{}
            }

            // --- 中央: 時計 ---
            Clock{ id: clock }

            // --- 右: メディア / システム(音量+バッテリー) ---
            Row {
                id: rightRow
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // 時計の右端までしか伸びない (収まらない曲名は"…"で省略)
                Media {
                    maxWidth: Math.max(60,
                        (rightRow.parent.width - clock.width) / 2
                        - sysPill.width - cc.width - rightRow.spacing * 2
                        - rightRow.anchors.rightMargin - 16)
                }

                Rectangle {
                    id: sysPill
                    anchors.verticalCenter: parent.verticalCenter
                    width: sysRow.width + 24
                    height: 22
                    radius: 11
                    color: "#5514171f"

                    Row {
                        id: sysRow
                        anchors.centerIn: parent
                        spacing: 12

                        Volume{}

                        Battery{}
                    }
                }

                ControlCenter{ id: cc }
            }
        }
    }
}
