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
    property var numberMap: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    
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
        anchors.right: wsSelector.left
        anchors.top: parent.top
        height: 31
        anchors.leftMargin: 5
        anchors.rightMargin: 20
        spacing: 10

        QuickMenuButton{
        	rootTopBar: root
        }


        Text {
            color: Theme.accent
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 ;  bold: true}
            text: Hyprland.activeToplevel && Hyprland.activeToplevel.wayland ? Hyprland.activeToplevel.title : ""
            Layout.maximumWidth: 450 
            elide: Text.ElideRight
        }
        
        Item {
            Layout.fillWidth: true
        }
    }
   
    
    WorkspaceSelector {
        id: wsSelector
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
        anchors.left: wsSelector.right
        height: 31
        anchors.rightMargin: 15
        anchors.leftMargin: 15
        
        

         Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            MediaWidget {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                Layout.maximumWidth: 450 
                Layout.fillHeight: true
            }
        }

        SystemTray {
            Layout.rightMargin: 10
            parentWindow: root
        }
        
        Clock { }
    }
}
