import QtQuick
import QtTest
import org.kde.plasma.private.mpris as Mpris
import "../package/contents/ui" as Bar

Item {
    width: 240
    height: 42

    function i18n(text) { return text }

    QtObject {
        id: fixture
        property bool ready: true
        property int playbackStatus: Mpris.PlaybackStatus.Playing
        property bool canSeek: true
        property bool canPlay: true
        property bool canPause: true
        property bool canGoNext: true
        property string title: "Demo track"
        property string artists: "Demo artist"
        property double songLength: 200000000
        property double songPosition: 20000000
        property double lastPosition: -1
        property int seekCalls: 0
        function setPosition(position) { lastPosition = position; seekCalls++; songPosition = position }
        function playPause() { }
        function next() { }
    }

    Bar.MusicField {
        id: field
        anchors.fill: parent
        player: fixture
        audioSamples: [0, 20, 50, 10, 0]
        visualizationMessage: "Demo-only visualization status"
    }

    TestCase {
        name: "PublicInlineSeek"
        when: windowShown

        function slider() {
            for (var i = 0; i < field.children.length; i++) {
                if (typeof field.children[i].commitPosition === "function") return field.children[i]
            }
            fail("Native seek Slider missing")
        }

        function init() {
            fixture.canSeek = true
            fixture.songPosition = 20000000
            fixture.lastPosition = -1
            fixture.seekCalls = 0
            mouseMove(field, 2, 2)
            wait(30)
        }

        function test_hover_does_not_seek() {
            var s = slider()
            mouseMove(s, s.width * 0.5, s.height * 0.5)
            tryCompare(s, "hoverActive", true)
            compare(fixture.seekCalls, 0)
            compare(fixture.songPosition, 20000000)
        }

        function test_click_seeks_to_track_midpoint() {
            var s = slider()
            mouseClick(s, s.width * 0.5, s.height * 0.5, Qt.LeftButton)
            verify(fixture.seekCalls >= 1)
            verify(Math.abs(fixture.lastPosition - 100000000) < 3000000,
                   "Unexpected target: " + fixture.lastPosition)
        }

        function test_drag_commits_target() {
            var s = slider()
            mousePress(s, s.width * 0.2, s.height * 0.5, Qt.LeftButton)
            mouseMove(s, s.width * 0.75, s.height * 0.5)
            mouseRelease(s, s.width * 0.75, s.height * 0.5, Qt.LeftButton)
            verify(fixture.seekCalls >= 1)
            verify(fixture.lastPosition > 140000000 && fixture.lastPosition < 165000000,
                   "Unexpected drag target: " + fixture.lastPosition)
        }

        function findButton(item, iconName) {
            if (item.icon && item.icon.name === iconName) return item
            var kids = item.children || []
            for (var i = 0; i < kids.length; i++) {
                var found = findButton(kids[i], iconName)
                if (found) return found
            }
            return null
        }

        function test_seek_surface_does_not_overlap_transport_buttons() {
            var pause = findButton(field, "media-playback-pause")
            var next = findButton(field, "media-skip-forward")
            verify(pause !== null && next !== null)
            mouseMove(pause, pause.width / 2, pause.height / 2)
            tryCompare(pause, "hovered", true)
            mouseMove(pause, 2, pause.height - 2)
            tryCompare(pause, "hovered", true)
            compare(slider().hoverActive, false, "Seek region overlaps pause button")
            mouseMove(next, next.width / 2, next.height / 2)
            tryCompare(next, "hovered", true)
            compare(slider().hoverActive, false)
        }

        function test_unsupported_seek_is_disabled() {
            fixture.canSeek = false
            var s = slider()
            compare(s.enabled, false)
            mouseClick(s, s.width * 0.5, s.height * 0.5, Qt.LeftButton)
            compare(fixture.seekCalls, 0)
        }
    }
}
