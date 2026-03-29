import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../../theme"

PanelWindow {
    id: popupWindow
    
    anchors.top: true
    anchors.right: true
    implicitWidth: 300
    implicitHeight: backgroundSurface.height
    margins.top: 0   
    
    

    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"

    property bool revealed: false
    property var modelData

    Connections {
        target: notificationModel
        function onCountChanged() {
            if (notificationModel.count > 0) {
                popupWindow.revealed = true;
            } else if (notificationModel.count === 0) {
                popupWindow.revealed = false;
            }
        }
    }
    
    visible: revealed || backgroundSurface.y > -(backgroundSurface.height - 1)


    Item {
        anchors.fill: parent
        clip: true 

        Rectangle {
            id: backgroundSurface
            width: parent.width
            height: layout.height

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
            ListView {
                id: layout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                
                height: contentHeight

                model: notificationModel


                remove: Transition {
                    NumberAnimation { 
                        property: "height"
                        to: 0
                        duration: 300
                        easing.type: Easing.OutCubic 
                    }
                }

                delegate: Item{
                    id: delegateItem
                    width: ListView.view.width
                    height: 60

                    Connections {
                        target: model.notif
                        function onClosed() {
                            notificationModel.remove(index);
                        }
                    }


                    Timer {
                        interval: (model.notif.timeout > 0) ? model.notif.timeout : 5000
                        running: true
                        onTriggered: {
                            model.notif.dismiss();
                            notificationModel.remove(delegateItem.index);
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("Notification clicked, Number of actions: " + model.notif.actions.length)
                            let defaultActionFound = false;
                            for (let i=0; i < model.notif.actions.length; i++){
                                let action = model.notif.actions[i]
                                

                                console.log("Found action [" + i + "]: identifier='" + action.identifier + "', text='" + action.text + "'");
                                if(action.identifier == "default"){
                                    console.log("Default action matched! Invoking...");
                                    action.invoke();
                                    defaultActionFound = true;
                                    break;
                                }
                            }
                            model.notif.dismiss();
                            notificationModel.remove(delegateItem.index);
                        }
                    }


                    //Appearence
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                         Image {
                                    source: model.notif.image || "dialog-information"
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    fillMode: Image.PreserveAspectCrop
                        }
                        ColumnLayout {
                            spacing: 2
                            Text { 
                                text: model.notif.summary 
                                color: Theme.accent
                                font.bold: true 
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pixelSize: 12
                            }
                            Text { 
                                text: model.notif.body 
                                color: Theme.text
                                elide: Text.ElideRight 
                                Layout.fillWidth: true
                                font.pixelSize: 12
                            }
                        }                        
                    }
                }
            }
            
        }
    }
}

