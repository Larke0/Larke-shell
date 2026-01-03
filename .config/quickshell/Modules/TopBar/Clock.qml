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
    
    // 1. The Time (Bold and Big)
    Text {
        // "hh:mm" = 24h format (e.g., 14:30)
        // "h:mm AP" = 12h format (e.g., 2:30 PM)
        text: Qt.formatDateTime(parent.currentDate, "hh:mm")
        
        color: "#cdd6f4" // Catppuccin Text
        font { 
            pixelSize: 20
            bold: true
            family: "JetBrainsMono Nerd Font" // Or your preferred font
        }
    }

    // 2. The Date (Optional - Smaller and softer color)
    Text {
        // "MMM dd" = Short Month + Day (e.g., Dec 30)
        text: Qt.formatDateTime(parent.currentDate, "MMM dd")
        
        color: "#bac2de" // Catppuccin Subtext
        font { 
            pixelSize: 18
            bold: true
            family: "JetBrainsMono Nerd Font"
        }
    }
}

