import QtQuick
import Quickshell.Services.Pipewire

Text {
  id: volText
  anchors.verticalCenter: parent.verticalCenter
  font.pixelSize: 13
  font.bold: true
  font.family: "JetBrainsMono Nerd Font"

  property var sink: Pipewire.defaultAudioSink
  property var audio: sink && sink.ready ? sink.audio : null
  property int vol: audio ? Math.round(audio.volume * 100) : 0
  property bool muted: audio ? audio.muted : false

  color: muted ? "#6c7689" : "#ffffff"

  property string icon: muted ? "\u{f075f}"
                      : vol >= 66 ? "\u{f057e}"
                      : vol >= 33 ? "\u{f0580}"
                      :             "\u{f057f}"
  text: icon + " " + vol + "%"

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

