import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

// コントロールセンター: バー右端の  ボタン → ポップアップ
// Wi-Fi/サウンドのトグル + 輝度/音量スライダー
// 輝度は logind の SetBrightness (busctl) で root 不要に書く
Item {
  id: root
  anchors.verticalCenter: parent.verticalCenter
  width: 26
  height: parent ? parent.height : 32

  property var audio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.ready
      ? Pipewire.defaultAudioSink.audio : null

  // --- user@host / uptime ---
  FileView { id: hostFile; path: "/etc/hostname" }
  FileView { id: upFile;   path: "/proc/uptime" }
  Timer {
    interval: 60000; repeat: true
    running: popup.visible
    onTriggered: upFile.reload()
  }
  property string userHost:
      Quickshell.env("USER") + "@" + hostFile.text().trim()
  property string uptime: {
    const s = parseFloat(upFile.text()) || 0
    const d = Math.floor(s / 86400)
    const h = Math.floor(s % 86400 / 3600)
    const m = Math.floor(s % 3600 / 60)
    return (d > 0 ? d + "d " : "") + h + "h " + m + "m"
  }

  // --- Wi-Fi 状態 (nmcli) ---
  property bool wifiOn: false
  Process {
    id: wifiCheck
    command: ["nmcli", "radio", "wifi"]
    stdout: StdioCollector {
      id: wifiOut
      onStreamFinished: root.wifiOn = wifiOut.text.trim() === "enabled"
    }
  }
  Timer { id: wifiRecheck; interval: 800; onTriggered: wifiCheck.running = true }
  function setWifi(on) {
    Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"])
    wifiOn = on  // 楽観更新、あとで実状態を確認
    wifiRecheck.restart()
  }

  // --- 輝度 (sysfs 読み / logind 書き) ---
  readonly property string blDev: "amdgpu_bl1"
  FileView { id: briCur; path: "/sys/class/backlight/" + blDev + "/brightness" }
  FileView { id: briMax; path: "/sys/class/backlight/" + blDev + "/max_brightness" }
  property int briMaxV: parseInt(briMax.text()) || 1
  property real bri: (parseInt(briCur.text()) || 0) / briMaxV
  property real briDrag: -1   // ドラッグ中の表示値 (-1 = 非ドラッグ)
  property bool briDirty: false

  function applyBri() {
    if (!briDirty || briDrag < 0) return
    briDirty = false
    Quickshell.execDetached(["busctl", "call",
      "org.freedesktop.login1", "/org/freedesktop/login1/session/auto",
      "org.freedesktop.login1.Session", "SetBrightness",
      "ssu", "backlight", blDev,
      String(Math.round(Math.max(0.01, briDrag) * briMaxV))])
  }
  // ドラッグ中は100msごとに間引いて書く (busctl連打防止)
  Timer {
    interval: 100; repeat: true
    running: root.briDrag >= 0
    onTriggered: root.applyBri()
  }
  Timer {
    id: briClear
    interval: 400
    onTriggered: { briCur.reload(); root.briDrag = -1 }
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
      text: "󰒓"
      color: popup.visible ? "#7ebae4" : ma.containsMouse ? "#7ebae4" : "#a3b8d8"
      font.pixelSize: 13
      font.family: "JetBrainsMono Nerd Font"

      Behavior on color { ColorAnimation { duration: 150 } }
    }
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.togglePopup()
  }

  function togglePopup() {
    if (!popup.visible) {
      wifiCheck.running = true
      briCur.reload()
      upFile.reload()
    }
    popup.visible = !popup.visible
  }

  // --- スライダー部品 ---
  component CcSlider: Item {
    id: s
    property string icon: ""
    property real value: 0     // 0-1
    signal moved(real v)
    signal endDrag()
    width: 246
    height: 24

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: s.icon
      color: "#a3b8d8"
      font.pixelSize: 15
      font.family: "JetBrainsMono Nerd Font"
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: Math.round(s.value * 100) + "%"
      color: "#6c7689"
      font.pixelSize: 10
      font.family: "JetBrainsMono Nerd Font"
    }

    Item {
      id: trackArea
      anchors.left: parent.left
      anchors.leftMargin: 28
      anchors.right: parent.right
      anchors.rightMargin: 38
      height: parent.height

      Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: "#336c7689"

        Rectangle {
          width: track.width * Math.max(0, Math.min(1, s.value))
          height: parent.height
          radius: 2
          color: "#7ebae4"
        }
      }

      Rectangle {
        x: track.width * Math.max(0, Math.min(1, s.value)) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 12; height: 12; radius: 6
        color: "#d2d9e8"
      }

      MouseArea {
        anchors.fill: parent
        onPressed: mouse => s.moved(Math.max(0, Math.min(1, mouse.x / width)))
        onPositionChanged: mouse => s.moved(Math.max(0, Math.min(1, mouse.x / width)))
        onReleased: s.endDrag()
      }
    }
  }

  // --- トグルボタン部品 ---
  component CcToggle: Rectangle {
    id: t
    property string icon: ""
    property string label: ""
    property bool on: false
    signal clicked()
    width: 119
    height: 40
    radius: 10
    color: on ? "#7ebae4" : tma.containsMouse ? "#446c7689" : "#226c7689"

    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
      anchors.centerIn: parent
      spacing: 8
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: t.icon
        color: t.on ? "#14171f" : "#a3b8d8"
        font.pixelSize: 16
        font.family: "JetBrainsMono Nerd Font"
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: t.label
        color: t.on ? "#14171f" : "#a3b8d8"
        font.pixelSize: 12
        font.bold: t.on
        font.family: "JetBrainsMono Nerd Font"
      }
    }

    MouseArea {
      id: tma
      anchors.fill: parent
      hoverEnabled: true
      onClicked: t.clicked()
    }
  }

  // --- ポップアップ ---
  PopupWindow {
    id: popup
    visible: false
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    implicitWidth: 290
    implicitHeight: panel.height + 16
    color: "transparent"

    Rectangle {
      id: panel
      anchors.horizontalCenter: parent.horizontalCenter
      y: popup.visible ? 8 : -height - 8
      width: 290
      height: col.height + 32
      radius: 12
      color: "#f014171f"
      border.color: "#336c7689"
      border.width: 1
      opacity: popup.visible ? 1 : 0

      Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
      Behavior on opacity { NumberAnimation { duration: 200 } }

      Column {
        id: col
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        // --- ヘッダー: アバター (fastfetchロゴ) + user@host + uptime ---
        Row {
          spacing: 12

          Item {
            width: 48; height: 48

            Image {
              id: avatar
              anchors.fill: parent
              source: "file://" + Quickshell.env("HOME") + "/.config/fastfetch/logo.jpg"
              sourceSize: Qt.size(96, 96)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              visible: false
            }

            MultiEffect {
              anchors.fill: avatar
              source: avatar
              maskEnabled: true
              maskSource: avatarMask
              maskThresholdMin: 0.5
              maskSpreadAtMin: 1.0
              visible: avatar.status === Image.Ready
            }

            Rectangle {
              id: avatarMask
              anchors.fill: avatar
              radius: width / 2
              layer.enabled: true
              visible: false
            }

            // 画像が無いときのフォールバック
            Rectangle {
              anchors.fill: parent
              radius: width / 2
              color: "#226c7689"
              visible: avatar.status !== Image.Ready
              Text {
                anchors.centerIn: parent
                text: ""
                color: "#7ebae4"
                font.pixelSize: 24
                font.family: "JetBrainsMono Nerd Font"
              }
            }
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
              text: root.userHost
              color: "#ffffff"
              font.pixelSize: 14
              font.bold: true
              font.family: "JetBrainsMono Nerd Font"
            }

            Row {
              spacing: 5
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅐"
                color: "#6c7689"
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "up " + root.uptime
                color: "#a3b8d8"
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
              }
            }
          }
        }

        // 区切り線
        Rectangle {
          width: 246; height: 1
          color: "#226c7689"
        }

        Row {
          spacing: 8

          CcToggle {
            icon: on ? "󰤨" : "󰤭"
            label: "Wi-Fi"
            on: root.wifiOn
            onClicked: root.setWifi(!root.wifiOn)
          }

          CcToggle {
            icon: on ? "󰕾" : "󰝟"
            label: "Sound"
            on: root.audio ? !root.audio.muted : false
            onClicked: if (root.audio) root.audio.muted = !root.audio.muted
          }
        }

        CcSlider {
          icon: "󰃞"
          value: root.briDrag >= 0 ? root.briDrag : root.bri
          onMoved: v => {
            root.briDrag = v
            root.briDirty = true
          }
          onEndDrag: {
            root.applyBri()
            briClear.restart()
          }
        }

        CcSlider {
          icon: "󰕾"
          value: root.audio ? root.audio.volume : 0
          onMoved: v => {
            if (!root.audio) return
            root.audio.volume = v
            if (root.audio.muted) root.audio.muted = false
          }
        }
      }
    }
  }

  // qs ipc call control toggle (キーバインド用)
  IpcHandler {
    target: "control"
    function toggle(): void { root.togglePopup() }
  }

  HyprlandFocusGrab {
    active: popup.visible
    windows: [popup]
    onCleared: popup.visible = false
  }
}
