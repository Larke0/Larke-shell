import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../theme"

Rectangle {
    id: root
    required property var context
    color: "#000000"
    focus: true

	

    property string wallpaperPath: ""
        
       
    Process {
    	id: awww
	    running: true
	    command: ["/bin/bash", "-c", "/usr/bin/awww query | awk -F 'image: ' '{print $2}' | head -n 1"]
	           
	    stdout: StdioCollector {
	      onStreamFinished: {
               console.log(`line read: ${this.text}`)
               wallpaperPath = this.text.trim()
               console.log(`Wallpaper path set to: ${wallpaperPath}`)
           }		
	    }
    }

    Image {
        id: background
        anchors.fill: parent
        source: root.wallpaperPath ? "file://" + root.wallpaperPath : ""
        
        fillMode: Image.PreserveAspectCrop
        asynchronous: false // Load immediately
        cache: true         // Keep in memory for faster subsequent locks
        
        // Matches the image to the screen resolution for faster decoding
        sourceSize.width: parent.width
        sourceSize.height: parent.height
    
        // Smoothly fade in once loaded
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 400 }
        }
    }

    ClockWidget {
	     id: mainClock
	     anchors.centerIn: parent
	     anchors.verticalCenterOffset: 200
	}
    
    Component.onCompleted: root.forceActiveFocus()

    // Handle all typing here
    Keys.onPressed: function(event) {
        if (root.context.unlockInProgress) return;

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.context.tryUnlock();
        } else if (event.key === Qt.Key_Backspace) {
            root.context.currentText = root.context.currentText.slice(0, -1);
        } else if (event.text.length > 0) {
            root.context.currentText += event.text;
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        spacing: 20

 		Text {
		    visible: root.context.showFailure
		    text: "Incorrect password"
		    color: "#f38ba8"
		    Layout.alignment: Qt.AlignHCenter 
		}
        // Use the custom component
        PasswordInput {
            text: root.context.currentText
            unlockInProgress: root.context.unlockInProgress
        }
    }
}
