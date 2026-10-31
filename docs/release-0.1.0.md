# Metis Desktopbar 0.1.0 — initial public beta

A Spotify-only horizontal KDE Plasma panel player with a compact native UI and an optional grey audio-spectrum curve.

- Track/artist, play/pause, next, native cover/timing popup.
- Hover target time; click or drag to seek.
- Dark/light palette support and compact laptop width.
- Optional visualization via CAVA and the existing native Process extension from Plasma Audio Visualizer/Kurve.
- Fixed default-output-monitor source; no microphone-source selector, WebSocket fallback, account token, or agent dependency.

**Install:** download `metis-desktopbar-0.1.0.plasmoid` and run:

```sh
kpackagetool6 --type Plasma/Applet --install metis-desktopbar-0.1.0.plasmoid
```

Then add Metis Desktopbar to a horizontal panel. See README for required and optional distribution packages. The player remains usable without the optional visualization dependencies.

Tested on Garuda / Plasma 6.8.2 / Qt 6.12. This is an initial beta, not a promise of compatibility with every Plasma 6 release. Preview images use clearly marked demo data.

GPL-3.0-only. Contains attributed GPL QML from PlasMusic Toolbar (Claudio Catterina) and Kurve (Luis Bocanegra). See LICENSE and THIRD_PARTY.md. Developed with disclosed AI assistance; no claim of Spotify endorsement.
