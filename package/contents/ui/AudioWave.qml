import QtQuick
import "WaveMath.js" as WaveMath

Item {
    id: root
    property var samples: []
    property real maxRange: 100
    property color lineColor: "#a5aaaa"

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var context = getContext("2d")
            context.clearRect(0, 0, width, height)
            if (!root.samples || root.samples.length === 0 || width <= 1 || height <= 1) {
                return
            }

            var points = WaveMath.interpolate(root.samples, Math.max(2, Math.floor(width / 1.5)), root.maxRange)
            if (points.length < 2) {
                return
            }
            var peak = 0
            for (var i = 0; i < points.length; i++) {
                peak = Math.max(peak, points[i])
            }
            if (peak <= 0) {
                return
            }

            var base = height * 0.83
            var lastX = 0
            var lastY = base - (points[0] / root.maxRange) * height * 0.62
            context.beginPath()
            context.moveTo(lastX, lastY)
            for (var point = 1; point < points.length; point++) {
                var x = width * point / (points.length - 1)
                var y = base - (points[point] / root.maxRange) * height * 0.62
                var middleX = (lastX + x) / 2
                var middleY = (lastY + y) / 2
                context.quadraticCurveTo(lastX, lastY, middleX, middleY)
                lastX = x
                lastY = y
            }
            context.lineTo(lastX, lastY)
            context.lineWidth = 1.25
            context.lineCap = "round"
            context.lineJoin = "round"
            context.strokeStyle = root.lineColor
            context.stroke()
        }
    }

    onSamplesChanged: canvas.requestPaint()
    onLineColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
}
