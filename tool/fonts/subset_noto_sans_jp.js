// Builds the Japanese subset of Noto Sans JP used by the app in 日本語 mode.
// Coverage: ASCII + Latin-1, general punctuation, CJK symbols, hiragana,
// katakana, full/half-width forms, and every character in JIS X 0208 (the
// Shift_JIS double-byte set: JIS level 1 + level 2 kanji, 6,355 kanji) —
// i.e. everything a normal Japanese product name or UI string uses.
// Anything outside it still renders through Flutter's own font fallback.
//
// To regenerate (only needed if the character set or source font changes):
//   1. Download the static TTFs next to this script:
//        https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;700
//        (fetch that CSS with plain curl — it lists the two full .ttf URLs)
//      saved as NotoSansJP-Regular.ttf and NotoSansJP-Bold.ttf
//   2. npm install subset-font@2
//   3. node subset_noto_sans_jp.js ../../assets/fonts/jp
//   4. Rename the output files (e.g. -v2) and update JapaneseFont's paths —
//      firebase.json caches fonts as immutable, so a changed file under the
//      same name would not reach returning visitors.
const fs = require('fs');
const subsetFont = require('subset-font');

const OUT = process.argv[2];
const chars = new Set();
const addRange = (a, b) => { for (let c = a; c <= b; c++) chars.add(String.fromCodePoint(c)); };

addRange(0x20, 0x7e);     // ASCII
addRange(0xa0, 0xff);     // Latin-1 (incl. ¥ ×)
addRange(0x2000, 0x206f); // general punctuation (— … ‘ ’ “ ”)
addRange(0x2190, 0x21ff); // arrows
addRange(0x2460, 0x24ff); // enclosed numbers ① ②
addRange(0x25a0, 0x25ff); // geometric shapes ■ ● ◯
addRange(0x3000, 0x303f); // CJK symbols & punctuation 、。「」
addRange(0x3040, 0x309f); // hiragana
addRange(0x30a0, 0x30ff); // katakana
addRange(0x31f0, 0x31ff); // katakana phonetic extensions
addRange(0xff00, 0xffef); // full-width / half-width forms

// JIS X 0208 via the Shift_JIS decoder: lead bytes 0x81–0x9F, 0xE0–0xEF.
const sjis = new TextDecoder('shift_jis', { fatal: false });
for (const lead of [...Array(0x1f).keys()].map((i) => 0x81 + i).concat([...Array(0x10).keys()].map((i) => 0xe0 + i))) {
  for (let trail = 0x40; trail <= 0xfc; trail++) {
    if (trail === 0x7f) continue;
    const ch = sjis.decode(new Uint8Array([lead, trail]));
    if (ch && ch !== '�' && ch.length === 1) chars.add(ch);
  }
}

const text = [...chars].join('');
const kanji = [...chars].filter((c) => /\p{Script=Han}/u.test(c)).length;
console.log(`characters: ${chars.size} (kanji: ${kanji})`);

(async () => {
  for (const weight of ['Regular', 'Bold']) {
    const src = fs.readFileSync(`NotoSansJP-${weight}.ttf`);
    const out = await subsetFont(src, text, { targetFormat: 'truetype' });
    fs.writeFileSync(`${OUT}/NotoSansJP-${weight}.ttf`, out);
    const br = require('zlib').brotliCompressSync(out).length;
    console.log(`NotoSansJP-${weight}: ${(src.length / 1048576).toFixed(2)} MB → ${(out.length / 1048576).toFixed(2)} MB (brotli ${(br / 1048576).toFixed(2)} MB)`);
  }
})();
