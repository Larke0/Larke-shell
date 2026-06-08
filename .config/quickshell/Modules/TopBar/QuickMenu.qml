import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../../theme"

// =============================================================================
// MainMenu — Slide-in panel anchored to the top-left of the screen.
// =============================================================================
PanelWindow {
    id: rootMainMenu
    required property var anchorWindow

    // -------------------------------------------------------------------------
    // Config — All magic numbers live here. Edit this block to restyle the menu.
    // -------------------------------------------------------------------------
    QtObject {
        id: cfg

        // Panel dimensions
        readonly property int panelWidth:  330
        readonly property int visibleWidth: panelWidth - notchDepth
        readonly property int panelHeight: 1050

        // Notch / cutout on the right edge of the background shape
        readonly property int notchDepth:  20
        readonly property int notchRadius: 10

        // Inner content column: narrower than the panel to clear the notch
        readonly property int contentWidth:   300
        readonly property int contentMargin:  10

        // Slide animation
        readonly property int slideOffsetX:    -310
        readonly property int slideDuration:    400

        // Focus-grab delay after open (ms) — prevents accidental immediate close
        readonly property int focusDelay:       200

        // Auto-close countdown when mouse leaves (ms)
        readonly property int autoCloseDelay: 10000

        // Spacing between major layout sections
        readonly property int sectionSpacing: 10

        // Divider bar
        readonly property int dividerHeight: 5
        readonly property int dividerRadius: 10

        // SysButton defaults
        readonly property int   sysBtnWidth:    80
        readonly property int   sysBtnHeight:   50
        readonly property int   sysBtnRadius:  100
        readonly property int   sysBtnFontSize: 40

        // Small reload button (top-left corner of the menu)
        readonly property int   reloadBtnSize:      30
        readonly property int   reloadBtnFontSize:  10

        // Lock icon is slightly smaller than the other sys buttons
        readonly property int   lockBtnFontSize: 33

        // QuickToggle defaults
        readonly property int   toggleWidth:    120
        readonly property int   toggleHeight:    60
        readonly property int   toggleRadius:   100
        readonly property int   toggleFontSize:  33

        // ListSelector defaults
        readonly property int   selectorHeight:   50
        readonly property int   selectorSpacing:   5
        readonly property int   selectorRadius:   20
        readonly property int   selectorFontSize: 16
        readonly property int   selectorIconSize: 26
        readonly property int   selectorAnimMs:  300

        // Row spacing inside system-button row and toggle row
        readonly property int sysRowSpacing:    15
        readonly property int toggleRowSpacing: 10

        // Animated GIF
        readonly property int gifSize:        250
        readonly property int gifLeftMargin:   27

        // Nerd Font used for icons throughout the panel
        readonly property string nerdFont: "JetBrainsMono Nerd Font Propo"
    }


    // -------------------------------------------------------------------------
    // Panel geometry & base appearance
    // -------------------------------------------------------------------------
    anchors.top:  true
    anchors.left: true
    implicitWidth:  cfg.panelWidth
    implicitHeight: cfg.panelHeight
    color:   "transparent"
    visible: true


    // -------------------------------------------------------------------------
    // Panel open/close state
    // -------------------------------------------------------------------------
    property bool isOpen: false

    function open() {
        isOpen = true
    }

    function close() {
        isOpen = false
    }

    function toggle() {
        if (isOpen) close()
        else        open()
    }

    onIsOpenChanged: {
        if (isOpen) {
            console.log("=== MENU OPENED ===")
            console.log("anchorWindow:", anchorWindow)
            console.log("anchorWindow.screen:", anchorWindow?.screen)
            console.log("anchorWindow.screen.name:", anchorWindow?.screen?.name)
            pwDumper.running = true

            if (anchorWindow && anchorWindow.screen) {
                ddcDisplayFinder.waylandOutput = anchorWindow.screen.name
                console.log("Starting ddcDisplayFinder with output:", ddcDisplayFinder.waylandOutput)
                ddcDisplayFinder.running = true
            } else {
                console.warn("No anchorWindow screen — falling back to display 1")
                rootMainMenu.currentDdcDisplay = 1
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
    // Processes
    // -------------------------------------------------------------------------

    // Dynamic Monitor Context Management
    property int currentDdcDisplay: 1

    // 1. Fully generic interface mapper
    Process {
        id: ddcDisplayFinder
        property string waylandOutput: ""

        command: ["sh", "-c", "ddcutil detect | awk -v t='" + waylandOutput + "' '/Display/ {id=$2} /DRM_connector:/ {conn=$2; sub(/^card[0-9]+-/, \"\", conn); if (conn == t) print id}'"]

        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                console.log("ddcDisplayFinder raw output: '" + output + "'")
                console.log("ddcDisplayFinder was looking for:", ddcDisplayFinder.waylandOutput)
                if (output.length > 0) {
                    let resolvedId = parseInt(output)
                    console.log("Resolved display ID:", resolvedId)
                    if (!isNaN(resolvedId)) {
                        rootMainMenu.currentDdcDisplay = resolvedId
                        console.log("currentDdcDisplay set to:", rootMainMenu.currentDdcDisplay)
                        brightnessFetcher.command = ["sh", "-c", "ddcutil --display " + resolvedId + " getvcp 10 | grep -oP 'current value = \\s*\\K[0-9]+'"]
                        console.log("Fetching brightness for display:", resolvedId)
                        brightnessFetcher.running = true
                    }
                } else {
                    console.warn("ddcDisplayFinder got empty output — no match for: " + ddcDisplayFinder.waylandOutput)
                }
            }
        }
    }

    // 2. Fetches current hardware brightness for the resolved display ID
    Process {
        id: brightnessFetcher

        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                console.log("brightnessFetcher raw output: '" + output + "'")
                console.log("brightnessFetcher was targeting display:", rootMainMenu.currentDdcDisplay)
                if (output.length > 0) {
                    let val = parseInt(output)
                    if (!isNaN(val)) {
                        console.log("Setting slider to:", val)
                        brightnessSlider.value = val
                    }
                }
            }
        }
    }

    // 3. Pushes slider updates to the correct display
    Process {
        id: brightnessSetter
    }

    // Runs an arbitrary shell command (used by SysButton)
    Process {
        id: powerAction
        command: ["sh", "-c", "true"]
    }

    // Sets the default PipeWire sink by numeric ID
    Process {
        id: wpctlSetter
        command: ["wpctl", "set-default"]
    }

    // Queries PipeWire for all audio sinks and finds the current default
    Process {
        id: pwDumper
        command: ["pw-dump"]

        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                if (output.length === 0) return

                try {
                    let data = JSON.parse(output)
                    let names   = []
                    let mapping = {}
                    let defaultNodeName = ""

                    let metadata = data.find(obj =>
                        obj.type === "PipeWire:Interface:Metadata" &&
                        obj.props &&
                        obj.props["metadata.name"] === "default"
                    )

                    if (metadata?.metadata) {
                        let entry = metadata.metadata.find(m => m.key === "default.audio.sink")
                        if (entry?.value?.name) {
                            defaultNodeName = entry.value.name
                        }
                    }

                    data.filter(obj =>
                        obj.info?.props?.["media.class"] === "Audio/Sink"
                    ).forEach(sink => {
                        let description = sink.info.props["node.description"] || "Unknown Device"
                        let systemName  = sink.info.props["node.name"]

                        names.push(description)
                        mapping[description] = sink.id

                        if (systemName === defaultNodeName) {
                            rootMainMenu.currentDefaultSink = description
                        }
                    })

                    console.log("---------------------------------")
                    console.log("ACTIVE DEFAULT:", rootMainMenu.currentDefaultSink)
                    console.log("ALL DEVICES:",    JSON.stringify(names))
                    console.log("---------------------------------")

                    if (names.length > 0) {
                        rootMainMenu.audioDeviceNames = [...names]
                        rootMainMenu.audioDeviceMap   = mapping
                    }

                } catch (e) {
                    console.error("Error parsing pw-dump JSON:", e)
                }
            }
        }
    }


    // -------------------------------------------------------------------------
    // Timers
    // -------------------------------------------------------------------------

    Timer {
        id: focusTimer
        interval: cfg.focusDelay
        repeat:   false
        onTriggered: {
            if (rootMainMenu.isOpen) rootMainMenu.focusActive = true
        }
    }

    Timer {
        id: closeTimer
        interval: cfg.autoCloseDelay
        repeat:   false
        onTriggered: rootMainMenu.close()
    }


    // -------------------------------------------------------------------------
    // Focus grab
    // -------------------------------------------------------------------------
    HyprlandFocusGrab {
        windows: [rootMainMenu]
        active:  rootMainMenu.focusActive
        onCleared: rootMainMenu.close()
    }


    // =========================================================================
    // Reusable components
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
        color:  mouse.containsMouse ? btn.hoverColor : btn.baseColor

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
            text:             btn.name
            color:            mouse.containsMouse ? "#1e1e2e" : "white"
            font.bold:        true
            font.family:      btn.fontFamily
            font.pixelSize:   btn.fontSize
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

        MouseArea {
            anchors.fill: parent
            onClicked: toggle.active = !toggle.active
        }

        Text {
            anchors.centerIn: parent
            text:           toggle.name
            color:          toggle.active ? "black" : "white"
            font.bold:      true
            font.family:    toggle.fontFamily
            font.pixelSize: toggle.fontSize
        }
    }


    component ListSelector: ColumnLayout {
        id: selector

        property string name:        "Select Option"
        property var    option:      ["Option 1", "Option 2", "Option 3"]
        property string selected:    option[0]
        property bool   expanded:    false

        property int buttonHeight:   cfg.selectorHeight
        property int buttonSpacing:  cfg.selectorSpacing
        property int fontSize:       cfg.selectorFontSize
        property int fontSizeName:   cfg.selectorIconSize
        property int animDuration:   cfg.selectorAnimMs

        signal itemSelected(string item)

        spacing:       buttonSpacing
        implicitWidth: cfg.contentWidth

        implicitHeight: selector.expanded
            ? (selector.option.length + 1) * (selector.buttonHeight + selector.buttonSpacing)
            : selector.buttonHeight + selector.buttonSpacing

        Behavior on implicitHeight {
            NumberAnimation {
                duration:    cfg.selectorAnimMs
                easing.type: Easing.OutCubic
            }
        }

        // Header / trigger row
        Rectangle {
            Layout.fillWidth: true
            height: selector.buttonHeight
            radius: cfg.selectorRadius
            color:  Theme.secondary_accent

            RowLayout {
                anchors {
                    fill:        parent
                    leftMargin:  15
                    rightMargin: 15
                }
                spacing: 5

                Text {
                    text:           selector.name
                    color:          "white"
                    font.bold:      true
                    font.pixelSize: selector.fontSizeName
                    elide:          Text.ElideRight
                }

                Text {
                    text:           selector.selected
                    color:          "white"
                    font.bold:      true
                    font.pixelSize: selector.fontSize
                    elide:          Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text:           selector.expanded ? "▲" : "▼"
                    color:          "gray"
                    font.pixelSize: selector.fontSize
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked:    selector.expanded = !selector.expanded
            }
        }

        // Animated container that reveals the option list
        Rectangle {
            id: listContainer
            Layout.fillWidth: true
            clip:  true
            color: "transparent"

            height: selector.expanded
                    ? selector.option.length * (selector.buttonHeight + selector.buttonSpacing)
                    : 0

            Behavior on height {
                NumberAnimation {
                    duration:    selector.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                width:   parent.width
                spacing: selector.buttonSpacing

                Repeater {
                    model: selector.option

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: selector.buttonHeight
                        radius: cfg.selectorRadius
                        color:  modelData === selector.selected ? Theme.accent : Theme.empty

                        Text {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left:           parent.left
                                right:          parent.right
                                leftMargin:     20
                                rightMargin:    20
                            }
                            text:           modelData
                            color:          modelData === selector.selected ? Theme.empty : Theme.accent
                            font.pixelSize: selector.fontSize
                            font.bold:      true
                            elide:          Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                selector.selected = modelData
                                selector.expanded = false
                                selector.itemSelected(modelData)
                            }
                        }
                    }
                }
            }
        }
    }


    component ListSlider: ColumnLayout {
        id: sliderRoot

        property string icon: "\udb80\udcdd"
        property int value: 50
        property int minValue: 0
        property int maxValue: 100

        property int sliderHeight: 50
        property int sliderRadius: 20
        property int iconSize: 26

        signal valueChangedByUser(int newValue)

        spacing: 5
        implicitWidth: cfg.contentWidth

        Rectangle {
            Layout.fillWidth: true
            height: sliderRoot.sliderHeight
            radius: sliderRoot.sliderRadius
            color: Theme.secondary_accent

            RowLayout {
                anchors {
                    fill:        parent
                    leftMargin:  15
                    rightMargin: 15
                }
                spacing: 15

                Text {
                    text:           sliderRoot.icon
                    color:          "white"
                    font.family:    cfg.nerdFont
                    font.pixelSize: sliderRoot.iconSize
                }

                Rectangle {
                    id: track
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Theme.empty

                    Rectangle {
                        id: fill
                        width: track.width * ((sliderRoot.value - sliderRoot.minValue) / (sliderRoot.maxValue - sliderRoot.minValue))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }

                    Rectangle {
                        id: handle
                        width:  16
                        height: 16
                        radius: 8
                        color:  "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: fill.width - (width / 2)
                    }

                    MouseArea {
                        anchors.fill: parent

                        function updateValue(mouseX) {
                            let ratio    = Math.max(0, Math.min(1, mouseX / track.width))
                            let newValue = Math.round(sliderRoot.minValue + ratio * (sliderRoot.maxValue - sliderRoot.minValue))
                            if (sliderRoot.value !== newValue) {
                                sliderRoot.value = newValue
                                sliderRoot.valueChangedByUser(newValue)
                            }
                        }

                        onPositionChanged: (mouse) => { if (pressed) updateValue(mouse.x) }
                        onClicked:         (mouse) => updateValue(mouse.x)
                    }
                }

                Text {
                    text:                   sliderRoot.value + "%"
                    color:                  "white"
                    font.bold:              true
                    font.pixelSize:         14
                    Layout.minimumWidth:    40
                    horizontalAlignment:    Text.AlignRight
                }
            }
        }
    }


    // =========================================================================
    // Visual content
    // =========================================================================
    Shape {
        id: bgShape
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        property real safeW: Math.max(rootMainMenu.width,  cfg.panelWidth)
        property real safeH: Math.max(rootMainMenu.height, cfg.panelHeight)

        property real notchDepth:  cfg.notchDepth
        property real notchRadius: cfg.notchRadius

        ShapePath {
            fillColor:   Theme.background
            strokeColor: "transparent"

            startX: 0; startY: 0

            PathLine { x: bgShape.safeW; y: 0 }

            PathQuad {
                controlX: bgShape.safeW - bgShape.notchDepth; controlY: 0
                x:        bgShape.safeW - bgShape.notchDepth
                y:        bgShape.notchRadius
            }

            PathLine {
                x: bgShape.safeW - bgShape.notchDepth
                y: bgShape.safeH - bgShape.notchRadius
            }

            PathQuad {
                controlX: bgShape.safeW - bgShape.notchDepth; controlY: bgShape.safeH
                x:        bgShape.safeW
                y:        bgShape.safeH
            }

            PathLine { x: 0; y: bgShape.safeH }
            PathLine { x: 0; y: 0 }
        }

        transform: Translate {
            id: slidePos
            x: cfg.slideOffsetX
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) closeTimer.stop()
                else         closeTimer.start()
            }
        }

        states: State {
            name: "open"
            when: rootMainMenu.isOpen
            PropertyChanges { target: slidePos; x: -cfg.notchDepth }
        }

        transitions: [
            Transition {
                from: "*"; to: "open"
                SequentialAnimation {
                    ScriptAction    { script: rootMainMenu.visible = true }
                    NumberAnimation {
                        target:      slidePos
                        property:    "x"
                        duration:    cfg.slideDuration
                        easing.type: Easing.OutCubic
                    }
                }
            },
            Transition {
                from: "open"; to: "*"
                SequentialAnimation {
                    NumberAnimation {
                        target:      slidePos
                        property:    "x"
                        duration:    cfg.slideDuration
                        easing.type: Easing.OutCubic
                    }
                    ScriptAction { script: rootMainMenu.visible = false }
                }
            }
        ]

        // -----------------------------------------------------------------
        // Flickable content area — allows scrolling when selector expands
        // -----------------------------------------------------------------
        Flickable {
            anchors {
                top:              parent.top
                horizontalCenter: parent.horizontalCenter
                margins:          cfg.contentMargin
            }
            width:        cfg.contentWidth
            height:       cfg.panelHeight - cfg.contentMargin * 2
            contentWidth: cfg.contentWidth
            contentHeight: quickMenu.implicitHeight
            clip:         true
            interactive:  contentHeight > height

            ColumnLayout {
                id: quickMenu
                spacing: cfg.sectionSpacing
                width: cfg.contentWidth

                // Quickshell hot-reload button
                SysButton {
                    name:       "\udb82\udc14"
                    fontFamily: cfg.nerdFont
                    fontSize:   cfg.reloadBtnFontSize
                    btnWidth:   cfg.reloadBtnSize
                    btnHeight:  cfg.reloadBtnSize
                    cmd: "nohup $HOME/.local/bin/quickshell-reload > /dev/null 2>&1 &"
                }

                // Power controls row: Shutdown · Reboot · Lock
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    spacing: cfg.sysRowSpacing

                    SysButton {
                        name: "\udb81\udc25"
                        cmd:  "systemctl poweroff"
                    }

                    SysButton {
                        name: "\udb81\udf09"
                        cmd:  "systemctl reboot"
                    }

                    SysButton {
                        name:     "\udb80\udf3e"
                        fontSize: cfg.lockBtnFontSize
                        cmd:      "sleep 0.3 && pidof hyprlock || hyprlock"
                    }
                }

                // Section divider
                Rectangle {
                    implicitHeight: cfg.dividerHeight
                    Layout.fillWidth: true
                    radius: cfg.dividerRadius
                    color:  Theme.accent_down
                }

                // Quick-toggle row: Wi-Fi · Bluetooth
                RowLayout {
                    id: quickButtons
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    spacing: cfg.toggleRowSpacing

                    QuickToggle { name: "\udb81\udda9" }
                    QuickToggle { name: "\udb80\udcaf" }
                }

                // Audio output selector
                ListSelector {
                    id: audioOutputSelector

                    name:     "\udb81\udcc3"
                    selected: rootMainMenu.currentDefaultSink
                    option:   rootMainMenu.audioDeviceNames

                    Layout.alignment:   Qt.AlignHCenter
                    Layout.leftMargin:  cfg.contentMargin - 2
                    Layout.rightMargin: cfg.contentMargin - 2

                    onItemSelected: (item) => {
                        let id = rootMainMenu.audioDeviceMap[item]
                        if (id) {
                            console.log("Switching audio to:", item, "ID:", id)
                            wpctlSetter.command = ["wpctl", "set-default", id]
                            wpctlSetter.running = true
                        } else {
                            console.warn("No ID found for selected device:", item)
                        }
                    }
                }

                // Brightness slider
                ListSlider {
                    id: brightnessSlider
                    icon: "\udb80\udcdd"

                    Layout.alignment:   Qt.AlignHCenter
                    Layout.leftMargin:  cfg.contentMargin - 2
                    Layout.rightMargin: cfg.contentMargin - 2

                    onValueChangedByUser: (newValue) => {
                        console.log("Slider changed to:", newValue, "— targeting display:", rootMainMenu.currentDdcDisplay)
                        brightnessSetter.command = [
                            "sh", "-c",
                            "ddcutil --async --display " + rootMainMenu.currentDdcDisplay + " setvcp 10 " + newValue
                        ]
                        console.log("brightnessSetter command:", brightnessSetter.command.join(" "))
                        brightnessSetter.running = true
                    }
                }

                // Decorative animated GIF
                AnimatedImage {
                    source:                 "/home/larke/.config/quickshell/assets/ado-dancing3.gif"
                    Layout.preferredWidth:  cfg.gifSize
                    Layout.preferredHeight: cfg.gifSize
                    fillMode:               Image.PreserveAspectFit
                    Layout.leftMargin:      cfg.gifLeftMargin
                    playing:                true
                }
            }
        }
    }
}
