import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"

Row {
    id: selectorRoot
    spacing: 5 // Adjust this number to make buttons closer (e.g., 2) or wider

    // Define properties to receive data from TopBar
    property int wsOffset: 0
    property var kanjiMap: [] 

    Repeater {
        model: 10
        Text {
            // Use 'selectorRoot' to access the properties defined above
            property int wsID: index + 1 + selectorRoot.wsOffset
            property var ws: Hyprland.workspaces.values.find(w => w.id === wsID)
            property bool isActive: Hyprland.focusedWorkspace?.id === wsID

            text: selectorRoot.kanjiMap[index]

            color: isActive ? Theme.accent : (ws ? Theme.occupied : Theme.empty)
            font { pixelSize: 18; bold: true }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + parent.wsID)
            }
        }
    }
}
