import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick
import "./bar"

Scope {
    // 既定オーディオシンクをバインド（音量の読み書きに必須）
    PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }

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
            Workspace{}

            // --- 中央: 時計 ---
            Clock{}

            // --- 右: 音量 / バッテリー ---
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Volume{}

                Battery{}
            }
        }
    }
}
