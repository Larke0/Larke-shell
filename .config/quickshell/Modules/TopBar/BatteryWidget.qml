import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../theme"

Item {
  id: batteryRoot
  implicitWidth: hasBattery ? batteryRow.implicitWidth : 0
  implicitHeight: hasBattery ? batteryRow.implicitHeight : 0
  visible: hasBattery

  property bool hasBattery: false
  property int percent: 0
  property string status: "Unknown"
  property bool charging: status === "Charging" || status === "Full"

  property string iconText: {
    if (charging) return "󰂄";
    if (percent >= 90) return "󰁹";
    if (percent >= 80) return "󰂂";
    if (percent >= 70) return "󰂁";
    if (percent >= 60) return "󰂀";
    if (percent >= 50) return "󰁿";
    if (percent >= 40) return "󰁾";
    if (percent >= 30) return "󰁽";
    if (percent >= 20) return "󰁼";
    if (percent >= 10) return "󰁻";
    return "󰁺";
  }

  property color batteryColor: {
    if (charging) return Theme.accent;
    if (percent <= 10) return "#ff4444";
    if (percent <= 20) return "#ff8844";
    return Theme.accent;
  }

  FileView {
    id: capacityFile
    path: "/sys/class/power_supply/BAT1/capacity"
    onLoaded: {
        let val = parseInt(text().trim())
        if (!isNaN(val)) {
            batteryRoot.hasBattery = true
            batteryRoot.percent = val
        }
    }
    onLoadFailed: {
        batteryRoot.hasBattery = false
        batteryTimer.running = false  // stop polling entirely
    }
}

FileView {
    id: statusFile
    path: "/sys/class/power_supply/BAT1/status"
    onLoaded: batteryRoot.status = text().trim()
    onLoadFailed: {}  // silently ignore — no battery
}

Timer {
    id: batteryTimer
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
        capacityFile.reload()
        statusFile.reload()
    }
}
Item {
    id: batteryRow
    implicitWidth: hoverHandler.hovered ? batteryIcon.width + percentText.width + 4 : batteryIcon.width
    implicitHeight: batteryIcon.height

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    Text {
        id: batteryIcon
        text: batteryRoot.iconText
        color: batteryRoot.batteryColor
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 20; bold: true }
        anchors.left: parent.left
    }

    HoverHandler {
        id: hoverHandler
    }

    Text {
        id: percentText
        text: batteryRoot.percent + "%"
        color: batteryRoot.batteryColor
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; bold: true }
        anchors.left: batteryIcon.right
        anchors.leftMargin: 4
        anchors.verticalCenter: batteryIcon.verticalCenter
        opacity: hoverHandler.hovered ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
    }
}
}
