# Metis Desktopbar

**A Spotify-only KDE Plasma panel player with a subtle, live grey audio-spectrum curve.**

Metis Desktopbar places the Spotify icon, track title and artist, playback controls, and a real seek line in a compact horizontal panel field. When Spotify is ready and playing, an optional CAVA analyzer draws a restrained waveform inside that field. The cover, playback timing, full seek control, and additional playback controls remain in the native Plasma popup.

This project is not affiliated with, endorsed by, or sponsored by Spotify AB.

## Features

- Spotify-only MPRIS selection; it does not take control of another media player.
- Clicking the music field opens the detail popup when Spotify is available. If it is not available, an explicit click requests the `spotify:` URI. Spotify is never started automatically.
- Inline play/pause and next controls, each with its own accessible name and tooltip.
- Live position and seek preview; clicking or dragging seeks only when MPRIS reports that seeking is supported.
- Optional grey CAVA output waveform, started only while the selected Spotify player is ready and in the Playing state.
- Native-theme Spotify icon; no bundled hand-drawn logo.
- Compact layout option for 204 px; the regular field is 240 px.
- English source strings, with Plasma's translation mechanism (`i18n`).

## Preview

Native widget renders with **demo metadata and spectrum values**, not screenshots of a user's account:

<img src="docs/screenshots/preview-dark.png" width="720" alt="Dark native widget preview with demo data">

<img src="docs/screenshots/preview-light.png" width="720" alt="Light native widget preview with demo data">

## Install

Requires KDE Plasma 6 with its media-player QML module, a Spotify desktop client, and the Qt 5 compatibility GraphicalEffects QML module used by the popup (the `qt6-5compat` package on Arch/Garuda). No Spotify Web API key, account token, or agent software is needed by this widget.


Install the distributable archive with Plasma's package tool:

```sh
kpackagetool6 --type Plasma/Applet --install metis-desktopbar-0.1.0.plasmoid
```

Then add **Metis Desktopbar** to a **horizontal Plasma panel**. This package targets horizontal panel use; vertical panels and a general desktop-widget layout have not been tested and are not claimed as supported.

## Waveform dependencies (optional)

The player and its popup work without the waveform packages. On the tested Garuda/Chaotic-AUR setup, the optional distribution packages are:

- `cava` — the CAVA analyzer executable.
- `plasma6-applets-kurve` — provides the existing Qt 6 native process QML extension `com.github.luisbocanegra.audiovisualizer.process`. Upstream now calls this project Plasma Audio Visualizer; package names vary by distribution. See its [installation instructions](https://github.com/luisbocanegra/plasma-audio-visualizer). Its widget does not need to be added to your panel.

The applet vendors the small GPL QML integration it needs, but does **not** bundle CAVA, the native extension, compiled binaries, a daemon, or a network/WebSocket process fallback. If CAVA or the native extension is unavailable, the waveform stays still/empty and hovering the music field explains that the optional dependency is missing; playback controls and the popup remain usable. No build step is required during installation.

The visualization is fixed to the reserved PulseAudio/PipeWire-Pulse alias `@DEFAULT_MONITOR@`: the monitor of the system default output sink. There is no device-name entry field or microphone-source selection. The live curve can be disabled in settings. Other sounds routed to that same output may also affect it; if a microphone is deliberately routed into system output, it is part of that output mix. This widget does not open a microphone input, save raw audio files, or display guessed Spotify bitrate/sample-rate claims. The line is a frequency-domain CAVA spectrum, not a time-domain waveform recording.

## Compatibility and test scope

- Declared Plasma API minimum: 6.0.4.
- This initial beta was tested on Garuda Linux, KDE Plasma 6.8.2, Qt 6.12: native controls, real CAVA frame flow and recreation, missing optional dependencies, light/dark rendering, and installation/smoke loading in fresh XDG directories on a private session bus.
- The declared minimum is not a claim that every Plasma 6 minor release has been tested. Only horizontal panel placement is in scope here.
- The optional waveform path uses the installed native process extension API; this source archive does not include or build that binary.

Run the offline checks with Node.js 22+ and Python 3:

```sh
node tests/test_logic.cjs
python3 scripts/build_package.py
```

The Node tests execute the actual QML JavaScript helpers and validate package/dependency contracts. The native Qt tests exercise hover/click/drag and transport hitboxes using fixture players, and the optional audio test checks real output-spectrum data and recreation without changing playback. The negative cases make the native process type or CAVA unavailable and check that the player remains usable.

```sh
python3 scripts/test_native.py
python3 scripts/test_package.py
```

The native checks require the installed KDE QML runtime and Qt 6 `qmltestrunner`. They run offscreen by default; `test_package.py` also uses `kpackagetool6`, `plasmawindowed`, and `dbus-run-session`. Its temporary desktop services are scoped and cleaned up. Optional-audio positive tests may skip on systems without the corresponding dependencies; the supported test environment had them installed and passed without skips. Headless window-shadow/portal warnings are not a claim of a full desktop-session test. No broad compatibility claim is made for other Plasma minor versions.

GitHub CI runs the logic and archive checks. Native Qt/audio/clean-profile checks are separate release checks, not implied by the CI badge.

## License and credits

The project is distributed under **GPL-3.0-only**; see [`LICENSE`](LICENSE). Vendored GPL code and its exact origins, versions, authors, licenses, and package-specific changes are listed in [`THIRD_PARTY.md`](THIRD_PARTY.md).

Copyright (C) 2026 Ruben (ruben2000de). Metis provided AI assistance with implementation and documentation; Ruben is the author/maintainer and takes responsibility for this package. The AI is not a copyright holder or co-author.
