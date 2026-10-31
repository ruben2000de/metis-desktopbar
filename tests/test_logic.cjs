const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { execFileSync } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const packageRoot = path.join(root, 'package');
function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}
function loadQmlScript(relativePath) {
  const filename = path.join(packageRoot, relativePath);
  const context = { module: { exports: {} } };
  vm.runInNewContext(fs.readFileSync(filename, 'utf8'), context, { filename });
  return context.module.exports;
}

const WaveMath = loadQmlScript('contents/ui/WaveMath.js');
const SeekMath = loadQmlScript('contents/ui/SeekMath.js');
let passed = 0;
function test(name, fn) {
  fn();
  passed += 1;
  process.stdout.write(`ok ${passed} - ${name}\n`);
}

const outputMonitor = '@DEFAULT_MONITOR@';

test('accepts only the reserved default-output monitor and rejects every free-form source', () => {
  assert.equal(WaveMath.isSafeMonitorSource('@DEFAULT_MONITOR@'), true);
  for (const value of [
    'microphone.monitor', 'ordinary-output.monitor', 'alsa_output.usb-test.analog-stereo.monitor', '@DEFAULT_SOURCE@',
    '', 'default', 'alsa_input.device.monitor', 'bluez_input.device.monitor',
    'pipewire_input.device.monitor', 'jack_input.device.monitor', 'source.mic.monitor',
    'alsa_output.device.monitor\nmethod=alsa', 'x.monitor;id', 'x.monitor\u0000',
    'x.monitor'.repeat(30)
  ]) {
    assert.equal(WaveMath.isSafeMonitorSource(value), false, JSON.stringify(value));
  }
});

test('audio analysis runs only for a ready player in Playing state with a validated output monitor', () => {
  assert.equal(WaveMath.shouldRunAudio(true, 1, 1, outputMonitor), true);
  assert.equal(WaveMath.shouldRunAudio(true, 1, 1, '@DEFAULT_MONITOR@'), true);
  assert.equal(WaveMath.shouldRunAudio(false, 1, 1, outputMonitor), false);
  assert.equal(WaveMath.shouldRunAudio(true, 2, 1, outputMonitor), false);
  assert.equal(WaveMath.shouldRunAudio(true, 1, 1, ''), false);
  assert.equal(WaveMath.shouldRunAudio(true, 1, 1, 'alsa_input.mic.monitor'), false);
});

test('missing player leads to a click-only Spotify request; a ready player opens details', () => {
  assert.equal(WaveMath.musicClickAction(false), 'launch');
  assert.equal(WaveMath.musicClickAction(true), 'popup');
  const main = read('package/contents/ui/main.qml');
  assert.match(main, /sourceIdentities:\s*\["Spotify"\]/);
  assert.match(main, /function handleMusicClick\(\)/);
  assert.match(main, /Qt\.openUrlExternally\("spotify:"\)/);
  assert.match(main, /onPrimaryActivated:\s*widget\.handleMusicClick\(\)/);
  assert.doesNotMatch(main, /Component\.onCompleted[^}]*openUrlExternally/s);
});

test('interpolates real CAVA bins, clamps range, and does not synthesize a waveform', () => {
  assert.deepEqual(Array.from(WaveMath.interpolate([0, 100], 5, 100)), [0, 25, 50, 75, 100]);
  assert.deepEqual(Array.from(WaveMath.interpolate([-9, 40, 140], 3, 100)), [0, 40, 100]);
  assert.deepEqual(Array.from(WaveMath.interpolate([12], 4, 100)), [12, 12, 12, 12]);
  assert.deepEqual(Array.from(WaveMath.interpolate([0, Number.NaN, 100], 3, 100)), [0, 50, 100]);
  assert.deepEqual(Array.from(WaveMath.interpolate([], 12, 100)), []);
  assert.deepEqual(Array.from(WaveMath.interpolate([1, 2], 1, 100)), []);
  const wave = read('package/contents/ui/AudioWave.qml');
  assert.doesNotMatch(wave, /Math\.(?:random|sin|cos)|NumberAnimation/);
});

