#!/usr/bin/env python3
"""Native Qt fixture checks, including graceful optional-dependency failures."""
import argparse
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]

def find_runner():
    names = [shutil.which('qmltestrunner6'), shutil.which('qmltestrunner'),
             '/usr/lib/qt6/bin/qmltestrunner', '/usr/lib64/qt6/bin/qmltestrunner']
    return next((p for p in names if p and pathlib.Path(p).is_file()), None)

def run_case(runner, target, env, cwd=None, imports=()):
    command = [runner]
    for directory in imports:
        command.extend(["-import", str(directory)])
    command.extend(["-input", str(target)])
    result = subprocess.run(command, env=env, cwd=cwd,
                            capture_output=True, text=True, timeout=40)
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    invalid = any(s in result.stdout + result.stderr for s in
                  ('TypeError:', 'ReferenceError:', 'Cannot assign to non-existent property'))
    if result.returncode or invalid:
        raise SystemExit(result.returncode or 1)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--previews', type=pathlib.Path,
                        help='Also render native dark/light demo images into this directory')
    args = parser.parse_args()
    runner = find_runner()
    if not runner:
        raise SystemExit('Qt 6 qmltestrunner is required for native fixture tests.')
    env = dict(os.environ)
    env.setdefault('QT_QPA_PLATFORM', 'offscreen')
    env.setdefault('QT_QUICK_BACKEND', 'software')
    env.setdefault('QT_QPA_PLATFORMTHEME', 'kde')
    env['QML_XHR_ALLOW_FILE_READ'] = '1'
    run_case(runner, ROOT / 'tests', env)

    # Shadow only the optional module in this test process; system files stay untouched.
    with tempfile.TemporaryDirectory(prefix='metis-no-native-') as temp:
        module = pathlib.Path(temp) / 'com/github/luisbocanegra/audiovisualizer/process'
        module.mkdir(parents=True)
        (module / 'qmldir').write_text('module com.github.luisbocanegra.audiovisualizer.process\nProcess 1.0 Process.qml\n')
        (module / 'Process.qml').write_text('import QtQuick\nimport Metis.MissingBackendFixture 1.0\nQtObject {}\n')
        missing = dict(env, QML_IMPORT_PATH=temp, QML2_IMPORT_PATH=temp, QML_DISABLE_DISK_CACHE='1')
        run_case(runner, ROOT / 'tests/missing_dependency.qml', missing, imports=(temp,))

    # Let sh run normally but make the optional cava executable unavailable.
    with tempfile.TemporaryDirectory(prefix='metis-no-cava-') as temp:
        shell = shutil.which('sh')
        if not shell:
            raise SystemExit('A POSIX shell is required for the missing-CAVA fixture.')
        (pathlib.Path(temp) / 'sh').symlink_to(shell)
        run_case(runner, ROOT / 'tests/missing_dependency.qml', dict(env, PATH=temp))

    if args.previews:
        destination = args.previews.resolve()
        destination.mkdir(parents=True, exist_ok=True)
        run_case(runner, ROOT / 'scripts/tst_preview.qml', env, cwd=destination)
        print('Native preview images use demo metadata/spectrum, not user account data.')

if __name__ == '__main__':
    main()
