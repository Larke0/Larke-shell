import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: control
    implicitWidth: 600
    implicitHeight: 100


    FontLoader {
        id: meganbats
        // "../" means "go up to the parent folder" (quickshell)
        // then go into "fonts"
        source: "../fonts/Meganbats-rr9x.ttf"
        
        onStatusChanged: {
            if (meganbats.status === FontLoader.Error)
                console.error("Still failing! Path tried: " + source)
        }
    }

    FontLoader {
        id: myhappyending
        // "../" means "go up to the parent folder" (quickshell)
        // then go into "fonts"
        source: "../fonts/MyHappyEndingRegular-Lx7G.ttf"
        
        onStatusChanged: {
            if (myhappyending.status === FontLoader.Error)
                console.error("Still failing! Path tried: " + source)
        }
    }
        
    
    property string text: ""
    property bool unlockInProgress: false

    // 1. The Model: Stores the dots
    ListModel { 
        id: dotsModel 
    }

    onTextChanged: {
        // Define all the characters that produce good shapes in your font
        var validChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

        // If typing: Pick a random char from validChars
        while (dotsModel.count < control.text.length) {
            var randomIndex = Math.floor(Math.random() * validChars.length);
            var randomChar = validChars.charAt(randomIndex);
            
            dotsModel.append({ "assignedIcon": randomChar }); 
        }

        // If deleting: Remove the last one
        while (dotsModel.count > control.text.length) {
            dotsModel.remove(dotsModel.count - 1);
        }
    }

    Rectangle {
        id: inputBg
        anchors.fill: parent
        color: Theme.background
        radius: 60
        border.color: root.context.showFailure ? "#f38ba8" : "#0db9d7"
        border.width: 2

        // Shake Animation on Error
        SequentialAnimation {
            id: shakeAnim
            running: root.context.showFailure
            loops: 1
            NumberAnimation { target: inputBg; property: "x"; from: 0; to: -10; duration: 50 }
            NumberAnimation { target: inputBg; property: "x"; from: -10; to: 10; duration: 50 }
            NumberAnimation { target: inputBg; property: "x"; from: 10; to: -10; duration: 50 }
            NumberAnimation { target: inputBg; property: "x"; from: -10; to: 0; duration: 50 }
        }

        // 3. The View: Displays the dots
        ListView {
            id: dotList
            anchors.fill: parent
            header: Item { width: 30; height: dotList.height }
            footer: Item { width: 30; height: dotList.height }
            orientation: ListView.Horizontal
            interactive: false
            spacing: 18

            clip: true

            onCountChanged: {
                Qt.callLater(positionViewAtEnd)
            }
            
            model: dotsModel

            // The Dot Component
            delegate: Item {
                width: 60
                height: dotList.height
                
                Text {
                    id: dotText
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 8
                    text: assignedIcon
                    color: Theme.accent
                    font.family: meganbats.name
                    font.pixelSize: 75
                }
            }

            // 4. The Transitions (Controlled Animations)
            
            // Animation for NEW dots only (Spin In)
            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
                    NumberAnimation { property: "scale"; from: 0; to: 1; duration: 150 }
                    NumberAnimation { 
                        property: "rotation"
                        from: -180
                        to: 0
                        duration: 200
                        easing.type: Easing.OutBack
                    }
                }
            }

            // Animation for DELETED dots (Shrink Out)
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: 150 }
                    NumberAnimation { property: "scale"; to: 0; duration: 150 }
                }
            }
        }

        // Placeholder Text
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 35
            anchors.verticalCenter: parent.verticalCenter
            text: "Type Password..."
            color: Theme.accent_down
            font.pixelSize: 45
            font.family: myhappyending.name
            visible: control.text.length === 0
        }
        
        // Loading Overlay
        Rectangle {
            anchors.fill: parent
            color: "#80000000"
            visible: control.unlockInProgress
            radius: 8
        }
    }
}
