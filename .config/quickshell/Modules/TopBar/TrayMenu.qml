import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: trayMenuRoot
    property var menuHandle
    
    implicitWidth: 200
    implicitHeight: trayMenu.implicitHeight + 20
    color: Theme.background
    radius: 8

    QsMenuOpener {
        id: opener
        menu: trayMenuRoot.menuHandle
    }

    ColumnLayout {
        id: trayMenu
        anchors.fill: parent
        anchors.margins: 10
        spacing: 1

        Repeater {
            model: opener.children
            delegate: ColumnLayout {
                Layout.fillWidth: true
                
                Rectangle {
                    visible: modelData.isSeparator
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.empty
                }
                
                Rectangle {
                    visible: !modelData.isSeparator
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    color: itemMouse.containsMouse ? Theme.accent : "transparent"

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if (modelData.enabled) modelData.trigger()
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 5

                        Image {
                            source: modelData.icon
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                        }

                        Text {
                            text: modelData.text
                            color: itemMouse.containsMouse ? Theme.background : Theme.accent
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        
                    }
                }
            }
        }
    }
}
