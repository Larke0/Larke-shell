import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    

    // Re-load the font here to keep the component self-contained
    FontLoader {
        id: clockFont
        source: "../fonts/MyHappyEndingRegular-Lx7G.ttf"
    }

    function updateTime() {
        var now = new Date();
        timeLabel.text = Qt.formatTime(now, "hh:mm");
        dateLabel.text = Qt.formatDate(now, "dddd, MMMM d");
    }

    Timer {
        interval: 1000 // Update every second
        running: true
        repeat: true
        onTriggered: root.updateTime()
    }

    // Run once on startup to set immediate time
    Component.onCompleted: root.updateTime()

    Rectangle {
            id: backgroundBox
            
            // Dynamic Size: Content size + Padding
            width: layout.implicitWidth + 80  // 40px padding on left/right
            height: layout.implicitHeight + 40 // 20px padding on top/bottom
            
            anchors.centerIn: parent
    
            color: "#000000"
            radius: 60
            border.color: Theme.accent
            border.width: 2

	    ColumnLayout {
	        id: layout
	        anchors.centerIn: parent
	        spacing: -15 // Tighten the gap between time and date

	        Text {
	            id: timeLabel
	            text: "00:00"
	            
	            color: Theme.accent

				style: Text.Outline
	            styleColor: "#000000" // Black border
	            
	            font.family: clockFont.name
	            font.pixelSize: 150
	            font.bold: false
	            
	            // Center text if the font is monospaced (rare for cartoons, but good practice)
	            Layout.alignment: Qt.AlignHCenter
	        }

	        Text {
	            id: dateLabel
	            text: "Monday, January 1"
	            
	            color: Theme.accent
				font.bold: false
				
				style: Text.Outline
	            styleColor: "#000000"
	            
	            font.family: clockFont.name
	            font.pixelSize: 40
	            Layout.alignment: Qt.AlignHCenter
	        }
	    }
   	}
}
