import QtQuick
import Quickshell.Hyprland

// ワークスペースインジケーター
// フォーカス中はピル状に伸びて番号を表示、他は小さなドット。
// special workspace (super+S の magic, id<0) は通常の列に混ぜず、
// 存在するときだけ右端に杖アイコンで表示する。
// 色は theme.lua のグレーブルーパレットに合わせる。
Rectangle {
  id: root
  anchors.verticalCenter: parent.verticalCenter
  width: row.width + 14
  height: 22
  radius: height / 2
  color: "#5514171f"

  readonly property var specialWs:
    Hyprland.workspaces.values.find(w => w.id < 0) ?? null

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6

    Repeater {
      model: Hyprland.workspaces.values
               .filter(w => w.id > 0)
               .sort((a, b) => a.id - b.id)

      Rectangle {
        id: ws
        required property var modelData
        readonly property bool focused: modelData.focused

        anchors.verticalCenter: parent.verticalCenter
        width: focused ? 30 : 16
        height: 16
        radius: height / 2
        color: focused ? "#a3b8d8"
             : modelData.urgent ? "#bf616a"
             : ma.containsMouse ? "#6c7689"
             : "#434c5e"

        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: ws.modelData.name
          color: ws.focused ? "#14171f" : "#d2d9e8"
          opacity: ws.focused ? 1.0 : 0.7
          font.pixelSize: 10
          font.bold: ws.focused

          Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        MouseArea {
          id: ma
          anchors.fill: parent
          hoverEnabled: true
          onClicked: Hyprland.dispatch("hl.dsp.focus({workspace=" + ws.modelData.id + "})")
        }
      }
    }

    Rectangle {
      id: special
      visible: root.specialWs !== null
      readonly property bool focused: root.specialWs !== null && root.specialWs.focused

      anchors.verticalCenter: parent.verticalCenter
      width: 16
      height: 16
      radius: height / 2
      color: focused ? "#7ebae4"
           : sma.containsMouse ? "#6c7689"
           : "#434c5e"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        anchors.centerIn: parent
        text: ""  // nf-fa-magic
        color: special.focused ? "#14171f" : "#d2d9e8"
        opacity: special.focused ? 1.0 : 0.7
        font.pixelSize: 9
        font.family: "JetBrainsMono Nerd Font"

        Behavior on opacity { NumberAnimation { duration: 150 } }
      }

      MouseArea {
        id: sma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Hyprland.dispatch('hl.dsp.workspace.toggle_special("magic")')
      }
    }
  }
}
