// Runs after `flutter build web` (firebase.json hosting.predeploy).
//
// Renames build/web/index.html → app.html. Firebase Hosting always serves an
// exact static file before trying rewrites, so while index.html exists, `/`
// can never reach the `ssr` Cloud Function (server-rendered home page).
// Every non-SSR route is rewritten to /app.html instead, and the function
// fetches /app.html as its template. Local `flutter run` is unaffected.
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', '..', 'build', 'web');
const from = path.join(dir, 'index.html');
const to = path.join(dir, 'app.html');

if (!fs.existsSync(from)) {
  console.error(`finalize_build: ${from} not found — did "flutter build web" run?`);
  process.exit(1);
}
if (fs.existsSync(to)) fs.unlinkSync(to);
fs.renameSync(from, to);
console.log('finalize_build: index.html → app.html');
