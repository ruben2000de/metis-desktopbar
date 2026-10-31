import QtQuick
import QtTest
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import "../package/contents/ui" as Bar

Item {
    width: 270
    height: 120
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
        property string artists: "Preview data"
        property double songLength: 200000000
        property double songPosition: 76000000
        function setPosition(position) { }
        function playPause() { }
        function next() { }
    }
    Bar.MusicField {
        id: dark
        x: 10; y: 10
        width: 240; height: 42
        player: demo
        audioSamples: [0, 5, 12, 26, 14, 7, 32, 21, 10, 6, 18, 9, 3, 0]
        Kirigami.Theme.inherit: false
        Kirigami.Theme.backgroundColor: "#202124"
        Kirigami.Theme.textColor: "#f0f0f0"
    }
    Bar.MusicField {
        id: light
        x: 10; y: 65
        width: 240; height: 42
        player: demo
        audioSamples: dark.audioSamples
        Kirigami.Theme.inherit: false
        Kirigami.Theme.backgroundColor: "#f5f5f5"
        Kirigami.Theme.textColor: "#202124"
    }
    TestCase {
        name: "NativeThemePreviews"
        when: windowShown
        function save(item, filename) {
            var done = false
            var okay = false
            item.grabToImage(function(result) {
                okay = result.saveToFile(filename)
                done = true
            }, Qt.size(item.width * 3, item.height * 3))
            tryVerify(function() { return done }, 3000)
            verify(okay, "Could not save " + filename)
        }
        function test_render() {
            mouseMove(parent, 0, 0)
            wait(250)
            compare(dark.lightSurface, false)
            compare(light.lightSurface, true)
            save(dark, "preview-dark.png")
            save(light, "preview-light.png")
        }
    }
}
