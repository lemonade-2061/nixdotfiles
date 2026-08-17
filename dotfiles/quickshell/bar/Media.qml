import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../shoji"
import Quickshell.Services.Mpris

// Spotify (MPRIS) ナウプレイング + クリックでプレイヤーポップアップ
Item {
  id: root
  anchors.verticalCenter: parent.verticalCenter
  // shell.qml から渡される上限幅 (時計にぶつからない範囲)
  property real maxWidth: 300
  width: Math.min(icon.implicitWidth + 6 + title.implicitWidth + 20, maxWidth)
  height: parent ? parent.height : 32
  visible: player !== null

  // Spotify優先、なければ他のMPRISプレイヤー
  property var player: {
    const list = Mpris.players.values
    return list.find(p => (p.identity || "").toLowerCase().includes("spotify"))
        ?? (list.length > 0 ? list[0] : null)
  }

  property string song: player
      ? (player.trackTitle || "---") + (player.trackArtist ? " - " + player.trackArtist : "")
      : ""

  // ピル: [󰝚 曲名 - アーティスト] 収まらないぶんは "…" で省略
  Rectangle {
    id: pill
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 22
    radius: 11
    color: popup.visible ? "#556c7689"
         : ma.containsMouse ? "#886c7689"
         : "#5514171f"

    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
      id: icon
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      color: popup.visible ? "#7ebae4" : "#a3b8d8"
      font.pixelSize: 13
      font.bold: true
      font.family: "JetBrainsMono Nerd Font"
      text: "󰝚"

      Behavior on color { ColorAnimation { duration: 150 } }
    }

    // 収まらないときはマーキー (往復スクロール)
    Item {
      id: clipBox
      anchors.left: icon.right
      anchors.leftMargin: 6
      anchors.right: parent.right
      anchors.rightMargin: 10
      height: parent.height
      clip: true

      readonly property bool overflow: title.implicitWidth > width
      onOverflowChanged: title.x = 0

      Text {
        id: title
        anchors.verticalCenter: parent.verticalCenter
        color: popup.visible ? "#7ebae4" : "#ffffff"
        font.pixelSize: 13
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        text: root.song

        Behavior on color { ColorAnimation { duration: 150 } }
      }

      SequentialAnimation {
        id: marquee
        running: clipBox.overflow && root.visible
        loops: Animation.Infinite
        PauseAnimation { duration: 2500 }
        NumberAnimation {
          target: title; property: "x"
          to: clipBox.width - title.implicitWidth
          duration: Math.max(1000, (title.implicitWidth - clipBox.width) * 40)
        }
        PauseAnimation { duration: 2500 }
        NumberAnimation { target: title; property: "x"; to: 0; duration: 800; easing.type: Easing.InOutQuad }
      }

      // 曲が変わったら先頭から
      Connections {
        target: root
        function onSongChanged() {
          title.x = 0
          if (marquee.running) marquee.restart()
        }
      }
    }
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    onClicked: popup.visible = !popup.visible
  }

  // 表示中だけ1秒ごとに再生位置を更新 (positionはシグナルを発火させて再読込する仕様)
  Timer {
    interval: 1000; repeat: true
    running: popup.visible && root.player !== null && root.player.isPlaying
    onTriggered: root.player.positionChanged()
  }

  PopupWindow {
    id: popup
    visible: false
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    // 画面右端からはみ出さないようクランプ (Shoji.popupShiftX 参照)
    anchor.rect.x: popup.visible
      ? Shoji.popupShiftX(root, root.QsWindow.window, popup.implicitWidth)
      : 0
    implicitWidth: 290
    implicitHeight: panel.height + 16
    color: "transparent"

    Rectangle {
      id: panel
      anchors.horizontalCenter: parent.horizontalCenter
      // バーの下からニュルンと出す
      y: popup.visible ? 8 : -height - 8
      width: 290
      height: col.height + 30
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
        spacing: 10

        // --- アルバムアート ---
        Item {
          width: 246; height: 246
          anchors.horizontalCenter: parent.horizontalCenter

          Image {
            id: art
            anchors.fill: parent
            source: root.player ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
          }

          MultiEffect {
            anchors.fill: art
            source: art
            maskEnabled: true
            maskSource: artMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            visible: art.status === Image.Ready
          }

          Rectangle {
            id: artMask
            anchors.fill: art
            radius: 10
            layer.enabled: true
            visible: false
          }

          // アート未取得時のプレースホルダ
          Rectangle {
            anchors.fill: parent
            radius: 10
            color: "#226c7689"
            visible: art.status !== Image.Ready
            Text {
              anchors.centerIn: parent
              text: "󰝚"
              color: "#6c7689"
              font.pixelSize: 64
              font.family: "JetBrainsMono Nerd Font"
            }
          }
        }

        // --- 曲名 / アーティスト ---
        Text {
          width: 246
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.player ? (root.player.trackTitle || "---") : ""
          color: "#ffffff"
          font.pixelSize: 14
          font.bold: true
          font.family: "JetBrainsMono Nerd Font"
          elide: Text.ElideRight
          horizontalAlignment: Text.AlignHCenter
        }
        Text {
          width: 246
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.player ? root.player.trackArtist : ""
          color: "#a3b8d8"
          font.pixelSize: 12
          font.family: "JetBrainsMono Nerd Font"
          elide: Text.ElideRight
          horizontalAlignment: Text.AlignHCenter
        }

        // --- シークバー + 時間 ---
        Item {
          width: 246; height: 28
          anchors.horizontalCenter: parent.horizontalCenter

          function fmt(s) {
            s = Math.max(0, Math.floor(s))
            return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
          }

          Rectangle {
            id: track
            anchors.top: parent.top
            anchors.topMargin: 4
            width: parent.width; height: 4; radius: 2
            color: "#336c7689"

            Rectangle {
              width: root.player && root.player.length > 0
                   ? track.width * Math.min(1, root.player.position / root.player.length)
                   : 0
              height: parent.height; radius: 2
              color: "#7ebae4"
            }
          }

          MouseArea {
            anchors.top: parent.top
            width: parent.width; height: 14
            onClicked: mouse => {
              if (root.player && root.player.canSeek && root.player.length > 0)
                root.player.position = (mouse.x / width) * root.player.length
            }
          }

          Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: root.player ? parent.fmt(root.player.position) : ""
            color: "#6c7689"
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
          }
          Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: root.player && root.player.lengthSupported ? parent.fmt(root.player.length) : ""
            color: "#6c7689"
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
          }
        }

        // --- コントロール ---
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 20

          Item {
            width: 44; height: 44
            Rectangle {
              anchors.centerIn: parent
              width: 36; height: 36; radius: 18
              color: prevMa.containsMouse ? "#446c7689" : "transparent"
              Text {
                anchors.centerIn: parent
                text: "󰒮"
                color: "#d2d9e8"
                font.pixelSize: 20
                font.family: "JetBrainsMono Nerd Font"
              }
            }
            MouseArea {
              id: prevMa
              anchors.fill: parent
              hoverEnabled: true
              onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
            }
          }

          Item {
            width: 44; height: 44
            Rectangle {
              anchors.fill: parent
              radius: 22
              color: playMa.containsMouse ? "#a3b8d8" : "#7ebae4"

              // フォントグリフは中心がズレるので図形で描く
              Shape {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 2  // 三角の見た目の重心補正
                width: 15; height: 18
                visible: !(root.player && root.player.isPlaying)
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                  strokeWidth: -1
                  fillColor: "#14171f"
                  startX: 0; startY: 0
                  PathLine { x: 15; y: 9 }
                  PathLine { x: 0; y: 18 }
                  PathLine { x: 0; y: 0 }
                }
              }
              Row {
                anchors.centerIn: parent
                spacing: 5
                visible: root.player !== null && root.player.isPlaying
                Rectangle { width: 5; height: 16; radius: 2; color: "#14171f" }
                Rectangle { width: 5; height: 16; radius: 2; color: "#14171f" }
              }

              Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
              id: playMa
              anchors.fill: parent
              hoverEnabled: true
              onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
            }
          }

          Item {
            width: 44; height: 44
            Rectangle {
              anchors.centerIn: parent
              width: 36; height: 36; radius: 18
              color: nextMa.containsMouse ? "#446c7689" : "transparent"
              Text {
                anchors.centerIn: parent
                text: "󰒭"
                color: "#d2d9e8"
                font.pixelSize: 20
                font.family: "JetBrainsMono Nerd Font"
              }
            }
            MouseArea {
              id: nextMa
              anchors.fill: parent
              hoverEnabled: true
              onClicked: if (root.player && root.player.canGoNext) root.player.next()
            }
          }
        }
      }
    }
  }

  // qs ipc call media toggle でポップアップ開閉 (キーバインド用にも使える)
  IpcHandler {
    target: "media"
    function toggle(): void { popup.visible = !popup.visible }
  }

  PopupGrab {
    active: popup.visible
    windows: [popup]
    onCleared: popup.visible = false
  }
}
