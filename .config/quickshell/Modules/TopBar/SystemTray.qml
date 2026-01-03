import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../theme"

RowLayout {
    spacing: 8
    id: systemTray

    property var parentWindow

    Repeater {
        model: SystemTray.items

        Item {
        	id: trayItem
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20

            QsMenuAnchor {
            	id: trayMenu
            	menu: modelData.menu

				anchor {
     		        window: parentWindow
     		        // Initialize with 0, but we will update this before opening
     		        rect: Qt.rect(0, 0, 0, 0)
     		    }
            }

            Image {
                anchors.fill: parent
                source: modelData.icon
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        // 1. Try standard DBus activation
                        modelData.activate();
                    } 
                    else if (mouse.button === Qt.RightButton) {
                        // Try to trigger the secondary menu action
                        var coords = trayItem.mapToItem(parentWindow.contentItem, 0, 0);
						console.log("App:", modelData.title, "Has Menu:", modelData.hasMenu, "Handle:", modelData.menu);

						var visualBottom = parentWindow.height + parentWindow.margins.bottom;
						// Update the anchor rect
		                trayMenu.anchor.rect = Qt.rect(coords.x, visualBottom, trayItem.width, 0);
		                
		                // Now open the menu
                        if (modelData.hasMenu) {
                            trayMenu.open();
                        }
                    }
                }
            }
        }
    }
}

