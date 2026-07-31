import QtQuick
import Quickshell.Hyprland

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
        font.pixelSize: 13
        font.bold: modelData.focused
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("hl.dsp.focus({workspace=" + modelData.id + "})")
      }
    }
  }
}
