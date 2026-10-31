import QtQuick
import QtTest
import org.kde.plasma.private.mpris as Mpris
import "../package/contents/ui" as Bar

Item {
    width: 240; height: 42
    function i18n(text) { return text }
    QtObject {
        id: demo
        property bool ready: true
        property int playbackStatus: Mpris.PlaybackStatus.Playing
        property bool canSeek: true
        property bool canPlay: true
        property bool canPause: true
        property bool canGoNext: true
        property string title: "Demo track"
        property string artists: "Missing optional dependency"
        property double songLength: 200000000
        property double songPosition: 20000000
        property double requested: -1
        function setPosition(position) { requested = position; songPosition = position }
        function playPause() { }
        function next() { }
    }
    Bar.AudioSpectrum {
        id: spectrum
        enabled: true
        monitorSource: "@DEFAULT_MONITOR@"
        frameRate: 12
        barCount: 48
    }
    Bar.MusicField {
        id: field
        anchors.fill: parent
        player: demo
        audioSamples: spectrum.spectrum
        visualizationMessage: spectrum.statusMessage
    }
    TestCase {
        name: "MissingOptionalAudioDependency"
        when: windowShown
        function test_player_remains_usable_with_an_explicit_waveform_status() {
            tryVerify(function() { return spectrum.statusMessage.length > 0 }, 4000)
            compare(spectrum.spectrum.length, 0)
            verify(spectrum.statusMessage.indexOf("optional") >= 0)
            var slider = null
            for (var i = 0; i < field.children.length; i++) {
                if (typeof field.children[i].commitPosition === "function") slider = field.children[i]
            }
            verify(slider !== null)
            mouseClick(slider, slider.width * 0.5, slider.height * 0.5, Qt.LeftButton)
            verify(Math.abs(demo.requested - 100000000) < 3000000)
        }
    }
}
