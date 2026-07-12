import QtQuick
import QtQuick.Layouts
import QtCore 
import Quickshell.Services.SystemTray as QsTray
import "../../theme"

MouseArea {
    id: trayHoverContainer
    
    property var parentWindow

    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight
    
    hoverEnabled: true
    propagateComposedEvents: true

    onExited: {
        if (trayRoot.isExpanded) {
            autoHideTimer.restart();
        }
    }

    onEntered: {
        autoHideTimer.stop();
    }

    RowLayout {
        id: trayRoot
        anchors.fill: parent
        spacing: 6

        property bool isExpanded: false

        // Persistent storage for your pinned item IDs
        Settings {
            id: traySettings
            category: "SystemTray"
            property var pinnedList: ["network", "nm-applet", "volume", "wireplumber"]
        }

        function isPinned(appId) {
            return traySettings.pinnedList.includes(appId);
        }

        function togglePin(appId) {
            var current = Array.from(traySettings.pinnedList);
            var index = current.indexOf(appId);
            if (index > -1) {
                current.splice(index, 1);
            } else {
                current.push(appId);
            }
            traySettings.pinnedList = current;
        }

        // ==========================================
        // AUTOMATIC COLLAPSE TIMER (3 SECONDS)
        // ==========================================
        Timer {
            id: autoHideTimer
            interval: 3000
            repeat: false
            onTriggered: trayRoot.isExpanded = false
        }

        // --- INTERNAL CORE LAYOUT ---
        RowLayout {
            id: mainLayout
            spacing: 6

            // ==========================================
            // 1. LEFT SIDE: UNPINNED / OVERFLOW ICONS
            // ==========================================
            Item {
                id: overflowContainer
                Layout.preferredWidth: trayRoot.isExpanded ? overflowTrayRow.implicitWidth : 0
                Layout.fillHeight: true
                clip: true 

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                }

                RowLayout {
                    id: overflowTrayRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: QsTray.SystemTray.items
                        
                        delegate: Rectangle {
                            id: unpinnedIconWrapper
                            property bool shouldShow: !trayRoot.isPinned(modelData.id)
                            
                            visible: shouldShow
                            width: shouldShow ? 22 : 0
                            height: shouldShow ? 22 : 0
                            color: "transparent"

                            // --- RIGHT-TO-LEFT STAGGERED FADE ---
                            // Opacity targets 1.0 when expanded. When collapsing, drops immediately to avoid awkward delays.
                            opacity: trayRoot.isExpanded ? 1.0 : 0.0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            // Use an event handler to inject the precise right-to-left delay cleanly
                            onOpacityChanged: {
                                if (trayRoot.isExpanded && opacity === 1.0) {
                                    // Let QML compute the stagger window cleanly without property double-sets
                                    var staggerDelay = Math.max(0, (overflowRepeater.count - 1 - index) * 45);
                                }
                              }


                            Image {
                                anchors.fill: parent
                                source: modelData.icon
                                fillMode: Image.PreserveAspectFit
                            }

                            MouseArea {
                                id: unpinnedIconMouse
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        trayRoot.togglePin(modelData.id);
                                    } else if (mouse.button === Qt.RightButton) {
                                        if (modelData.hasMenu) {
                                            var windowPos = mapToItem(trayHoverContainer.parentWindow.contentItem, mouse.x, mouse.y);
                                            modelData.display(trayHoverContainer.parentWindow, windowPos.x, windowPos.y);
                                        } else {
                                            trayRoot.togglePin(modelData.id);
                                        }
                                    } else {
                                        modelData.activate();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // 2. CENTER: THE WINDOWS-STYLE FLIPPING ARROW
            // ==========================================
            Rectangle {
                id: expandButton
                width: 16
                height: 24
                color: "transparent"
                
                Text {
                    id: arrowText
                    anchors.centerIn: parent
                    text: "◀"
                    color: Theme.accent
                    font.pixelSize: 12

                    opacity: trayRoot.isExpanded ? 1.0 : 0.4

                    Behavior on opacity {
                        NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        trayRoot.isExpanded = !trayRoot.isExpanded;
                        autoHideTimer.stop(); 
                    }
                }
            }

            // ==========================================
            // 3. RIGHT SIDE: ALWAYS VISIBLE PINNED ICONS
            // ==========================================
            RowLayout {
                id: pinnedTrayRow
                spacing: 6

                Repeater {
                    model: QsTray.SystemTray.items
                    
                    delegate: Rectangle {
                        id: pinnedIconWrapper
                        property bool shouldShow: trayRoot.isPinned(modelData.id)
                        
                        visible: shouldShow
                        width: shouldShow ? 22 : 0
                        height: shouldShow ? 22 : 0
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            source: modelData.icon
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            id: pinnedIconMouse
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.MiddleButton) {
                                    trayRoot.togglePin(modelData.id);
                                } else if (mouse.button === Qt.RightButton) {
                                    if (modelData.hasMenu) {
                                        var windowPos = mapToItem(trayHoverContainer.parentWindow.contentItem, mouse.x, mouse.y);
                                        modelData.display(trayHoverContainer.parentWindow, windowPos.x, windowPos.y);
                                    } else {
                                        trayRoot.togglePin(modelData.id);
                                    }
                                } else {
                                    modelData.activate();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
