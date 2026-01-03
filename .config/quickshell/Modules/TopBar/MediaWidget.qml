import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "../../theme"

RowLayout {
    id: mediaRoot
    spacing: 8

    // --- STATE ---
    property var trackTitle: "No Media"
    property var trackArtist: ""
    property bool isPlaying: false
    property bool hasPlayer: false
    
    // We store the actual player object here so we can control it later
    property var activePlayerObject: null
    
    // Remembers the name of the last app
    property string lastActiveIdentity: ""

    // --- LOGIC: The Smart Selector ---
    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var pList = Array.from(Mpris.players.values);
            var winner = null;
            var foundPlaying = false;

            // 1. Search for a player that is CURRENTLY PLAYING
            for (var i = 0; i < pList.length; i++) {
                var p = pList[i];
                if (p.playbackState === 1) { 
                    winner = p;
                    foundPlaying = true;
                    parent.lastActiveIdentity = p.identity;
                    break;
                }
            }

            // 2. Fallback to Last Active
            if (!foundPlaying && parent.lastActiveIdentity !== "") {
                for (var j = 0; j < pList.length; j++) {
                    if (pList[j].identity === parent.lastActiveIdentity) {
                        winner = pList[j];
                        break;
                    }
                }
            }

            // 3. Update the UI
            if (winner) {
                parent.hasPlayer = true;
                parent.isPlaying = foundPlaying;
                parent.activePlayerObject = winner; // Store the object for the MouseArea
                
                parent.trackTitle = winner.metadata["xesam:title"];
                parent.trackArtist = winner.metadata["xesam:artist"];
            } else {
                parent.hasPlayer = false;
                parent.activePlayerObject = null;
            }
        }
    }

    // --- VISUALS ---
    visible: hasPlayer

    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onPressed: (mouse) => {
            if (!mediaRoot.activePlayerObject) return;

            console.log("Button Pressed ID:", mouse.button);

            if (mouse.button === Qt.LeftButton) {
                // LEFT CLICK: Play/Pause
                mediaRoot.activePlayerObject.togglePlaying();
            } 
            else if (mouse.button === Qt.RightButton) {
                 mediaRoot.activePlayerObject.next();
             }
             else if (mouse.button === Qt.MiddleButton) {
                 mediaRoot.activePlayerObject.previous();
            }
        }
    }

    // 1. Icon
    Text {
        text: "" 
        color: mediaRoot.isPlaying ? Theme.accent : Theme.empty
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
    }

    // 2. Title
    Text {
        text: (mediaRoot.trackTitle || "Unknown") + ""
        color: mediaRoot.isPlaying ? Theme.accent_down : Theme.empty
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 14; bold: true }
        elide: Text.ElideRight
        Layout.maximumWidth: 300
    }

    // 3. Artist
    Text {
        text: mediaRoot.trackArtist ? ("- " + mediaRoot.trackArtist) : ""
        color: mediaRoot.isPlaying ? Theme.accent_down : Theme.empty
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 }
        visible: text.length > 2
        elide: Text.ElideRight
        Layout.maximumWidth: 300 
    }
}
