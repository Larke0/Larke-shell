import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"

Row {
    id: selectorRoot
    spacing: 5

    property int wsOffset: 0
    property var kanjiMap: [] 

    Repeater {
        model: 10
        Text {
            property int wsID: index + 1 + selectorRoot.wsOffset
            property var ws: Hyprland.workspaces.values.find(w => w.id === wsID)
            property bool isActive: Hyprland.focusedWorkspace?.id === wsID

            text: selectorRoot.kanjiMap[index]

            color: isActive ? Theme.accent : (ws ? Theme.occupied : Theme.empty)
            font { family: "Noto Sans CJK JP"; pixelSize: 18; bold: false }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + parent.wsID)
            }
        }
    }
}
