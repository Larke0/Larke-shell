import QtQuick
import Quickshell
import Quickshell.Wayland


PopupWindow {
  id: rootPopup
  required property var anchorWindow

  anchor.window: rootPopup.anchorWindow
  anchor.rect.x: parentWindow.width / 2 - width / 2
  anchor.rect.y: parentWindow.height
  implicitWidth: 200
  implicitHeight: 200
  visible: false
}
