// Runs after `flutter build web` (firebase.json hosting.predeploy).
//
// 1. Renames build/web/index.html → app.html. Firebase Hosting always serves
//    an exact static file before trying rewrites, so while index.html
//    exists, `/` can never reach the `ssr` Cloud Function (server-rendered
//    home page). Every non-SSR route is rewritten to /app.html instead, and
//    the function fetches /app.html as its template. Local `flutter run` is
//    unaffected.
//
// 2. Points web/index.html's Firebase JS SDK `modulepreload` hints at the
//    SDK version the installed firebase_core_web actually loads. A stale
//    version (e.g. after a `flutter pub` upgrade) is worse than no hint: the
//    browser downloads ~270 KB of the old SDK for nothing, then fetches the
//    real one late, on the path to the first frame (measured: +1–3 s on a
//    6 Mbps link).
const fs = require('fs');
const os = require('os');
const path = require('path');

const root = path.join(__dirname, '..', '..');
const dir = path.join(root, 'build', 'web');
const from = path.join(dir, 'index.html');
const to = path.join(dir, 'app.html');

if (!fs.existsSync(from)) {
  console.error(`finalize_build: ${from} not found — did "flutter build web" run?`);
  process.exit(1);
}

let html = fs.readFileSync(from, 'utf8');
const sdkVersion = firebaseJsSdkVersion();
if (sdkVersion) {
  const before = html;
  html = html.replace(/firebasejs\/\d+\.\d+\.\d+\//g, `firebasejs/${sdkVersion}/`);
  if (html !== before) console.log(`finalize_build: Firebase JS SDK preloads → ${sdkVersion}`);
} else {
  console.warn('finalize_build: could not determine the Firebase JS SDK version — preload hints left unchanged');
}

if (fs.existsSync(to)) fs.unlinkSync(to);
fs.writeFileSync(to, html);
fs.unlinkSync(from);
console.log('finalize_build: index.html → app.html');

/** `supportedFirebaseJsSdkVersion` from the firebase_core_web version in pubspec.lock. */
function firebaseJsSdkVersion() {
  try {
    const lock = fs.readFileSync(path.join(root, 'pubspec.lock'), 'utf8');
    const match = lock.match(/\n  firebase_core_web:\n(?:    .*\n)*?    version: "([^"]+)"/);
    if (!match) return null;
    const pubCache = process.env.PUB_CACHE ||
      (process.platform === 'win32'
        ? path.join(process.env.LOCALAPPDATA || '', 'Pub', 'Cache')
        : path.join(os.homedir(), '.pub-cache'));
    const source = fs.readFileSync(
      path.join(pubCache, 'hosted', 'pub.dev', `firebase_core_web-${match[1]}`, 'lib', 'src', 'firebase_sdk_version.dart'),
      'utf8',
    );
    return (source.match(/supportedFirebaseJsSdkVersion\s*=\s*'([^']+)'/) || [])[1] || null;
  } catch (_) {
    return null;
  }
}
