import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import "WaveMath.js" as WaveMath
import "vendor/plasmusic" as PlasMusic

PlasmoidItem {
    id: widget

    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    property bool compactMode: plasmoid.configuration.compactMode
    readonly property font baseFont: Kirigami.Theme.defaultFont
    readonly property var activePlayer: player
    readonly property string audioSource: "@DEFAULT_MONITOR@"
    readonly property bool audioAllowed: plasmoid.configuration.showWaveform && WaveMath.shouldRunAudio(
        !!(player && player.ready),
        player ? player.playbackStatus : Mpris.PlaybackStatus.Unknown,
        Mpris.PlaybackStatus.Playing,
        audioSource
    )
    readonly property int desktopRate: Math.max(1, Math.min(60, plasmoid.configuration.desktopAudioFrameRate))
    readonly property int laptopRate: Math.max(1, Math.min(60, plasmoid.configuration.laptopAudioFrameRate))
    readonly property int selectedRate: compactMode ? laptopRate : desktopRate

    // Each field owns its tooltip; avoid a competing panel-wide tooltip.
    toolTipMainText: ""
    toolTipSubText: ""

    function handleMusicClick() {
        if (WaveMath.musicClickAction(!!(player && player.ready)) === "launch") {
            // A launch request is made only as the result of an explicit user click.
            Qt.openUrlExternally("spotify:")
        } else {
            expanded = true
        }
    }

    PlasMusic.Player {
        id: player
        sourceIdentities: ["Spotify"]
    }

    Timer {
        interval: 1000
        running: !!player && player.ready && player.playbackStatus === Mpris.PlaybackStatus.Playing
        repeat: true
        triggeredOnStart: true
        onTriggered: player.updatePosition()
    }

    Loader {
        id: audioSpectrumLoader
        active: widget.audioAllowed
        asynchronous: false
        sourceComponent: Component {
            AudioSpectrum {
                enabled: true
                monitorSource: widget.audioSource
                frameRate: widget.selectedRate
                barCount: 48
            }
        }
    }

    compactRepresentation: Item {
        id: compact
        readonly property real musicWidth: widget.compactMode ? 204 : 240

        implicitWidth: musicWidth
        implicitHeight: 42
        Layout.minimumWidth: musicWidth
        Layout.preferredWidth: musicWidth
        Layout.maximumWidth: musicWidth
        Layout.minimumHeight: 42
        Layout.preferredHeight: 42
        Layout.fillHeight: true

        MusicField {
            anchors.fill: parent
            player: widget.activePlayer
            audioSamples: audioSpectrumLoader.item ? audioSpectrumLoader.item.spectrum : []
            visualizationMessage: audioSpectrumLoader.item ? audioSpectrumLoader.item.statusMessage : ""
            compactMode: widget.compactMode
            onPrimaryActivated: widget.handleMusicClick()
        }
    }

    fullRepresentation: PlasMusic.Full { }
}
