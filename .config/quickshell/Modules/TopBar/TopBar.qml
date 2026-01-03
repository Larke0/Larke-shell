import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../../theme"

PanelWindow {
    id: root
    property var modelData
    screen: modelData


	WlrLayershell.layer: WlrLayer.Top

    
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 45

    margins {
            bottom: -15
    }
    
    color: "transparent"
    
    // --- CUSTOMIZATION SETTINGS ---
    property int notchWidth: 1900  // width of the flat center
    property int notchHeight: 15 // depth of the cutout
    property int notchRadius: 10 // corner roundness
    
    // --- LOGIC ---
    property var hMonitor: Hyprland.monitors.values.find(m => m.name === root.screen.name)
    property int currentWs: hMonitor ? hMonitor.activeWorkspace.id : 1
    property int wsOffset: Math.floor((currentWs - 1) / 10) * 10
    property var kanjiMap: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    
    // --- BACKGROUND SHAPE ---
    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4 
        
        ShapePath {
            fillColor: Theme.background
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
    
            // 1. Define the main bar area (Outer Rectangle)
            PathMove { x: 0; y: 0 }
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: 0 }
    
            // 2. Define the rounded cutout at the bottom center
            // Jump to the start of the notch (Left Side)
            PathMove { 
                x: (root.width / 2) - (notchWidth / 2) - notchRadius
                y: root.height 
            }
            
            // Left curve going up into the bar
            PathArc { 
                x: (root.width / 2) - (notchWidth / 2)
                y: root.height - notchHeight
                radiusX: notchRadius
                radiusY: notchRadius 
            }
            
            // Flat line across the top of the notch
            PathLine { 
                x: (root.width / 2) + (notchWidth / 2)
                y: root.height - notchHeight 
            }
            
            // Right curve going back down to the bottom edge
            PathArc { 
                x: (root.width / 2) + (notchWidth / 2) + notchRadius
                y: root.height
                radiusX: notchRadius
                radiusY: notchRadius 
            }
        }
    }
    
    // --- CONTENT ---
    RowLayout {
        anchors.left: parent.left
        anchors.top: parent.top
        height: 31
        anchors.leftMargin: 5
        spacing: 10
        
        Image {
            source: Theme.logoPath
            Layout.preferredHeight: 25
            Layout.preferredWidth: 25
            fillMode: Image.PreserveAspectFit
            Layout.leftMargin: 5
        }
        
        MediaWidget {
            Layout.maximumWidth: 450 
        }
    }
    
    WorkspaceSelector {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: (45 / 2) - (height / 2) -8 // Centers
        wsOffset: root.wsOffset
        kanjiMap: root.kanjiMap
        z: 10
    }
    
    RowLayout {
        anchors.right: parent.right
        anchors.top: parent.top
        height: 31
        anchors.rightMargin: 15
        
        SystemTray {
            Layout.rightMargin: 10
            parentWindow: root
        }
        
        Clock { }
    }
}
