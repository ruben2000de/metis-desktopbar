# Third-party notices

Metis Desktopbar is distributed under GPL-3.0-only. The complete license text is in [`LICENSE`](LICENSE). The following upstream code remains under its original GPL terms; it is included here to avoid an install-time dependency on another plasmoid's private QML path.

## PlasMusic Toolbar

- Upstream: [ccatterina/plasmusic-toolbar](https://github.com/ccatterina/plasmusic-toolbar)
- Version sourced: **4.3.1** (installed package `plasma6-applets-plasmusic-toolbar`)
- Original author: **Claudio Catterina**
- Upstream metadata license: **GPL3**
- Vendored files: `package/contents/ui/vendor/plasmusic/Player.qml`, `Full.qml`, and `components/`.
- The source files are vendored from the installed package. The public applet pins the player identity to Spotify and uses the upstream full-view components for its popup; it does not load files from `/usr/share/plasma/plasmoids/plasmusic-toolbar` at runtime.

## Kurve / Plasma Audio Visualizer

- Upstream: [luisbocanegra/plasma-audio-visualizer](https://github.com/luisbocanegra/plasma-audio-visualizer) (Kurve 3.6.0 source; upstream tag `v3.6.0`)
- Original author: **Luis Bocanegra**
- Upstream metadata license: **GPL-3.0**
- Vendored code: `package/contents/ui/vendor/kurve/Cava.qml`; the native-only process wrapper in `package/contents/ui/vendor/kurve/components/` is adapted from upstream's `ProcessMonitorPrimary.qml`.
- Modified for Metis Desktopbar on 2026-10-31. The native adapter uses the upstream `restart()`/`stop()` API. Arbitrary source selection is not exposed; the applet fixes visualization to the reserved default-output-monitor alias.
- Changes: process QML is loaded dynamically so a missing native module can fail closed without taking down the player UI; only the native `Process` backend is used. The Python/WebSocket PID-control fallback and its tools are not included or enabled. CAVA is launched only while the Spotify MPRIS source is ready and Playing. The extension itself is not bundled.

## Runtime dependencies that are not bundled

CAVA is an optional system program ([CAVA](https://github.com/karlstav/cava)); the applet does not include it. On Arch Linux/Garuda it is provided by `cava`. The optional native Qt module comes from `plasma6-applets-kurve` on Arch Linux/Garuda. These packages are needed only for live visualization. KDE Plasma 6 and its MPRIS/Plasma QML runtime are needed for the applet and popup.

No Spotify artwork or logo is bundled; the applet requests the `spotify` icon from the active icon theme.
