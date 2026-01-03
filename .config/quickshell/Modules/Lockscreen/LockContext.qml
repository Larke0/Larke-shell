import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root
    signal unlocked()
    
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (currentText === "") return;
        root.unlockInProgress = true;
        pam.start(); // Begin PAM authentication
    }

    PamContext {
        id: pam
        // Note: You can use your system's default login config
        config: "login" 

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText); // Send the typed password to PAM
            }
        }

        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked(); // Trigger success signal
            } else {
                root.currentText = "";
                root.showFailure = true; // Show error message
            }
            root.unlockInProgress = false;
        }
    }
}
