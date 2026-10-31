#!/usr/bin/env python3
"""Build and validate the local, reviewable Plasma applet archive."""
from __future__ import annotations

import json
import stat
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "package"
DIST = ROOT / "dist"
REQUIRED_DOCS = ("README.md", "LICENSE", "THIRD_PARTY.md")
BLOCKED_MARKERS = (
    b"/opt" + b"/data",
    b"/home" + b"/user",
    b"org.metis" + b".desktopbar",
    b"garuda" + b"-desktop",
    b"garuda" + b"-laptop",
    b"file:///usr/share/" + b"plasma/plasmoids/",
)
ALLOWED_SUFFIXES = {".json", ".qml", ".js", ".xml"}
BINARY_SUFFIXES = {".so", ".dll", ".dylib", ".exe", ".pyc", ".bin"}


def validate_tree() -> tuple[dict, list[Path]]:
    metadata_path = PACKAGE / "metadata.json"
    if not metadata_path.is_file():
        raise SystemExit("package/metadata.json is missing")
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    plugin = metadata.get("KPlugin", {})
    expected = {
        "Id": "io.github.ruben2000de.metisdesktopbar",
        "Version": "0.1.0",
        "License": "GPL-3.0-only",
    }
    for key, value in expected.items():
        if plugin.get(key) != value:
            raise SystemExit(f"metadata KPlugin.{key} must be {value!r}")
    authors = plugin.get("Authors", [])
    if not authors or authors[0].get("Name") != "Ruben (ruben2000de)":
        raise SystemExit("metadata must name Ruben (ruben2000de) as author")

    source_files = sorted(path for path in PACKAGE.rglob("*") if path.is_file())
    if not any(path.relative_to(PACKAGE).as_posix() == "contents/ui/main.qml" for path in source_files):
        raise SystemExit("contents/ui/main.qml is missing")

    for path in source_files:
        rel = path.relative_to(PACKAGE).as_posix()
        data = path.read_bytes()
        if path.suffix.lower() in BINARY_SUFFIXES or data.startswith(b"\x7fELF"):
            raise SystemExit(f"compiled/binary payload is forbidden: {rel}")
        if path.suffix.lower() not in ALLOWED_SUFFIXES:
            raise SystemExit(f"unexpected package file type: {rel}")
        lowered = data.lower()
        for marker in BLOCKED_MARKERS:
            if marker in lowered:
                raise SystemExit(f"private/removed feature marker {marker.decode(errors='replace')!r} in {rel}")

    for doc in REQUIRED_DOCS:
        if not (ROOT / doc).is_file():
            raise SystemExit(f"required distributable notice is missing: {doc}")
    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    if "GNU GENERAL PUBLIC LICENSE" not in license_text or "Version 3" not in license_text:
        raise SystemExit("LICENSE must contain the full GPL version 3 text")

    return metadata, source_files


def build() -> Path:
    metadata, source_files = validate_tree()
    version = metadata["KPlugin"]["Version"]
    output = DIST / f"metis-desktopbar-{version}.plasmoid"
    DIST.mkdir(parents=True, exist_ok=True)

    entries: list[tuple[str, Path]] = [("metadata.json", PACKAGE / "metadata.json")]
    entries.extend(
        (path.relative_to(PACKAGE).as_posix(), path)
        for path in source_files
        if path != PACKAGE / "metadata.json"
    )
    entries.extend((doc, ROOT / doc) for doc in REQUIRED_DOCS)
    entries.sort(key=lambda row: (row[0] != "metadata.json", row[0]))

    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for arcname, path in entries:
            info = zipfile.ZipInfo(arcname, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            archive.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)

    with zipfile.ZipFile(output, "r") as archive:
        names = archive.namelist()
        if not names or names[0] != "metadata.json":
            raise SystemExit("archive must place metadata.json at its root")
        if any(name.startswith("package/") or name.startswith("../") or name.startswith("/") for name in names):
            raise SystemExit("archive contains an invalid root path")
        for doc in REQUIRED_DOCS:
            if doc not in names:
                raise SystemExit(f"archive is missing {doc}")
        packaged_metadata = json.loads(archive.read("metadata.json"))
        if packaged_metadata != metadata:
            raise SystemExit("archive metadata differs from package source")
        if len(names) != len(set(names)):
            raise SystemExit("archive contains duplicate paths")
        for name in names:
            payload = archive.read(name)
            if payload.startswith(b"\x7fELF") or name.lower().endswith(tuple(BINARY_SUFFIXES)):
                raise SystemExit(f"archive includes a compiled/binary payload: {name}")

    print(f"Built {output}")
    print(f"Root entries: {len(entries)}; QML/JS/XML/JSON package files: {len(source_files)}")
    print("Validated root metadata, GPL-3.0-only license, notices, private-feature/path exclusions, and no binaries.")
    return output


if __name__ == "__main__":
    build()
