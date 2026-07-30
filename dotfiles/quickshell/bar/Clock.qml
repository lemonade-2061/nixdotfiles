import QtQuick

Text {
  id: clock
  anchors.centerIn: parent
  color: "#ffffff"
  font.pixelSize: 13
  font.family: "JetBrainsMono Nerd Font"
  font.bold: true

  property var now: new Date()
  text: Qt.formatDateTime(now, "<-- yy-ddd -| HH:mm |- MM-dd --> ")

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: clock.now = new Date()
  }
}


