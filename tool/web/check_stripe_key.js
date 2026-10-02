// Hosting predeploy guard: refuses to build/deploy the web app unless
// config/stripe_live.json holds a real live publishable key, so a deploy can
// never ship the placeholder or a test key by mistake.
const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, '..', '..', 'config', 'stripe_live.json');
const key = JSON.parse(fs.readFileSync(file, 'utf8')).STRIPE_PUBLISHABLE_KEY || '';

if (!/^pk_live_[A-Za-z0-9]{20,}$/.test(key) || key.includes('REPLACE_ME')) {
  console.error('config/stripe_live.json must contain a real pk_live_... publishable key. Aborting deploy.');
  process.exit(1);
}
