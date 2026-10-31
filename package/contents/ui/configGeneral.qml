import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    property alias cfg_compactMode: compactModeCheck.checked
    property alias cfg_showWaveform: waveformCheck.checked
    property alias cfg_desktopAudioFrameRate: desktopRate.value
    property alias cfg_laptopAudioFrameRate: laptopRate.value

    Kirigami.FormLayout {
        Layout.fillWidth: true
        Controls.CheckBox {
            id: compactModeCheck
            Kirigami.FormData.label: i18n("Layout:")
            text: i18n("Compact laptop width (204 px)")
        }
        Controls.CheckBox {
            id: waveformCheck
            Kirigami.FormData.label: i18n("Visualization:")
            text: i18n("Show the live audio-spectrum curve")
        }
        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Uses only the system default audio-output monitor. Microphone inputs and custom device names are not selectable.")
            opacity: 0.82
        }
        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("The live waveform requires the optional CAVA package and the Kurve native process extension. Without them, the player and popup still work; hover over the music field for the status.")
            opacity: 0.82
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Desktop CAVA rate:")
            Controls.SpinBox { id: desktopRate; from: 1; to: 60; value: 24 }
            Controls.Label { text: i18n("frames/s") }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Compact CAVA rate:")
            Controls.SpinBox { id: laptopRate; from: 1; to: 60; value: 12 }
            Controls.Label { text: i18n("frames/s") }
        }
    }
}
