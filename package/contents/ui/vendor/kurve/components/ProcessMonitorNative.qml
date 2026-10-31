import QtQuick
import com.github.luisbocanegra.audiovisualizer.process

// Native-only adapter adapted from Kurve's GPL-3.0 ProcessMonitorPrimary.qml.
// It is loaded dynamically so a missing optional QML module cannot break the player.
Item {
    id: root

    property string command: ""
    readonly property string stdout: process.stdout
    readonly property string stderr: process.stderr
    readonly property bool running: process.running

    function restart() {
        process.restart()
    }

    function start() {
        // The upstream native Process type exposes restart(), not start().
        process.restart()
    }

    function stop() {
        process.stop()
    }

    Process {
        id: process
    }

    onCommandChanged: {
        if (command.length === 0) return
        process.command = ["sh", "-c", command]
    }
}
