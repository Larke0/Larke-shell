import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../../theme"

// =============================================================================
// QuickMenu — Slide-in panel anchored to the top-left of the screen.
// =============================================================================
PanelWindow {
    id: rootMainMenu
    required property var anchorWindow

    // -------------------------------------------------------------------------
    // Config
    // -------------------------------------------------------------------------
    QtObject {
        id: cfg

        readonly property int panelWidth:   330
        readonly property int panelHeight:  1050
        readonly property int notchDepth:   20
        readonly property int notchRadius:  10
        readonly property int contentWidth: 300
        readonly property int contentMargin: 10

        readonly property int slideOffsetX:  -330
        readonly property int slideDuration:  400

        readonly property int focusDelay:    200
        readonly property int autoCloseDelay: 10000
        readonly property int sectionSpacing: 10

        readonly property int dividerHeight: 5
        readonly property int dividerRadius: 10

        readonly property int sysBtnWidth:    80
        readonly property int sysBtnHeight:   50
        readonly property int sysBtnRadius:   100
        readonly property int sysBtnFontSize: 40

        readonly property int reloadBtnSize:     30
        readonly property int reloadBtnFontSize: 10
        readonly property int lockBtnFontSize:   33

        readonly property int toggleWidth:    120
        readonly property int toggleHeight:   60
        readonly property int toggleRadius:   100
        readonly property int toggleFontSize: 33

        readonly property int selectorHeight:  50
        readonly property int selectorSpacing: 5
        readonly property int selectorRadius:  20
        readonly property int selectorFontSize: 16
        readonly property int selectorIconSize: 26
        readonly property int selectorAnimMs:   300

        readonly property int sysRowSpacing:    15
        readonly property int toggleRowSpacing: 10

        readonly property int gifSize:       250
        readonly property int gifLeftMargin: 27

        readonly property string nerdFont: "JetBrainsMono Nerd Font Propo"
    }


    // -------------------------------------------------------------------------
    // Panel geometry
    // -------------------------------------------------------------------------
    anchors.top:  true
    anchors.left: true
    implicitWidth:  cfg.panelWidth
    implicitHeight: cfg.panelHeight
    color:   "transparent"
    visible: true


    // -------------------------------------------------------------------------
    // Open / close
    // -------------------------------------------------------------------------
    property bool isOpen: false

    function open()   { isOpen = true  }
    function close()  { isOpen = false }
    function toggle() { if (isOpen) close(); else open() }

    onIsOpenChanged: {
        if (isOpen) {
            pwDumper.running = true
            if (anchorWindow && anchorWindow.screen) {
                ddcDisplayFinder.waylandOutput = anchorWindow.screen.name
                ddcDisplayFinder.running = true
            } else {
                rootMainMenu.currentDdcDisplay = 1
                brightnessFetcher.command = ["sh", "-c",
                    "ddcutil --display 1 getvcp 10 | grep -oP 'current value = \\s*\\K[0-9]+'"]
                brightnessFetcher.running = true
            }
            focusTimer.start()
        } else {
            pwDumper.running = false
            focusTimer.stop()
            rootMainMenu.focusActive = false
        }
    }

    property bool focusActive: false


    // -------------------------------------------------------------------------
    // Audio state
    // -------------------------------------------------------------------------
    property var    audioDeviceNames:  []
    property var    audioDeviceMap:    ({})
    property string currentDefaultSink: ""

    // -------------------------------------------------------------------------
    // Brightness state
    // -------------------------------------------------------------------------
    property int currentDdcDisplay: 1

    // Shared slide offset — both Shape and Flickable bind to this
    property real slideX: cfg.slideOffsetX


    // -------------------------------------------------------------------------
    // Processes
    // -------------------------------------------------------------------------

    Process {
        id: ddcDisplayFinder
        property string waylandOutput: ""
        command: ["sh", "-c",
            "ddcutil detect | awk -v t='" + waylandOutput + "' " +
            "'/Display/ {id=$2} /DRM_connector:/ {conn=$2; sub(/^card[0-9]+-/, \"\", conn); if (conn == t) print id}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                if (output.length > 0) {
                    let resolvedId = parseInt(output)
                    if (!isNaN(resolvedId)) {
                        rootMainMenu.currentDdcDisplay = resolvedId
                        brightnessFetcher.command = ["sh", "-c",
                            "ddcutil --display " + resolvedId +
                            " getvcp 10 | grep -oP 'current value = \\s*\\K[0-9]+'"]
                        brightnessFetcher.running = true
                    }
                } else {
                    console.warn("ddcDisplayFinder: no match for", ddcDisplayFinder.waylandOutput)
                }
            }
        }
    }

    Process {
        id: brightnessFetcher
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(this.text.trim())
                if (!isNaN(val)) brightnessSlider.value = val
            }
        }
    }

    Process { id: brightnessSetter }

    Process {
        id: powerAction
        command: ["sh", "-c", "true"]
    }

    Process {
        id: wpctlSetter
        command: ["wpctl", "set-default"]
    }

    Process {
        id: pwDumper
        command: ["pw-dump"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                if (output.length === 0) return
                try {
                    let data = JSON.parse(output)
                    let names = [], mapping = {}, defaultNodeName = ""
                    let metadata = data.find(obj =>
                        obj.type === "PipeWire:Interface:Metadata" &&
                        obj.props?.["metadata.name"] === "default")
                    if (metadata?.metadata) {
                        let entry = metadata.metadata.find(m => m.key === "default.audio.sink")
                        if (entry?.value?.name) defaultNodeName = entry.value.name
                    }
                    data.filter(obj => obj.info?.props?.["media.class"] === "Audio/Sink")
                        .forEach(sink => {
                            let desc = sink.info.props["node.description"] || "Unknown Device"
                            let name = sink.info.props["node.name"]
                            names.push(desc)
                            mapping[desc] = sink.id
                            if (name === defaultNodeName) rootMainMenu.currentDefaultSink = desc
                        })
                    if (names.length > 0) {
                        rootMainMenu.audioDeviceNames = [...names]
                        rootMainMenu.audioDeviceMap   = mapping
                    }
                } catch (e) { console.error("pw-dump parse error:", e) }
            }
        }
    }


    // -------------------------------------------------------------------------
    // Timers
    // -------------------------------------------------------------------------
    Timer {
        id: focusTimer
        interval: cfg.focusDelay; repeat: false
        onTriggered: { if (rootMainMenu.isOpen) rootMainMenu.focusActive = true }
    }

    Timer {
        id: closeTimer
        interval: cfg.autoCloseDelay; repeat: false
        onTriggered: rootMainMenu.close()
    }

    HyprlandFocusGrab {
        windows: [rootMainMenu]
        active:  rootMainMenu.focusActive
        onCleared: rootMainMenu.close()
    }


    // =========================================================================
    // Components
    // =========================================================================

    component SysButton: Rectangle {
        id: btn
        property string name:       "Action"
        property string cmd:        ""
        property string baseColor:  Theme.empty
        property string hoverColor: Theme.accent
        property string fontFamily: cfg.nerdFont
        property int    fontSize:   cfg.sysBtnFontSize
        property int    btnWidth:   cfg.sysBtnWidth
        property int    btnHeight:  cfg.sysBtnHeight

        Layout.preferredWidth:  btnWidth
        Layout.preferredHeight: btnHeight
        radius: cfg.sysBtnRadius
        color:  mouse.containsMouse ? hoverColor : baseColor
        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
            id: mouse; anchors.fill: parent; hoverEnabled: true
            onClicked: {
                powerAction.command = ["sh", "-c", btn.cmd]
                powerAction.running = true
                rootMainMenu.close()
            }
        }
        Text {
            anchors.centerIn: parent
            text: btn.name; color: mouse.containsMouse ? "#1e1e2e" : "white"
            font.bold: true; font.family: btn.fontFamily; font.pixelSize: btn.fontSize
        }
    }

    component QuickToggle: Rectangle {
        id: toggle
        property string name:       "Unknown"
        property bool   active:     false
        property string fontFamily: cfg.nerdFont
        property int    fontSize:   cfg.toggleFontSize

        Layout.preferredWidth:  cfg.toggleWidth
        Layout.preferredHeight: cfg.toggleHeight
        radius: cfg.toggleRadius
        color:  active ? Theme.accent : Theme.empty
        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea { anchors.fill: parent; onClicked: toggle.active = !toggle.active }
        Text {
            anchors.centerIn: parent
            text: toggle.name; color: toggle.active ? "black" : "white"
            font.bold: true; font.family: toggle.fontFamily; font.pixelSize: toggle.fontSize
        }
    }

    component ListSelector: Item {
        id: selector
        property string name:       "Select Option"
        property var    option:     ["Option 1", "Option 2", "Option 3"]
        property string selected:   option[0]
        property bool   expanded:   false
        property int buttonHeight:  cfg.selectorHeight
        property int buttonSpacing: cfg.selectorSpacing
        property int fontSize:      cfg.selectorFontSize
        property int fontSizeName:  cfg.selectorIconSize
        property int animDuration:  cfg.selectorAnimMs

        signal itemSelected(string item)

        // Animate this — the parent ColumnLayout reads Layout.preferredHeight
        // so items below slide down as this expands.
        property real expandedHeight: selector.expanded
            ? (selector.option.length + 1) * (selector.buttonHeight + selector.buttonSpacing)
            : selector.buttonHeight + selector.buttonSpacing

        Behavior on expandedHeight {
            NumberAnimation { duration: cfg.selectorAnimMs; easing.type: Easing.OutCubic }
        }

        Layout.preferredWidth:  cfg.contentWidth
        Layout.preferredHeight: expandedHeight
        implicitHeight:         expandedHeight

        Rectangle {
            id: selectorHeader
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: selector.buttonHeight
            radius: cfg.selectorRadius; color: Theme.secondary_accent
            RowLayout {
                anchors { fill: parent; leftMargin: 15; rightMargin: 15 }
                spacing: 5
                Text { text: selector.name; color: "white"; font.bold: true; font.pixelSize: selector.fontSizeName; elide: Text.ElideRight }
                Text { text: selector.selected; color: "white"; font.bold: true; font.pixelSize: selector.fontSize; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: selector.expanded ? "▲" : "▼"; color: "gray"; font.pixelSize: selector.fontSize }
            }
            MouseArea { anchors.fill: parent; onClicked: selector.expanded = !selector.expanded }
        }

        Rectangle {
            anchors { top: selectorHeader.bottom; topMargin: selector.buttonSpacing; left: parent.left; right: parent.right }
            clip: true; color: "transparent"
            height: selector.expanded
                ? selector.option.length * (selector.buttonHeight + selector.buttonSpacing) : 0
            Behavior on height {
                NumberAnimation { duration: selector.animDuration; easing.type: Easing.OutCubic }
            }
            Column {
                width: parent.width; spacing: selector.buttonSpacing
                Repeater {
                    model: selector.option
                    delegate: Rectangle {
                        width: parent.width; height: selector.buttonHeight
                        radius: cfg.selectorRadius
                        color: modelData === selector.selected ? Theme.accent : Theme.empty
                        Text {
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: 20; rightMargin: 20 }
                            text: modelData; font.pixelSize: selector.fontSize; font.bold: true; elide: Text.ElideRight
                            color: modelData === selector.selected ? Theme.empty : Theme.accent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { selector.selected = modelData; selector.expanded = false; selector.itemSelected(modelData) }
                        }
                    }
                }
            }
        }
    }

    component ListSlider: ColumnLayout {
        id: sliderRoot
        property string icon:      "\udb80\udcdd"
        property int    value:     50
        property int    minValue:  0
        property int    maxValue:  100
        property int    sliderHeight: 50
        property int    sliderRadius: 20
        property int    iconSize:  26

        signal valueChangedByUser(int newValue)

        spacing: 5

        Rectangle {
            Layout.fillWidth: true; height: sliderRoot.sliderHeight
            radius: sliderRoot.sliderRadius; color: Theme.secondary_accent
            RowLayout {
                anchors { fill: parent; leftMargin: 15; rightMargin: 15 }
                spacing: 15
                Text { text: sliderRoot.icon; color: "white"; font.family: cfg.nerdFont; font.pixelSize: sliderRoot.iconSize }
                Rectangle {
                    id: track; Layout.fillWidth: true; height: 6; radius: 3; color: Theme.empty
                    Rectangle {
                        id: fill
                        width: track.width * ((sliderRoot.value - sliderRoot.minValue) / (sliderRoot.maxValue - sliderRoot.minValue))
                        height: parent.height; radius: parent.radius; color: Theme.accent
                    }
                    Rectangle {
                        width: 16; height: 16; radius: 8; color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: fill.width - 8
                    }
                    MouseArea {
                        anchors.fill: parent
                        function updateValue(mx) {
                            let ratio = Math.max(0, Math.min(1, mx / track.width))
                            let nv = Math.round(sliderRoot.minValue + ratio * (sliderRoot.maxValue - sliderRoot.minValue))
                            if (sliderRoot.value !== nv) { sliderRoot.value = nv; sliderRoot.valueChangedByUser(nv) }
                        }
                        onPositionChanged: (mouse) => { if (pressed) updateValue(mouse.x) }
                        onClicked: (mouse) => updateValue(mouse.x)
                    }
                }
                Text {
                    text: sliderRoot.value + "%"; color: "white"; font.bold: true; font.pixelSize: 14
                    Layout.minimumWidth: 40; horizontalAlignment: Text.AlignRight
                }
            }
        }
    }


    // =========================================================================
    // Background shape — paint only, no layout children
    // =========================================================================
    Shape {
        id: bgShape
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        property real safeW: Math.max(rootMainMenu.width,  cfg.panelWidth)
        property real safeH: Math.max(rootMainMenu.height, cfg.panelHeight)

        ShapePath {
            fillColor: Theme.background; strokeColor: "transparent"
            startX: 0; startY: 0
            PathLine { x: bgShape.safeW; y: 0 }
            PathQuad {
                controlX: bgShape.safeW - cfg.notchDepth; controlY: 0
                x: bgShape.safeW - cfg.notchDepth; y: cfg.notchRadius
            }
            PathLine { x: bgShape.safeW - cfg.notchDepth; y: bgShape.safeH - cfg.notchRadius }
            PathQuad {
                controlX: bgShape.safeW - cfg.notchDepth; controlY: bgShape.safeH
                x: bgShape.safeW; y: bgShape.safeH
            }
            PathLine { x: 0; y: bgShape.safeH }
            PathLine { x: 0; y: 0 }
          }

        transform: Translate { x: rootMainMenu.slideX }

        states: State {
            name: "open"; when: rootMainMenu.isOpen
            PropertyChanges { target: rootMainMenu; slideX: -cfg.notchDepth }
        }

        transitions: [
            Transition {
                from: "*"; to: "open"
                SequentialAnimation {
                    ScriptAction { script: rootMainMenu.visible = true }
                    NumberAnimation {
                        target: rootMainMenu; property: "slideX"
                        duration: cfg.slideDuration; easing.type: Easing.OutCubic
                    }
                }
            },
            Transition {
                from: "open"; to: "*"
                SequentialAnimation {
                    NumberAnimation {
                        target: rootMainMenu; property: "slideX"
                        duration: cfg.slideDuration; easing.type: Easing.OutCubic
                    }
                    ScriptAction { script: rootMainMenu.visible = false }
                }
            }
        ]

        HoverHandler {
            onHoveredChanged: {
                if (hovered) closeTimer.stop()
                else         closeTimer.start()
            }
        }
        
    }


   


    // =========================================================================
    // Content — sibling of Shape, tracks the same slideX
    // =========================================================================
    Flickable {
        x:      cfg.contentMargin + rootMainMenu.slideX
        y:      cfg.contentMargin
        width:  cfg.contentWidth
        height: cfg.panelHeight - cfg.contentMargin * 2

        contentWidth:  cfg.contentWidth
        contentHeight: quickMenu.implicitHeight
        clip:          true
        interactive:   contentHeight > height

        ColumnLayout {
            id: quickMenu
            spacing: cfg.sectionSpacing
            width:  cfg.contentWidth
            height: implicitHeight

            SysButton {
                name: "\udb82\udc14"; fontFamily: cfg.nerdFont
                fontSize: cfg.reloadBtnFontSize; btnWidth: cfg.reloadBtnSize; btnHeight: cfg.reloadBtnSize
                cmd: "nohup $HOME/.local/bin/quickshell-reload > /dev/null 2>&1 &"
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter; Layout.fillWidth: true
                spacing: cfg.sysRowSpacing
                SysButton { name: "\udb81\udc25"; cmd: "systemctl poweroff" }
                SysButton { name: "\udb81\udf09"; cmd: "systemctl reboot" }
                SysButton { name: "\udb80\udf3e"; fontSize: cfg.lockBtnFontSize; cmd: "sleep 0.3 && pidof hyprlock || hyprlock" }
            }

            Rectangle {
                implicitHeight: cfg.dividerHeight; Layout.fillWidth: true
                radius: cfg.dividerRadius; color: Theme.accent_down
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter; Layout.fillWidth: true
                spacing: cfg.toggleRowSpacing
                QuickToggle { name: "\udb81\udda9" }
                QuickToggle { name: "\udb80\udcaf" }
            }

            ListSelector {
                id: audioOutputSelector
                name:     "\udb81\udcc3"
                selected: rootMainMenu.currentDefaultSink
                option:   rootMainMenu.audioDeviceNames
                Layout.fillWidth: true
                onItemSelected: (item) => {
                    let id = rootMainMenu.audioDeviceMap[item]
                    if (id) { wpctlSetter.command = ["wpctl", "set-default", id]; wpctlSetter.running = true }
                }
            }

            ListSlider {
                id: brightnessSlider
                icon: "\udb80\udcdd"
                Layout.fillWidth: true
                onValueChangedByUser: (newValue) => {
                    brightnessSetter.command = ["sh", "-c",
                        "ddcutil --async --display " + rootMainMenu.currentDdcDisplay + " setvcp 10 " + newValue]
                    brightnessSetter.running = true
                }
            }

            AnimatedImage {
                source: "/home/larke/.config/quickshell/assets/ado-dancing3.gif"
                Layout.preferredWidth:  cfg.gifSize
                Layout.preferredHeight: cfg.gifSize
                fillMode: Image.PreserveAspectFit
                Layout.leftMargin: cfg.gifLeftMargin
                playing: true
            }
        }
    }
}
