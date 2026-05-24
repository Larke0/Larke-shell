import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../../theme"

PanelWindow {
    required property var menu

    anchors.top:   true
    anchors.right: true
    implicitWidth:  menu.notchDepth * 2  // extra room for the curve to live in
    implicitHeight: menu.panelHeight
    color: "transparent"

    Shape {
        id: theShape
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor:   Theme.background
            strokeColor: "transparent"

            startX: 0; startY: 0

            // Top-left corner curve inward
            PathQuad {
                controlX: menu.notchDepth; controlY: 0
                x:        menu.notchDepth
                y:        menu.notchRadius
            }

            // Inner wall ↓
            PathLine {
                x: menu.notchDepth
                y: theShape.height - menu.notchRadius
            }

            // Bottom-left corner curve back out
            PathQuad {
                controlX: menu.notchDepth; controlY: theShape.height
                x:        0
                y:        theShape.height
            }

            // Bottom edge →
            PathLine { x: theShape.width; y: theShape.height }

            // Right edge ↑
            PathLine { x: theShape.width; y: 0 }

            // Back to start
            PathLine { x: 0; y: 0 }
        }
    }
}
