import QtQuick
import Quickshell.Io

Text {
  anchors.verticalCenter: parent.verticalCenter
  font.pixelSize: 13
  font.bold: true
  font.family: "JetBrainsMono Nerd Font"

  // sysfs を1秒ごとにリロード
  FileView { id: batCap;    path: "/sys/class/power_supply/BAT0/capacity" }
  FileView { id: batStatus; path: "/sys/class/power_supply/BAT0/status" }
  Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: { batCap.reload(); batStatus.reload() }
  }

  property int pct: parseInt(batCap.text()) || 0
  property string st: batStatus.text().trim()
  property bool charging: st === "Charging" || st === "Full"

  color: charging ? "#7ebae4" : (pct <= 15 ? "#ff5555" : (pct <= 30 ? "#f1fa8c" : "#ffffff"))

  property string icon: pct >= 90 ? ""
                      : pct >= 70 ? ""
                      : pct >= 50 ? ""
                      : pct >= 30 ? ""
                      :             ""

  text: icon + " " + pct + "%" + (charging ? "+" : "")
}
