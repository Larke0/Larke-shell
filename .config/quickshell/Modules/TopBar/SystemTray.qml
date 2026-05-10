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

    // First repeater: everything except fcitx and nm-applet
    Repeater {
        model: SystemTray.items

        Item {
            id: trayItem

            property string itemId: modelData.id.toLowerCase()
            visible: !itemId.includes("fcitx") && itemId !== "nm-applet"

            Layout.preferredWidth: 20
            Layout.preferredHeight: 20

            QsMenuAnchor {
                id: trayMenu
                menu: modelData.menu
                anchor {
                    window: parentWindow
                    rect: Qt.rect(0, 0, 0, 0)
                }
            }

            property string cleanIcon: {
                let rawSource = modelData.icon ? modelData.icon.toString() : "";

                // Spotify: force standard icon
                if (itemId === "spotify-client") {
                    return "file:///run/current-system/sw/share/icons/Papirus-Dark/32x32/apps/spotify.svg";
                }

                // Strip unsupported '?path=' params (Steam, etc.)
                if (rawSource.includes("?path=")) {
                    return rawSource.split("?")[0];
                }

                return rawSource;
            }

            Component.onCompleted: {
                console.log("=== TRAY ITEM DETECTED ===");
                console.log("ID:", itemId);
                console.log("Raw Icon:", modelData.icon ? modelData.icon.toString() : "None");
            }

            Image {
                anchors.fill: parent
                source: cleanIcon
                sourceSize: Qt.size(parent.width, parent.height)
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate();
                    } else if (mouse.button === Qt.RightButton) {
                        var coords = trayItem.mapToItem(parentWindow.contentItem, 0, 0);
                        var visualBottom = parentWindow.height + parentWindow.margins.bottom;
                        trayMenu.anchor.rect = Qt.rect(coords.x, visualBottom, trayItem.width, 0);
                        if (modelData.hasMenu) {
                            trayMenu.open();
                        }
                    }
                }
            }
        }
    }

    // Second repeater: nm-applet always last
    Repeater {
        model: SystemTray.items

        Item {
            id: nmTrayItem

            property string itemId: modelData.id.toLowerCase()
            visible: itemId === "nm-applet"

            Layout.preferredWidth: 20
            Layout.preferredHeight: 20

            QsMenuAnchor {
                id: nmTrayMenu
                menu: modelData.menu
                anchor {
                    window: parentWindow
                    rect: Qt.rect(0, 0, 0, 0)
                }
            }

            property string cleanIcon: {
                let raw = modelData.icon ? modelData.icon.toString() : "";
                let iconName = raw.replace("image://icon/", "");
                let mapping = {
                    "nm-signal-100": "network-wireless-signal-excellent",
                    "nm-signal-75": "network-wireless-signal-good",
                    "nm-signal-50": "network-wireless-signal-ok",
                    "nm-signal-25": "network-wireless-signal-low",
                    "nm-signal-00": "network-wireless-signal-none",
                    "nm-no-connection": "network-wireless-offline"
                };
                let mapped = mapping[iconName] || "network-wireless-signal-excellent";
                return "file:///run/current-system/sw/share/icons/Papirus-Dark/16x16/panel/" + mapped + ".svg";
            }

            Image {
                anchors.fill: parent
                source: cleanIcon
                sourceSize: Qt.size(parent.width, parent.height)
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate();
                    } else if (mouse.button === Qt.RightButton) {
                        var coords = nmTrayItem.mapToItem(parentWindow.contentItem, 0, 0);
                        var visualBottom = parentWindow.height + parentWindow.margins.bottom;
                        nmTrayMenu.anchor.rect = Qt.rect(coords.x, visualBottom, nmTrayItem.width, 0);
                        if (modelData.hasMenu) {
                            nmTrayMenu.open();
                        }
                    }
                }
            }
        }
    }
}