test('seek helpers clamp to track bounds, reject unknown duration, and format elapsed time', () => {
  assert.equal(SeekMath.targetPosition(0.5, 200000000), 100000000);
  assert.equal(SeekMath.targetPosition(-1, 200000000), 0);
  assert.equal(SeekMath.targetPosition(1.2, 200000000), 199999999);
  assert.equal(SeekMath.targetPosition(0.5, 0), null);
  assert.equal(SeekMath.targetPosition(Number.NaN, 200000000), null);
  assert.equal(SeekMath.formatTime(243000000), '4:03');
  assert.equal(SeekMath.formatTime(3723000000), '1:02:03');
});

test('inline seek is capability-gated and leaves the verified transport-button boundary intact', () => {
  const music = read('package/contents/ui/MusicField.qml');
  assert.match(music, /player\.canSeek/);
  assert.match(music, /root\.player\.setPosition\(target\)/);
  assert.match(music, /SeekMath\.formatTime\(target\)/);
  assert.match(music, /when: !seekSlider\.pressed/);
  assert.equal((music.match(/controls\.x \+ playPauseButton\.x - x - 7/g) || []).length, 2);
});

test('field pairs theme text with a theme-aware surface and adapts grey wave contrast', () => {
  const music = read('package/contents/ui/MusicField.qml');
  assert.match(music, /Kirigami\.Theme\.colorSet:\s*Kirigami\.Theme\.View/);
  assert.match(music, /Kirigami\.Theme\.backgroundColor/);
  assert.match(music, /fieldColor: lightSurface \? Kirigami\.Theme\.backgroundColor : "#101213"/);
  assert.match(music, /lightSurface \? "#555b60" : "#a5aaaa"/);
  assert.match(music, /color: Kirigami\.Theme\.textColor/);
});

test('vendored QML imports and popup configuration resolve within the package tree', () => {
  const qmlFiles = fs.readdirSync(packageRoot, { recursive: true }).filter(name => name.endsWith('.qml'));
  const configText = read('package/contents/config/main.xml');
  const configNames = new Set(Array.from(configText.matchAll(/<entry name="([^"]+)"/g), match => match[1]));
  const missingConfig = new Set();
  for (const relative of qmlFiles) {
    const filename = path.join(packageRoot, relative);
    const source = fs.readFileSync(filename, 'utf8');
    for (const [, name] of source.matchAll(/plasmoid\.configuration\.([A-Za-z0-9_]+)/g)) {
      if (!configNames.has(name)) missingConfig.add(name);
    }
    for (const [, importPath] of source.matchAll(/^\s*import\s+"([^"]+)"/gm)) {
      const target = path.resolve(path.dirname(filename), importPath);
      assert.ok(fs.existsSync(target), `${relative} has unresolved local import ${importPath}`);
    }
  }
  assert.deepEqual([...missingConfig], []);
  const main = read('package/contents/ui/main.qml');
  assert.doesNotMatch(main, /Plasma5Support|DataSource|connectedSources/);
  assert.ok(fs.existsSync(path.join(packageRoot, 'contents/ui/vendor/kurve/Cava.qml')));
});

