import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../../theme"



Image {
	id: rootQuickMenuButton
    source: Theme.logoPath
    Layout.preferredHeight: 20
    Layout.preferredWidth: 20
    fillMode: Image.PreserveAspectFit
    Layout.leftMargin: 5

	required property var rootTopBar

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
           // quickMenu.toggle()
           quickMenu.open()
        }
    }

    QuickMenu{
    	id: quickMenu
    	anchorWindow: rootTopBar

    	visible: false
    }
}
