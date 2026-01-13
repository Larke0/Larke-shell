//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import Quickshell.Services.Notifications

import "Modules/TopBar"
import "Modules/Notifications"
import "Modules/Lockscreen"
import "Modules/OSD"


ShellRoot {
    id: shellRoot
    property bool isLocked: false

   property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""

   onFocusedMonitorNameChanged: {
        //console.log(">> SYSTEM UPDATE: Focused Monitor is now:", focusedMonitorName)
    }

    


    NotificationServer {
        id: notificationServer
        onNotification: (notification) => {
        	notification.tracked = true;
        	//console.log("Current Focused Monitor:", Quickshell.Hyprland.focusedMonitor.name);
            notificationModel.append({ "notif": notification });
        }
    }

    ListModel {
        id: notificationModel
    }
    
    
	
    // Matches bind = ..., global, quickshell:lock
    GlobalShortcut {
        name: "lock"
        onPressed: shellRoot.isLocked = true
    }

    

    Variants {
        model: Quickshell.screens
        delegate: NotificationPopups {
            screen: modelData
            /*Component.onCompleted: {]
                
                console.log("--- Debugging Popup ---")
                console.log("My Screen:", modelData.name)
                console.log("Active Screen:", shellRoot.focusedMonitorName)
                
                // Check if the objects match
                console.log("Direct Match:", modelData === Quickshell.screens.current)
                
                // Check if names match (often safer)
                console.log("Name Match:", Quickshell.screens.current && modelData.name === Quickshell.screens.current.name)
            }*/
            visible: notificationModel.count > 0 && (modelData.name === shellRoot.focusedMonitorName)
        }
    }

    Variants {
            model: Quickshell.screens
            delegate: TopBar {
                screen: modelData
            }
   	}

   	Variants {
            model: Quickshell.screens
            delegate: VolumeOSD {
                modelData: modelData
            }
   	}
    

    LockContext {
        id: lockContext
        onUnlocked: {
            shellRoot.isLocked = false; 
            currentText = ""; 
        }
    }

    WlSessionLock {
        id: lock
        locked: shellRoot.isLocked 

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext 
            }
        }
    }
}
