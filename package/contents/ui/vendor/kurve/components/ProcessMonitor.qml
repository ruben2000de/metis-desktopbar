// Process monitor adapted from Kurve 3.6.0, GPL-3.0; see THIRD_PARTY.md.
import QtQuick

// Native-only dynamic loader for Kurve's optional Qt Process extension.
// There is deliberately no WebSocket/PID-control fallback.
Item {
    id: root

    property string command: ""
    readonly property string stdout: nativeBackend.item ? nativeBackend.item.stdout : ""
    readonly property string stderr: nativeBackend.item ? nativeBackend.item.stderr : ""
    readonly property bool running: nativeBackend.item ? nativeBackend.item.running : false
    readonly property bool loadingFailed: nativeBackend.status === Loader.Error
    readonly property list<string> loadingErrors: loadingFailed ? ["Native Process QML extension is unavailable"] : []
    readonly property bool usingFallback: false
    property var process: nativeBackend.item

    function restart() {
        if (nativeBackend.item) nativeBackend.item.restart()
    }

    function start() {
        if (nativeBackend.item) nativeBackend.item.start()
    }

    function stop() {
        if (nativeBackend.item) nativeBackend.item.stop()
    }

    onCommandChanged: {
        if (nativeBackend.item) nativeBackend.item.command = command
    }

    Loader {
        id: nativeBackend
        active: true
        source: "ProcessMonitorNative.qml"
        onLoaded: item.command = root.command
    }
}
