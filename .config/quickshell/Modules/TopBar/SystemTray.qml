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

          

			property bool isFcitx: modelData.id.toLowerCase().includes("fcitx")    
	        // Hide and remove from layout if it's Fcitx
	        visible: !isFcitx
        	
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

            // Sanitize the incoming icon data
            property string cleanIcon: {
                // Ensure we are working with a string
                let rawSource = modelData.icon ? modelData.icon.toString() : "";
                
                // 1. The Spotify Hard-Override
                // 'spotify-linux-32' rarely exists in standard themes. 
                // We force it to ask for the standard 'spotify' icon instead.
                if (modelData.id.toLowerCase() === "spotify-client") {
                    return "image://icon/com.spotify.Client"; 
                }
                
                // 2. The Universal Fix (Helps Steam and others)
                // If any app sends an unsupported '?path=' parameter, chop it off.
                // "image://icon/steam_tray_mono?path=/home/..." becomes "image://icon/steam_tray_mono"
                if (rawSource.includes("?path=")) {
                    return rawSource.split("?")[0];
                }
                
                // 3. Normal apps pass through untouched
                return rawSource;
            }

            Image {
                anchors.fill: parent
                // Feed the sanitized string to the image component
                source: cleanIcon
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