test('native visualization backend fails closed without WebSocket or PID helper fallback', () => {
  const monitor = read('package/contents/ui/vendor/kurve/components/ProcessMonitor.qml');
  const native = read('package/contents/ui/vendor/kurve/components/ProcessMonitorNative.qml');
  const cava = read('package/contents/ui/vendor/kurve/Cava.qml');
  assert.match(native, /import com\.github\.luisbocanegra\.audiovisualizer\.process/);
  assert.match(native, /Process\s*\{/);
  assert.match(monitor, /status === Loader\.Error/);
  assert.doesNotMatch(monitor + native + cava, /QtWebSockets|WebSocketServer|ProcessMonitorFallback\.qml|commandMonitorTool/);
  assert.match(read('package/contents/ui/AudioSpectrum.qml'), /optional Kurve native process extension/);
  assert.match(read('package/contents/ui/MusicField.qml'), /visualizationMessage/);
});

test('public package has a stable identity, named human maintainer, GPL metadata, and horizontal-only guidance', () => {
  const metadata = JSON.parse(read('package/metadata.json'));
  assert.equal(metadata.KPlugin.Id, 'io.github.ruben2000de.metisdesktopbar');
  assert.equal(metadata.KPlugin.Version, '0.1.0');
  assert.equal(metadata.KPlugin.License, 'GPL-3.0-only');
  assert.deepEqual(metadata.KPlugin.Authors, [{ Name: 'Ruben (ruben2000de)' }]);
  assert.match(read('README.md'), /horizontal Plasma panel/i);
  assert.match(read('README.md'), /not been tested and are not claimed as supported/i);
  assert.match(read('README.md'), /AI assistance with implementation and documentation/i);
  assert.match(read('THIRD_PARTY.md'), /Claudio Catterina/);
  assert.match(read('THIRD_PARTY.md'), /Luis Bocanegra/);
});

test('package source contains no private paths/features, and archive root is distributable', () => {
  const blocked = [
    new RegExp('/opt' + '/data', 'i'), new RegExp('/home' + '/user', 'i'),
    new RegExp('org.metis' + '.desktopbar', 'i'), new RegExp('garuda' + '-desktop', 'i'),
    new RegExp('garuda' + '-laptop', 'i'),
    new RegExp('file:///usr/share/' + 'plasma/plasmoids', 'i')
  ];
  for (const entry of fs.readdirSync(packageRoot, { recursive: true })) {
    const filename = path.join(packageRoot, entry);
    if (!fs.statSync(filename).isFile()) continue;
    const content = fs.readFileSync(filename);
    assert.equal(content.includes(0), false, `NUL byte in ${entry}`);
    const text = content.toString('utf8');
    for (const pattern of blocked) assert.doesNotMatch(text, pattern, `${entry} matched ${pattern}`);
    assert.ok(['.qml', '.js', '.xml', '.json'].includes(path.extname(filename).toLowerCase()), entry);
  }
  const archive = path.join(root, 'dist/metis-desktopbar-0.1.0.plasmoid');
  execFileSync('python3', [path.join(root, 'scripts/build_package.py')], { stdio: 'pipe' });
  const names = execFileSync('python3', ['-c',
    'import sys,zipfile; z=zipfile.ZipFile(sys.argv[1]); print("\\n".join(z.namelist()))', archive],
    { encoding: 'utf8' }).trim().split('\n');
  assert.equal(names[0], 'metadata.json');
  assert.ok(names.includes('contents/ui/main.qml'));
  assert.ok(names.includes('LICENSE'));
  assert.ok(names.includes('THIRD_PARTY.md'));
  assert.ok(names.includes('README.md'));
  assert.ok(!names.some(name => name.startsWith('package/')));
});

test('production capture source is fixed and no device-name setting is exposed', () => {
  const main = read('package/contents/ui/main.qml');
  const config = read('package/contents/config/main.xml');
  const settings = read('package/contents/ui/configGeneral.qml');
  assert.match(main, /readonly property string audioSource:\s*"@DEFAULT_MONITOR@"/);
  assert.doesNotMatch(main, /configuration\.audioSource/);
  assert.doesNotMatch(config, /entry name="audioSource"/);
  assert.match(config, /entry name="showWaveform" type="Bool"/);
  assert.match(main, /configuration\.showWaveform && WaveMath\.shouldRunAudio/);
  assert.doesNotMatch(settings, /TextField|cfg_audioSource/);
});

process.stdout.write(`1..${passed}\n`);
