import QtQuick
import "SeekMath.js" as SeekMath
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.mpris as Mpris

Rectangle {
    id: root

    property var player: null
    property var audioSamples: []
    property bool compactMode: false
    property string visualizationMessage: ""
    signal primaryActivated()

    readonly property real fieldWidth: compactMode ? 204 : 240
    readonly property real positionFraction: {
        if (!player || !player.ready || player.songLength <= 0) {
            return 0
        }
        return Math.max(0, Math.min(1, player.songPosition / player.songLength))
    }
    readonly property string titleText: player && player.ready
        ? (player.title || "Spotify") : i18n("Start Spotify")
    readonly property string artistText: player && player.ready
        ? (player.artists || "") : i18n("Click the icon to start")
    readonly property bool lightSurface:
        Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) !== Kirigami.ColorUtils.Dark
    readonly property color fieldColor: lightSurface ? Kirigami.Theme.backgroundColor : "#101213"
    readonly property color waveformColor: lightSurface ? "#555b60" : "#a5aaaa"
    readonly property real waveformOpacity: lightSurface ? 0.48 : 0.34

    implicitWidth: fieldWidth
    implicitHeight: 42
    Layout.minimumWidth: fieldWidth
    Layout.preferredWidth: fieldWidth
    Layout.maximumWidth: fieldWidth
    Layout.minimumHeight: 42
    Layout.preferredHeight: 42
    radius: 6
    color: fieldColor
    border.width: 1
    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.10)
    clip: true

    // Keep foreground labels and controls paired with the local surface palette.
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    MouseArea {
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton
        onClicked: root.primaryActivated()
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        active: !spotifyButton.hovered && !playPauseButton.hovered && !nextButton.hovered && !seekSlider.hoverActive
        mainText: root.titleText
        subText: {
            var details = root.artistText + (root.player && root.player.ready
                ? "\n" + i18n("Click: open playback details")
                : "\n" + i18n("Click: start Spotify"))
            if (root.visualizationMessage.length > 0) {
                details += "\n" + root.visualizationMessage
            }
            return details
        }
    }

    AudioWave {
        x: 41
        y: 7
        width: Math.max(0, controls.x + playPauseButton.x - x - 7)
        height: 29
        z: 1
        samples: root.audioSamples
        lineColor: root.waveformColor
        opacity: root.waveformOpacity
    }

    PlasmaComponents.Slider {
        id: seekSlider
        x: 43
        y: parent.height - 15
        width: Math.max(0, controls.x + playPauseButton.x - x - 7)
        height: 15
        z: 3
        padding: 0
        from: 0
        to: 1
        enabled: !!root.player && root.player.ready && root.player.canSeek && root.player.songLength > 0
        property bool userSeeking: false
        property bool hoverActive: hoverMouse.containsMouse
        Accessible.name: i18n("Playback position")

        function commitPosition() {
            if (!enabled || !root.player) return
            var target = SeekMath.targetPosition(value, root.player.songLength)
            if (target !== null) root.player.setPosition(target)
        }

        Binding {
            target: seekSlider
            property: "value"
            value: root.positionFraction
            when: !seekSlider.pressed
            restoreMode: Binding.RestoreNone
        }

        onPressedChanged: {
            if (pressed) userSeeking = true
            else if (userSeeking) {
                commitPosition()
                userSeeking = false
            }
        }
        onMoved: if (!pressed) commitPosition()

        background: Item {
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                height: seekSlider.hoverActive || seekSlider.pressed ? 3 : 1
                radius: height / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.16)
                Behavior on height { NumberAnimation { duration: 110 } }
                Rectangle {
                    width: parent.width * seekSlider.visualPosition
                    height: parent.height
                    radius: parent.radius
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.66)
                }
            }
        }
        handle: Rectangle {
            width: 7
            height: 7
            x: seekSlider.visualPosition * (seekSlider.width - width)
            y: seekSlider.height - 7
            radius: 3.5
            color: Kirigami.Theme.textColor
            opacity: seekSlider.hoverActive || seekSlider.pressed ? 0.9 : 0
            Behavior on opacity { NumberAnimation { duration: 110 } }
        }
        MouseArea {
            id: hoverMouse
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
        PlasmaComponents.ToolTip.text: {
            var duration = root.player ? root.player.songLength : 0
            var target = SeekMath.targetPosition(hoverMouse.mouseX / Math.max(1, width), duration)
            return target === null ? "" : SeekMath.formatTime(target) + " / " + SeekMath.formatTime(duration) + "\n" + i18n("Click or drag to seek")
        }
        PlasmaComponents.ToolTip.visible: hoverActive && enabled
        PlasmaComponents.ToolTip.delay: 200
    }

    RowLayout {
        id: controls
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 5
        spacing: 4
        z: 2

        PlasmaComponents.ToolButton {
            id: spotifyButton
            Layout.preferredWidth: 32
            Layout.minimumWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            padding: 0
            icon.name: "spotify"
            icon.width: 28
            icon.height: 28
            Accessible.name: player && player.ready ? i18n("Open Spotify playback details") : i18n("Start Spotify")
            background: Rectangle {
                radius: 5
                color: spotifyButton.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.09) : "transparent"
            }
            PlasmaComponents.ToolTip.text: root.player && root.player.ready
                ? i18n("Open cover and playback details") : i18n("Start Spotify")
            PlasmaComponents.ToolTip.visible: hovered
            PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            onClicked: root.primaryActivated()
        }

        ColumnLayout {
            id: trackText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.titleText
                textFormat: Text.PlainText
                font.pointSize: root.compactMode ? 7.8 : 8.2
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: 0.96
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.artistText
                textFormat: Text.PlainText
                font.pointSize: root.compactMode ? 6.8 : 7.2
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: 0.68
            }
        }

        PlasmaComponents.ToolButton {
            id: playPauseButton
            Layout.preferredWidth: 22
            Layout.minimumWidth: 22
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter
            padding: 2
            icon.name: player && player.playbackStatus === Mpris.PlaybackStatus.Playing
                ? "media-playback-pause" : "media-playback-start"
            icon.width: 16
            icon.height: 16
            Accessible.name: player && player.playbackStatus === Mpris.PlaybackStatus.Playing
                ? i18n("Pause") : i18n("Resume playback")
            enabled: !!player && player.ready
                && (player.playbackStatus === Mpris.PlaybackStatus.Playing ? player.canPause : player.canPlay)
            background: Rectangle {
                radius: 4
                color: playPauseButton.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.08) : "transparent"
            }
            PlasmaComponents.ToolTip.text: player && player.playbackStatus === Mpris.PlaybackStatus.Playing
                ? i18n("Pause music") : i18n("Resume playback")
            PlasmaComponents.ToolTip.visible: hovered
            PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            onClicked: if (player) player.playPause()
        }

        PlasmaComponents.ToolButton {
            id: nextButton
            Layout.preferredWidth: 20
            Layout.minimumWidth: 20
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter
            padding: 2
            icon.name: "media-skip-forward"
            icon.width: 15
            icon.height: 15
            Accessible.name: i18n("Next track")
            enabled: !!player && player.ready && player.canGoNext
            background: Rectangle {
                radius: 4
                color: nextButton.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.08) : "transparent"
            }
            PlasmaComponents.ToolTip.text: i18n("Next track")
            PlasmaComponents.ToolTip.visible: hovered
            PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            onClicked: if (player) player.next()
        }
    }
}
