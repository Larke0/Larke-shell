import QtQuick

Item {
    id: control
    property int size: 12
    property color color: "black"
    
    width: size
    height: size

    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = control.color;
            
            // Draw a square then cut out a circle
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(control.size, 0);
            ctx.lineTo(control.size, control.size);
            ctx.arcTo(0, control.size, 0, 0, control.size);
            ctx.closePath();
            ctx.fill();
        }
    }
}
