import QtQuick
import Quickshell

// NixOSロゴのランチャーボタン
// クリックで Noctalia のランチャーを開く (Noctalia 起動中のみ)。
Rectangle {
  id: root
  anchors.verticalCenter: parent.verticalCenter
  width: 26
  height: 22
  radius: height / 2
  color: ma.containsMouse ? "#886c7689" : "#5514171f"

  Behavior on color { ColorAnimation { duration: 150 } }

  Text {
    anchors.centerIn: parent
    text: ""  // nf-linux-nixos
    color: ma.containsMouse ? "#7ebae4" : "#a3b8d8"
    font.pixelSize: 14
    font.family: "JetBrainsMono Nerd Font"

    Behavior on color { ColorAnimation { duration: 150 } }
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    onClicked: Quickshell.execDetached(
      ["noctalia", "msg", "panel-toggle", "launcher"])
  }
}
