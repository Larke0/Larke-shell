import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../../theme"

Row {
    id: selectorRoot
    spacing: 5

    property int wsOffset: 0
    property var kanjiMap: [] 

    Repeater {
        model: 10
        Text {
            id: kanjiBtn 
            
            property int wsID: index + 1 + selectorRoot.wsOffset
            property var ws: Hyprland.workspaces.values.find(w => w.id === wsID)
            property bool isActive: Hyprland.focusedWorkspace?.id === wsID

            text: selectorRoot.kanjiMap[index]
            color: isActive ? Theme.accent : (ws ? Theme.occupied : Theme.empty)
            font { family: "Noto Sans CJK JP"; pixelSize: 18; bold: false }

            Behavior on opacity { NumberAnimation { duration: 100 } }

            // Creates a raw shell process instance for this specific button
            Process {
                id: scriptRunner
                
                // sh -c executes the entire string exactly as if you typed it in Kitty
                command: [
                    "sh", 
                    "-c", 
                    "~/.config/hypr/scripts/monitor_ws.sh workspace " + kanjiBtn.wsID
                ]
              }

            MouseArea {
                anchors.fill: parent
                
                onPressed: kanjiBtn.opacity = 0.3
                onReleased: kanjiBtn.opacity = 1.0

                onClicked: {
                    console.log("Triggering script for workspace: " + kanjiBtn.wsID)
                    
                    // Reset the process state and trigger it
                    scriptRunner.running = false
                    scriptRunner.running = true
                }
              }        
          }
    }
}
