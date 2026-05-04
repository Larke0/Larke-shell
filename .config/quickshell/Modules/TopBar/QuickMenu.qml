import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../../theme"

PanelWindow {
  id: rootMainMenu
  required property var anchorWindow

  Process {
      id: wpctlSetter
      command: ["wpctl", "set-default"]
  }

  // Global State
  property var audioDeviceNames: []
  property var audioDeviceMap: ({})
  property string currentDefaultSink: ""

    Process {
        id: powerAction
        // We use 'sh -c' so we can pass any full command string
        command: ["sh", "-c", "true"] 
    }
  
  Process {
      id: pwDumper
      command: ["pw-dump"]
      
      stdout: StdioCollector {
          onStreamFinished: {
              let output = this.text.trim();
              if (output.length === 0) return;
  
              try {
                  let data = JSON.parse(output);
                  let names = [];
                  let mapping = {};
                  let defaultNodeName = ""; 
  
                  // 1. Find the metadata object (Targeting the system name like "alsa_output...")
                  let metadata = data.find(obj => obj.type === "PipeWire:Interface:Metadata" && obj.props && obj.props["metadata.name"] === "default");
                  
                  if (metadata && metadata.metadata) {
                       let defaultEntry = metadata.metadata.find(m => m.key === "default.audio.sink");
                       if (defaultEntry && defaultEntry.value && defaultEntry.value.name) {
                           defaultNodeName = defaultEntry.value.name;
                       }
                  }
  
                  // 2. Filter for Audio Sinks
                  let sinks = data.filter(obj => 
                      obj.info && 
                      obj.info.props && 
                      obj.info.props["media.class"] === "Audio/Sink"
                  );
  
                  sinks.forEach(sink => {
                      let id = sink.id;
                      let description = sink.info.props["node.description"] || "Unknown Device";
                      let systemName = sink.info.props["node.name"];
                      
                      names.push(description);
                      mapping[description] = id;
  
                      // Match the system name to find our "friendly" default
                      if (systemName === defaultNodeName) {
                          rootMainMenu.currentDefaultSink = description;
                      }
                  });
  
                  // --- NEW: Print Final Results to Console ---
                  console.log("---------------------------------")
                  console.log("ACTIVE DEFAULT:", rootMainMenu.currentDefaultSink)
                  console.log("ALL DEVICES:", JSON.stringify(names))
                  console.log("---------------------------------")
  
                  // 3. Update Global Properties
                  if (names.length > 0) {
                      rootMainMenu.audioDeviceNames = [...names];
                      rootMainMenu.audioDeviceMap = mapping;
                  }
  
              } catch (e) {
                  console.error("Error parsing pw-dump JSON:", e);
              }
          }
      }
  }
  
  // Trigger refresh when menu opens
  onIsOpenChanged: {
      if (isOpen) {
          pwDumper.running = true
          // Start the delay timer
          focusTimer.start()
      } else {
          pwDumper.running = false
          // specific cleanup
          focusTimer.stop()
          rootMainMenu.focusActive = false
      }
  }

  anchors.top: true
  anchors.left: true
  implicitWidth: 300
  implicitHeight: 1050
  color: "transparent"
  visible: true

    
  property bool isOpen: false
  function open() {
      isOpen = true
  }

  function close() {
      //visible = false
      isOpen = false
  }

  function toggle() {
      if (isOpen) close()
      else open()
  }

    component SysButton: Rectangle {
        id: btn
        property string name: "Action"
        property string cmd: ""
        property string baseColor: Theme.empty
        property string hoverColor:  Theme.accent
        
        property int btnWidth: 80
        property int btnHeight: 50

        property var font
        property var font_size
    
        Layout.preferredWidth: btnWidth
        Layout.preferredHeight: btnHeight
        radius: 100
        color: mouse.containsMouse ? btn.hoverColor : btn.baseColor
    
        // Smooth color change
        Behavior on color { ColorAnimation { duration: 150 } }
    
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                console.log("Running system command:", btn.cmd)
                powerAction.command = ["sh", "-c", btn.cmd]
                powerAction.running = true
                rootMainMenu.close()
            }
        }
    
        Text {
            anchors.centerIn: parent
            text: btn.name
            color: mouse.containsMouse ? "#1e1e2e" : "white"
            font.bold: true
            font.family: btn.font
            font.pixelSize: btn.font_size
        }
    }    

  
    component QuickToggle: Rectangle {
        id: toggle
        property string name: "Unknown"
        property bool active: false
        property var font
        property int font_size
        

        // Button sizes
        Layout.preferredWidth: 120
        Layout.preferredHeight: 60
        
        radius: 100

        color: active ? Theme.accent : Theme.empty

        // Smooth color change
        Behavior on color { ColorAnimation { duration: 150 } }

        // Simple click interaction
        MouseArea {
            anchors.fill: parent
            onClicked: toggle.active = !toggle.active
        }

        // Icon / Label
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            
            Text {
                text: toggle.name
                color: toggle.active ? "black" : "white"
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
                font.family: toggle.font
                font.pixelSize: toggle.font_size
            }
        }      
    }


    component ListSelector: ColumnLayout {
        id: selector
        property string name: "Select Option"
        property var option: ["Option 1", "Option 2", "Option 3"]
        property string selected: option[0]
        property bool expanded: false
        property int buttons_height: 50
        property int buttons_spacing: 5
        property int font_size: 14
        property int font_size_name: selector.font_size
        property int animation_duration: 300 
        
        signal itemSelected(string item)
        
        spacing: buttons_spacing
        implicitWidth: 280
        
        // --- 1. Main Button (Header) ---
        Rectangle {
            Layout.fillWidth: true // Fill the width of the component
            height: selector.buttons_height
            radius: 20
            color: Theme.secondary_accent

            RowLayout{
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                spacing: 5
                Text {
                    id: textName          
                    text: selector.name
                    color: "white"
                    font.bold: true
                    font.pixelSize: selector.font_size_name
                    elide: Text.ElideRight
                }

                Text {
                    
                    id: textSelected
                    text: selector.selected
                    color: "white"
                    font.bold: true
                    font.pixelSize: selector.font_size
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    id: arrowText
                    text: selector.expanded ? "▲" : "▼"
                    color: "gray"
                    font.pixelSize: selector.font_size
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: selector.expanded = !selector.expanded
            }
        }

        // --- 2. Expandable List Container ---
        Rectangle {
            id: listContainer
            Layout.fillWidth: true
            clip: true 
            color: "transparent"
            Layout.preferredHeight: height
            height: selector.expanded ? (selector.option.length * (selector.buttons_height + selector.buttons_spacing)) : 0

            Behavior on height {
                NumberAnimation {
                    duration: selector.animation_duration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                width: parent.width // Match the container width exactly
                spacing: selector.buttons_spacing

                Repeater {
                    model: selector.option
                    delegate: Rectangle {
                        Layout.fillWidth: true 
                        
                        height: selector.buttons_height
                        radius: 20
                        color: modelData === selector.selected ? Theme.accent : Theme.empty

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20 

                            text: modelData
                            color: modelData === selector.selected ? Theme.empty : Theme.accent
                            font.pixelSize: selector.font_size
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                selector.selected = modelData;
                                selector.expanded = false;
                                selector.itemSelected(modelData);
                            }
                        }
                    }
                }
            }
        }
    }


    component ListSlider: ColumnLayout {
        id: listSlider
    }

    property bool focusActive: false
    
    Timer {
        id: focusTimer
        interval: 200 // Wait 200ms before grabbing focus
        repeat: false
        onTriggered: {
            if (rootMainMenu.isOpen) {
                rootMainMenu.focusActive = true
            }
        }
    }


    HyprlandFocusGrab {
        windows: [rootMainMenu]
        active: rootMainMenu.focusActive
        onCleared: {
            // Logic: If user clicks outside, close immediately
            rootMainMenu.close()
        }
    }

    Timer {
        id: closeTimer
        interval: 10000 // 10000ms = 1 second
        repeat: false
        onTriggered: rootMainMenu.close()
    }


  //Visual Content
      Rectangle {
          anchors.fill: parent
          color: Theme.background
          radius: 0

            transform: Translate {
                id: slidePos
                x: -310 
            }
            
          //  Close on Mouse Exit
          // This component watches the mouse state for this rectangle
          HoverHandler {
              // "hovered" becomes true when mouse enters, false when it leaves
              onHoveredChanged: {
                  // If the mouse just left the window, close it
                  if (hovered) {
                      closeTimer.stop()
                  } else {
                      closeTimer.start()
                  }
              }
          }


          states: State {
              name: "open"
              when: rootMainMenu.isOpen // Trigger when window opens
              
              // Move to x: 0 (Normal position) and Opacity: 1 (Visible)
              PropertyChanges { target: slidePos; x: 0 }
          }
          
            transitions: [
                Transition {
                    from: "*"
                    to: "open"
                    SequentialAnimation {
                        ScriptAction {
                            script: rootMainMenu.visible = true
                        }
                        NumberAnimation {
                            target: slidePos
                            property: "x"
                            duration: 400 // Duration in milliseconds
                            easing.type: Easing.OutCubic // Starts fast, slows down at the end
                        }
                    }
                },

                Transition {
                    from: "open"
                    to: "*"
                    SequentialAnimation{
                        NumberAnimation {
                            target: slidePos
                            property: "x"
                            duration: 400 // Duration in milliseconds
                            easing.type: Easing.OutCubic // Starts fast, slows down at the end
                        }
                        ScriptAction {
                            script: rootMainMenu.visible = false
                        }
                    }
                }
            ]

          ColumnLayout{
              spacing: 10
              anchors {
                  top: parent.top
                  horizontalCenter: parent.horizontalCenter
                  margins: 10
                }


                // Qs Reload Button (Fixed icon, size, and command path)
                   SysButton {
                       name: "\udb82\udc14" // Nerd Font Reload/Refresh icon
                       font: "JetBrainsMono Nerd Font Propo"
                       font_size: 10      // Scaled down font size
                       btnWidth: 30       // Explicitly smaller width
                       btnHeight: 30      // Stays square
                       
                       // Swapped ~ for $HOME. sh -c often fails to expand ~ properly
                       cmd: "nohup $HOME/.local/bin/quickshell-reload > /dev/null 2>&1 &"
                   }
              
            width: parent.width
            id: quickMenu    

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                spacing: 15

                
                
                // Shutdown Button (Red accent)
                SysButton {
                    name: "\udb81\udc25"
                    font: "JetBrainsMono Nerd Font Propo"
                    font_size: 40
                    cmd: "systemctl poweroff"
                    //baseColor: "#453a40" // Slight reddish tint for safety
                    //hoverColor: "#f38ba8" // Catppuccin Red
                }
                

                // Reboot Button
                SysButton {
                    name: "\udb81\udf09"
                    font: "JetBrainsMono Nerd Font Propo"
                    font_size: 40
                    cmd: "systemctl reboot"
                }

                // Lock Button
                   SysButton {
                       name: "\udb80\udf3e"
                    font: "JetBrainsMono Nerd Font Propo"
                    font_size: 33
                       cmd: "sleep 0.3 && pidof hyprlock || hyprlock" // Prevents opening twice
                   }               
             }

             Rectangle {
                implicitHeight: 5
                Layout.fillWidth: true
                radius: 10
                color: Theme.accent_down
             }
              RowLayout{
                  id: quickButtons
                  spacing: 10
                Layout.alignment: Qt.AlignHCenter
                  Layout.fillWidth: true
                  

                // Wifi Button
                QuickToggle {
                    name: "\udb81\udda9"
                    font_size: 33
                }

                // Bluetooth Button
                QuickToggle {
                    name: "\udb80\udcaf"
                    font_size: 33
                }
                  
              }

              ListSelector {
                  id: audioOutputSelector
                  name: "\udb81\udcc3"
                  selected: rootMainMenu.currentDefaultSink
                  option: rootMainMenu.audioDeviceNames
                Layout.preferredWidth: 100
                  Layout.alignment: Qt.AlignHCenter
                  Layout.leftMargin: 8
                  Layout.rightMargin: 8
                font_size_name: 26
                font_size: 16


                  onItemSelected:  (item) => {
                      let id = rootMainMenu.audioDeviceMap[item];

                      if (id) {
                           console.log("Switching audio to:", item, "ID:", id);
                           wpctlSetter.command = ["wpctl", "set-default", id];
                           wpctlSetter.running = true;
                       } else {
                           console.warn("No ID found for selected device:", item);
                       }
                  }
                  
              }


             AnimatedImage {
                 source: "/home/larke/.config/quickshell/assets/ado-dancing3.gif"
                 Layout.preferredHeight: 250
                 Layout.preferredWidth: 250
                 fillMode: Image.PreserveAspectFit
                 Layout.leftMargin: 27
                 playing: true
             }                
          }
      }
}
