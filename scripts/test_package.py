#!/usr/bin/env python3
"""Install the archive in fresh XDG dirs and smoke-load it on a private D-Bus."""
import hashlib
import json
import os
import pathlib
import signal
import shutil
import time
import subprocess
import tempfile
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / 'dist/metis-desktopbar-0.1.0.plasmoid'
PLUGIN = 'io.github.ruben2000de.metisdesktopbar'

def main():
    for tool in ('kpackagetool6', 'plasmawindowed', 'dbus-run-session'):
        if not shutil.which(tool):
            raise SystemExit(f'{tool} is required for the isolated package smoke test.')
    if not ARCHIVE.is_file():
        raise SystemExit('Build the archive first with scripts/build_package.py.')
    with zipfile.ZipFile(ARCHIVE) as archive:
        names = archive.namelist()
        assert len(names) == len(set(names))
        assert all(not pathlib.PurePosixPath(name).is_absolute()
                   and '..' not in pathlib.PurePosixPath(name).parts for name in names)
        assert json.loads(archive.read('metadata.json'))['KPlugin']['Id'] == PLUGIN
        expected = {name: hashlib.sha256(archive.read(name)).hexdigest() for name in names}
    with tempfile.TemporaryDirectory(prefix='metis-clean-profile-') as temp:
        base = pathlib.Path(temp)
        env = dict(os.environ, XDG_DATA_HOME=str(base / 'data'),
                   XDG_CONFIG_HOME=str(base / 'config'), XDG_CACHE_HOME=str(base / 'cache'),
                   QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
                   QT_QPA_PLATFORMTHEME='kde', QML_XHR_ALLOW_FILE_READ='1')
        for name in ('data', 'config', 'cache'):
            (base / name).mkdir()
        subprocess.run(['kpackagetool6', '--type', 'Plasma/Applet', '--install', str(ARCHIVE)],
                       env=env, check=True, timeout=20)
        installed = base / 'data/plasma/plasmoids' / PLUGIN
        actual = {str(p.relative_to(installed)): hashlib.sha256(p.read_bytes()).hexdigest()
                  for p in installed.rglob('*') if p.is_file()}
        assert actual == expected, 'Installed package bytes differ from the archive'
        # D-Bus-activated children can outlive the viewer and hold pipes open.
        # Keep this test in its own process group, capture into files, and reap
        # the whole owned group without touching the real desktop services.
        with tempfile.TemporaryFile(mode='w+') as out, tempfile.TemporaryFile(mode='w+') as err:
            process = subprocess.Popen(['dbus-run-session', '--', 'plasmawindowed', '--smoke-test', PLUGIN],
                                       env=env, stdout=out, stderr=err, start_new_session=True)
            try:
                code = process.wait(timeout=25)
            except subprocess.TimeoutExpired:
                code = 124
            finally:
                try:
                    os.killpg(process.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait(timeout=3)
                time.sleep(0.2)
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
            out.seek(0); stdout = out.read()
            err.seek(0); stderr = err.read()
        print(stdout)
        print(stderr)
        assert code == 0, 'Native Plasma package smoke failed'
        assert not any(word in stdout + stderr for word in
                       ('TypeError:', 'ReferenceError:', 'Cannot assign to non-existent property',
                        'Unable to assign', 'Error loading QML'))
        print(json.dumps({'fresh_profile': True, 'private_session_bus': True,
                          'package_files_verified': len(actual), 'native_smoke': 'passed'}))

if __name__ == '__main__':
    main()
