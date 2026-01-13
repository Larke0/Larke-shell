import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Wayland
import "../../theme" // Import your theme for colors

PanelWindow {
    id: root
	mask: content
    property var modelData
    screen: modelData
    visible: revealed || content.y > -(content.height - 1)


    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
	

    property bool revealed: false
    property real animatedMargin: revealed ? 30 : -10


	Behavior on animatedMargin {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic // Starts fast, slows down at the end
        }
    }
	
    anchors {
        top: true
    }
    margins { 
        top: 30
    }
    
    implicitWidth: 200
    implicitHeight: 40
    color: "transparent"

	property real volume: 0
	property bool isMuted: false

	property bool startup: true


    Process {
         id: wpctl
         command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
 
         stdout: StdioCollector {
             onStreamFinished: {
                 const text = this.text.trim()

 
                 // Logic 1: Check Mute Status
                 root.isMuted = text.includes("MUTED")
 
                 // Logic 2: Extract the number
                 const match = text.match(/([0-9.]+)/)
                 if (match && match[1]) {
                     root.volume = parseFloat(match[1])
                 }
             }
         }
     }

	Timer {
	        interval: 500
	        running: true
	        repeat: false
	        onTriggered: root.startup = false
	}

    Timer {
        interval: 200 // Check every 200ms
        running: true
        repeat: true
        onTriggered: wpctl.running = true
    }
  

    // Timer: Hide the OSD after 2 seconds of inactivity
    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.revealed = false
    }

   onVolumeChanged: {
   		if (!root.startup){
		    root.revealed = true
		    hideTimer.restart()
		}
	}

	onIsMutedChanged: {
		if (!root.startup){
		    root.revealed = true
		    hideTimer.restart()
		}
	}
    // --- VISUALS ---
    
    Item {
       anchors.fill: parent
       clip: true 

       Rectangle {
           id: content
           width: parent.width
           height: parent.height
           
           // The Animation Logic
           // If revealed: y = 0 (visible)
           // If hidden: y = -height (slide UP out of view)
           y: root.revealed ? 0 : -height
           
           Behavior on y {
               NumberAnimation {
                   duration: 250
                   easing.type: Easing.OutQuart
               }
           }

           // Visual Styling
           color: Theme.background
           radius: 10
           border.color: "transparent"
           border.width: 0


           Rectangle {
               id: topfill
               anchors.top: parent.top
               anchors.left: parent.left
               anchors.right: parent.right
               height: 20 
               color: Theme.background // Match background, not black, for seamless look
               radius: 0
           }

           RowLayout {
               anchors.fill: parent
               anchors.margins: 6
               spacing: 5
               
               Text {
                   text: root.isMuted ? "󰝟" : "󰕾"
                   font.family: "JetBrainsMono Nerd Font"
                   font.pixelSize: 20
                   color: Theme.text
               }

               Rectangle {
                   Layout.fillWidth: true
                   height: 6
                   color: Theme.empty 
                   radius: 3

                   Rectangle {
                       width: parent.width * root.volume
                       height: parent.height
                       color: root.isMuted ? Theme.empty : Theme.accent
                       radius: 3
                       Behavior on width { NumberAnimation { duration: 100 } }
                   }
               }

               Text {
                   text: Math.round(root.volume * 100) + "%"
                   font.family: "JetBrainsMono Nerd Font"
                   color: Theme.text
                   Layout.preferredWidth: 25
                   horizontalAlignment: Text.AlignRight
               }
           }
       }
   }
}


