import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root
    signal unlocked()
    
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: showFailure = false // Reset error when typing [cite: 67]

    function tryUnlock() {
        if (currentText === "") return;
        root.unlockInProgress = true;
        pam.start(); // Begin PAM authentication [cite: 68]
    }

    PamContext {
        id: pam
        // Note: You can use your system's default login config
        config: "login" 

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText); // Send the typed password to PAM [cite: 70]
            }
        }

        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked(); // Trigger success signal [cite: 71]
            } else {
                root.currentText = "";
                root.showFailure = true; // Show error message [cite: 71]
            }
            root.unlockInProgress = false;
        }
    }
}
