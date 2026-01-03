import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../../theme"

PanelWindow {
    id: popupWindow
    
    anchors.top: true
    anchors.right: true
    width: 300
    margins.top: 0   
    height: backgroundSurface.height

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.None
    color: "transparent"

    property bool revealed: false

    Connections {
        target: notificationModel
        function onCountChanged() {
            if (notificationModel.count > 0) popupWindow.revealed = true
        }
    }
    
    visible: revealed || backgroundSurface.y > -(backgroundSurface.height - 1)
    mask: backgroundSurface

    function removeNotification(notificationObject, force = false) {
         var index = -1;
         for (var i = 0; i < notificationModel.count; i++) {
             if (notificationModel.get(i).notif === notificationObject) {
                 index = i;
                 break;
             }
         }
         if (index === -1) return;

         if (notificationModel.count === 1) {
             // Slide whole window for last item
             popupWindow.revealed = false;
             var t = Qt.createQmlObject('import QtQuick; Timer {interval: 350; running: true;}', popupWindow);
             t.triggered.connect(function() {
                 if (notificationModel.count > 0) notificationModel.remove(index);
                 t.destroy();
             });
         } else if (force) {
             // Only remove if we've already finished the shrink animation
             notificationModel.remove(index);
         }
     }

    Item {
        anchors.fill: parent
        clip: true 

        Rectangle {
            id: backgroundSurface
            width: parent.width
            height: layout.implicitHeight

            // This animates the container size when an item inside shrinks
            Behavior on height {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
            }
		
            y: popupWindow.revealed ? 0 : -height
            
            Behavior on y {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
            }

            color: Theme.background
            radius: 8
            
            Rectangle {
                id: topfill
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 15
                color: Theme.background 
                radius: 0
            }

            ColumnLayout {
                id: layout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top 
                spacing: 0

                Repeater {
                    model: notificationModel
                    delegate: Item { 
                        id: delegateItem
                        Layout.fillWidth: true
                        
                        // Start at 60, but we will animate this to 0
                        implicitHeight: 60 

                        Behavior on implicitHeight {
                            NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
                        }

                        // Helper to trigger the local shrink then the model removal
                        function startDismissal() {
                            if (notificationModel.count > 1) {
                                delegateItem.implicitHeight = 0;
                                var t = Qt.createQmlObject('import QtQuick; Timer {interval: 310; running: true;}', delegateItem);
                                t.triggered.connect(function() {
                                    popupWindow.removeNotification(model.notif, true);
                                    t.destroy();
                                });
                            } else {
                                popupWindow.removeNotification(model.notif);
                            }
                        }

                        Connections {
                            target: model.notif
                            function onClosed() { delegateItem.startDismissal(); }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                model.notif.dismiss();
                                delegateItem.startDismissal();
                            }
                        }
                       
                        // Divider
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width * 0.9
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 1
                            color: Theme.empty
                            visible: index < notificationModel.count - 1 && delegateItem.implicitHeight > 0
                        }

                        // Wrap content in an Item to clip it as it shrinks
                        Item {
                            anchors.fill: parent
                            clip: true
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                
                                Image {
                                    source: model.notif.image || "dialog-information"
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Text { 
                                        text: model.notif.summary 
                                        color: Theme.accent
                                        font.bold: true 
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Text { 
                                        text: model.notif.body 
                                        color: Theme.text
                                        elide: Text.ElideRight 
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }

                        Timer {
                            interval: (model.notif.timeout > 0) ? model.notif.timeout : 5000
                            running: true
                            onTriggered: {
                                model.notif.dismiss();
                                delegateItem.startDismissal();
                            }
                        }
                    }
                }
            }
        }
    }
}

