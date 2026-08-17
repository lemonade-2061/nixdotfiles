import QtQuick
import Quickshell.Hyprland
import "../shoji"

// ワークスペースインジケーター
// フォーカス中はピル状に伸びて番号を表示、他は小さなドット。
// special workspace (super+S の magic, id<0) は通常の列に混ぜず、
// 存在するときだけ右端に杖アイコンで表示する (Hyprland のみ。ShojiWM に
// special workspace は無い)。
// ShojiWM では Shoji アダプタ (IPC ソケット) から自モニターの
// ワークスペース一覧を取り、Hyprland では従来通り Hyprland シングルトンを使う。
// 色は theme.lua のグレーブルーパレットに合わせる。
Rectangle {
  id: root
  anchors.verticalCenter: parent.verticalCenter
  width: row.width + 14
  height: 22
  radius: height / 2
  color: "#5514171f"

  // バー (shell.qml) から自スクリーン名をもらう (ShojiWM 用)
  property string monitorName: ""

  readonly property var specialWs:
    Shoji.active ? null
                 : (Hyprland.workspaces.values.find(w => w.id < 0) ?? null)

  // どちらのコンポジタでも {id, name, focused, urgent} に正規化する
  readonly property var wsModel:
    Shoji.active
      ? Shoji.monitorWorkspaces(root.monitorName)
          .map(w => ({ id: w.index, name: String(w.index),
                       focused: w.active, urgent: false }))
      : Hyprland.workspaces.values
          .filter(w => w.id > 0)
          .sort((a, b) => a.id - b.id)
          .map(w => ({ id: w.id, name: w.name,
                       focused: w.focused, urgent: w.urgent }))

  function focusWorkspace(id) {
    if (Shoji.active)
      Shoji.activate(root.monitorName, id)
    else
      Hyprland.dispatch("hl.dsp.focus({workspace=" + id + "})")
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6

    Repeater {
      model: root.wsModel

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
          onClicked: root.focusWorkspace(ws.modelData.id)
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
        text: ""  // nf-fa-magic
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
