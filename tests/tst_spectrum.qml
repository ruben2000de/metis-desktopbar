import QtQuick
import QtTest
import "../package/contents/ui" as Bar

Item {
    width: 240; height: 42
    function i18n(text) { return text }
    Loader {
        id: analysis
        active: false
        sourceComponent: Bar.AudioSpectrum {
            enabled: true
            monitorSource: "@DEFAULT_MONITOR@"
            frameRate: 12
            barCount: 48
        }
    }
    TestCase {
        name: "LiveOutputSpectrum"
        when: windowShown
        function cleanup() { analysis.active = false }
        function test_real_frames_and_recreation() {
            analysis.active = true
            tryVerify(function() {
                return analysis.item && (analysis.item.spectrum.length > 0 || analysis.item.statusMessage.length > 0)
            }, 4000)
            if (analysis.item.statusMessage.length > 0) {
                skip("Optional visualization dependencies unavailable: " + analysis.item.statusMessage)
            }
            verify(analysis.item.spectrum.length > 0)
            analysis.active = false
            compare(analysis.item, null)
            wait(100)
            analysis.active = true
            tryVerify(function() { return analysis.item && analysis.item.spectrum.length > 0 }, 4000)
            compare(analysis.item.statusMessage, "")
        }
    }
}
