import QtQuick
import Quickshell.Io

// CPU / メモリ使用率ピル
// /proc/stat は前回サンプルとの差分から使用率を出す
Rectangle {
  id: root
  anchors.verticalCenter: parent.verticalCenter
  width: row.width + 20
  height: 22
  radius: 11
  color: "#5514171f"

  property real cpu: 0   // 0-100
  property real mem: 0   // 0-100
  property var prev: null

  FileView { id: statFile; path: "/proc/stat" }
  FileView { id: memFile;  path: "/proc/meminfo" }

  Timer {
    interval: 2000; running: true; repeat: true
    onTriggered: { statFile.reload(); memFile.reload(); root.update() }
  }

  function update() {
    const stat = statFile.text()
    const mi = memFile.text()
    if (!stat || !mi) return

    // "cpu  user nice system idle iowait irq softirq steal ..."
    const f = stat.split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
    const total = f.reduce((a, b) => a + b, 0)
    const idle = f[3] + f[4]
    if (prev !== null) {
      const dt = total - prev[0]
      if (dt > 0) cpu = 100 * (1 - (idle - prev[1]) / dt)
    }
    prev = [total, idle]

    const tot = parseInt((mi.match(/MemTotal:\s+(\d+)/) || [])[1])
    const avail = parseInt((mi.match(/MemAvailable:\s+(\d+)/) || [])[1])
    if (tot > 0) mem = 100 * (1 - avail / tot)
  }

  function usageColor(v) {
    return v >= 85 ? "#ff5555" : v >= 60 ? "#f1fa8c" : "#ffffff"
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 10

    Row {
      spacing: 4
      anchors.verticalCenter: parent.verticalCenter
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰻠"
        color: "#a3b8d8"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: String(Math.round(root.cpu)).padStart(2, " ") + "%"
        color: root.usageColor(root.cpu)
        font.pixelSize: 13
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
      }
    }

    Row {
      spacing: 4
      anchors.verticalCenter: parent.verticalCenter
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰍛"
        color: "#a3b8d8"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: String(Math.round(root.mem)).padStart(2, " ") + "%"
        color: root.usageColor(root.mem)
        font.pixelSize: 13
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
      }
    }
  }
}
