import QtQuick
import QtQuick.Layouts
import "../../theme"

RowLayout {
    spacing: 10 // Space between Time and Date (if you enable both)

    // --- LOGIC ---
    property var currentDate: new Date()

    Timer {
        interval: 1000 // Update every 1000ms (1 second)
        running: true
        repeat: true
        onTriggered: parent.currentDate = new Date()
    }

    // --- VISUALS ---
    
    // The Time
    Text {
        text: Qt.formatDateTime(parent.currentDate, "hh:mm")
        
        color: Theme.accent 
        font { 
            pixelSize: 16
            bold: true
            family: "JetBrainsMono Nerd Font" // Or your preferred font
        }
    }

    // 2. The Date
    Text {
        // "MMM dd" = Short Month + Day (e.g., Dec 30)
        text: Qt.formatDateTime(parent.currentDate, "MMM dd")
        
        color: Theme.accent
        font { 
            pixelSize: 16
            bold: true
            family: "JetBrainsMono Nerd Font"
        }
    }
}

