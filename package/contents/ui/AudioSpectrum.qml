import QtQuick
import "WaveMath.js" as WaveMath

Item {
    id: root

    property string monitorSource: ""
    property int frameRate: 24
    property int barCount: 48
    property var spectrum: []
    property bool componentReady: false

    readonly property bool sourceValid: WaveMath.isSafeMonitorSource(monitorSource)
    readonly property string statusMessage: {
        if (!sourceValid) {
            return i18n("Live visualization is restricted to the system default audio-output monitor.")
        }
        if (!enabled) {
            return ""
        }
        if (cavaLoader.status === Loader.Error) {
            return i18n("Live waveform unavailable: install CAVA and the optional Kurve native process extension.")
        }
        if (cavaLoader.item && cavaLoader.item.hasError) {
            return i18n("Live waveform could not start. Check the optional CAVA and native process extension packages.")
        }
        return ""
    }

    function configuration() {
        return {
            framerate: Math.max(1, Math.min(60, Math.floor(frameRate))),
            barCount: barCount,
            noiseReduction: 77,
            monstercat: 0,
            waves: 0,
            autoSensitivity: 1,
            sensitivityEnabled: false,
            sensitivity: 100,
            lowerCutoffFreq: 50,
            higherCutoffFreq: 10000,
            inputMethod: "pulse",
            inputSource: monitorSource,
            sampleRate: 44100,
            sampleBits: 16,
            inputChannels: 2,
            autoconnect: 2,
            active: 0,
            remix: 1,
            virtual: 1,
            outputChannels: "mono",
            monoOption: "average",
            reverse: 0,
            waveform: 0,
            eqEnabled: false,
            eq: [],
            idleCheck: false,
            idleTimer: 5,
            cavaSleepTimer: 5,
            asciiMaxRange: 100
        }
    }

    function startBackend() {
        if (!componentReady || !enabled || !sourceValid) {
            return
        }
        if (cavaLoader.item) {
            cavaLoader.item.start()
            return
        }
        if (cavaLoader.status === Loader.Loading) {
            return
        }
        cavaLoader.setSource(Qt.resolvedUrl("vendor/kurve/Cava.qml"), configuration())
        cavaLoader.active = true
    }

    function stopBackend() {
        if (cavaLoader.item) {
            cavaLoader.item.stop()
        }
        spectrum = []
    }

    function restartBackend() {
        if (!componentReady) {
            return
        }
        stopBackend()
        cavaLoader.active = false
        cavaLoader.source = ""
        if (enabled && sourceValid) {
            Qt.callLater(function() { root.startBackend() })
        }
    }

    Loader {
        id: cavaLoader
        active: false
        asynchronous: false
        onLoaded: {
            if (root.enabled && root.sourceValid) {
                item.start()
                root.spectrum = item.values
            } else {
                item.stop()
            }
        }
    }

    Connections {
        target: cavaLoader.item
        enabled: cavaLoader.item !== null
        function onValuesChanged() {
            root.spectrum = cavaLoader.item ? cavaLoader.item.values : []
        }
    }

    onEnabledChanged: {
        if (!componentReady) return
        if (enabled && sourceValid) startBackend()
        else stopBackend()
    }
    onMonitorSourceChanged: restartBackend()
    onFrameRateChanged: restartBackend()

    Component.onCompleted: {
        componentReady = true
        startBackend()
    }
    Component.onDestruction: stopBackend()
}
