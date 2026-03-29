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
