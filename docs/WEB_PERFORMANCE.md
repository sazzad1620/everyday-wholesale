# Web Performance — What Changed & Status

The live site took 2–5 s of blank white screen before anything appeared, and images loaded slowly (especially from Bangladesh). Measured causes, then fixes. Hosting itself was never the problem: Firebase Hosting serves from a global CDN and the site's own files came back in ~0.3 s.

## 1. Measured causes (before)

| Cause | Detail |
|---|---|
| Flutter web engine + app download | CanvasKit engine ~1.6–1.9 MB + `main.dart.js` 4 MB (≈0.85 MB brotli) before the first frame |
| Stripe.js blocking the page | `<script src="https://js.stripe.com/v3/">` in `<head>` — nothing started until Stripe's servers answered, though only checkout needs it |
| Serial startup waits | languages → Firebase → Stripe `applySettings()` (downloads Stripe.js on web) → Google Fonts download, one after another, before `runApp` |
| Fixed splash delay | Splash always held ≥ 1.2 s |
| No loading feedback | `index.html` was plain white until Flutter drew |
| Images never cached | Storage served `Cache-Control: private, max-age=0` → every image re-downloaded on every visit |
| Oversized images | Banners ~300 KB each; one product photo was a 3.1 MB PNG shown in a ~200px card; each Storage request 0.8–1.7 s to first byte |

## 2. Fixes (done ✅)

### Startup
- ✅ **Instant loading screen** — logo + spinner in plain HTML/CSS in [web/index.html](../web/index.html), identical in layout to the app's splash page, removed on Flutter's `flutter-first-frame` event.
- ✅ **Stripe no longer blocks startup** — script tag removed (flutter_stripe_web injects it itself). New [StripeSetup](../lib/core/utils/stripe_setup.dart): mobile initializes at startup as before; web warms Stripe up in the background ~4 s after launch, and `confirmCardPayment` awaits `StripeSetup.ensureReady()` before showing the card form.
- ✅ **Header font bundled** — Oswald Light/SemiBold now ship in `assets/fonts/` (pubspec `fonts:`) instead of `google_fonts` downloading them before the first frame. (Noto Sans JP is still fetched on demand, only when Japanese is selected.)
- ✅ **Parallel startup** — EasyLocalization, date formatting and `Firebase.initializeApp` run concurrently in [bootstrap.dart](../lib/app/bootstrap.dart).
- ✅ **No fixed splash delay on web** — the HTML loader already shows the logo; mobile keeps its 1.2 s brand splash.
- ✅ **Connection hints** — `preconnect` to gstatic / Firestore / Storage, `dns-prefetch` for Auth, `preload` of `main.dart.js`.
- ✅ **WebAssembly build** (`flutter build web --wasm`) — Chrome/Edge/Android Chrome run the faster Wasm (skwasm) build, ~12 % smaller to download than the JS path (2.56 MB vs 2.90 MB brotli); Safari/Firefox automatically fall back to the JS build. Verified locally: home, categories, product page, Japanese, Stripe warm-up, no console errors.
- ✅ **In-app logo** recompressed 212 KB → 44 KB (loaded on every startup by the splash page); 3 unused demo images removed from the bundle.

### Images
- ✅ **Long-lived caching** — every upload now sets `Cache-Control: public, max-age=31536000, immutable` ([StorageUploadSettings](../lib/core/constants/storage_upload_settings.dart)); files are never overwritten (new timestamped name per upload), so this is safe.
- ✅ **Resize + compress on upload** — [ImageOptimizer](../lib/core/utils/image_optimizer.dart) (pure Dart `image` package, works on web and mobile) re-encodes every upload as JPEG, fixes EXIF rotation, flattens transparency onto white. Real test: the 3.1 MB product PNG → 270 KB (1200px) + 81 KB (600px thumbnail).
- ✅ **Thumbnails** — products now store `thumbnails[]` (index-aligned with `images[]`); cards, cart, search and order snapshots use `ProductEntity.thumbnailUrl` (falls back to the full image for older products). Category/subcategory uploads keep only the 600px copy (they're only ever tiles). Banners: 1600px.
- ✅ **Smoother loading** — images fade in ([imageFadeIn](../lib/shared/widgets/image_fade_in.dart)); banners after the first are pre-fetched so auto-play never shows a blank slide.
- ⬜ **One-time optimization of images uploaded before this change** — tool ready, needs to be run once (see §3).

### Deploy
- ✅ `firebase.json` hosting `predeploy` now runs `flutter build web --release --wasm`, so one command builds and deploys. `.wasm`/`.mjs` added to the `no-cache` (always revalidate) header rule so a redeploy reaches returning visitors immediately.

## 2b. Round 2 — measured on the live site, then fixed (done ✅)

Measured with headless Edge on a throttled connection (6 Mbps down, 120 ms latency — roughly Bangladesh → Japan/US), cold and warm visits.

**Found:**
- **Every visit re-downloaded the whole app.** Firebase Hosting answers `If-None-Match` revalidation with a full `200` (verified with curl), so the `no-cache` header on `main.dart.*` meant ~1 MB (Wasm) re-downloaded on *every* visit.
- **The `main.dart.js` preload was pure waste** — Chrome/Edge run the Wasm build, so that 907 KB download only competed with the files actually needed.
- **`/` was cached for an hour** (`max-age=3600`: the header rule matched `/index.html`, but visitors request `/`) — a deploy could take up to an hour to reach a returning visitor.
- **Splash waited ~2 s for Firebase Auth** before navigating to Home.
- **Firebase JS SDK** (~270 KB from gstatic) was only requested after the app had downloaded and started.
- **All 5 banners downloaded at once**, so the one actually on screen finished last.
- A deprecated no-op service worker was registered on every visit.

**Fixed:**
- ✅ Custom [web/flutter_bootstrap.js](../web/flutter_bootstrap.js) appends a per-build version to the app URLs (`main.dart.wasm?v=…`); `firebase.json` marks `main.dart.*` `immutable` for a year. New deploy → new version → new URL, so it's always fresh.
- ✅ Bootstrap script inlined into `index.html` (one less round trip); `main.dart.js` preload removed; service worker registration dropped.
- ✅ `/` and extension-less paths now `no-cache`; `assets/` + `icons/` (non-JSON) get `max-age=1 day, stale-while-revalidate=7 days`; JSON (translations, manifests) stays `no-cache`. Rule overlaps verified with minimatch.
- ✅ `modulepreload` of the 5 Firebase JS SDK modules (version 12.18.0 — **update in `web/index.html` when upgrading Firebase packages**).
- ✅ Web skips the splash's auth wait (the router's redirect still moves admins to `/admin` as soon as their session resolves).
- ✅ Banners 2–5 are only fetched after banner 1 has loaded.

**Result (same throttled connection):**

| | Live before round 2 | After round 2 |
|---|---|---|
| Returning visit — app on screen | 3.3 s | **0.57 s** |
| Returning visit — data downloaded | 2.6 MB | **11 KB** |
| First visit — app on screen | 6.1 s | **4.5 s** |

**Biggest remaining delay:** the live banners/product photos are still the original large files (banners 250–320 KB each, one product photo 625 KB) — the §3 optimization tool hasn't been run for real yet. After it runs, banners drop to ~150 KB, cards load ~40–80 KB thumbnails, and every image is browser-cached for a year.

**Still inherent:** first-visit download of the Flutter engine + app (~2.2 MB brotli, ~3 s at 6 Mbps), and Firestore's web connection setup (a couple of round trips before the first data).

## 3. Your action items

1. **Deploy.** Since round 3 the site needs the two new Cloud Functions (`ssr`, `sitemap`) together with Hosting — deploy them together (Hosting builds the app first; takes a few minutes):
   ```bash
   firebase deploy --only functions:ssr,functions:sitemap,hosting
   ```
   After that, app-only changes still go out with `firebase deploy --only hosting`; redeploy the functions only when `functions/src/seo/` changes.
2. **Optimize existing images once** — run the tool locally, sign in as an admin, **dry run first**, then run for real:
   ```bash
   flutter run -t lib/tools/optimize_images.dart -d edge
   ```
   It's idempotent (already-optimized images are skipped), so it's safe to re-run. Old product/category files are intentionally kept in Storage because past orders reference them; old banner files are deleted.
3. **Google Search Console** (after the deploy): add the property `https://everydaywholesale.jp`, verify it (a DNS TXT record at Xserver, like the Hosting one), submit `https://everydaywholesale.jp/sitemap.xml`, and use *URL Inspection* on a product page to request indexing. Test a product URL in Google's [Rich Results Test](https://search.google.com/test/rich-results) — it should detect *Product* and *Breadcrumb*.

## 4. Decided against (for now)

- **Splitting admin code out of the customer download (deferred loading)** — DI config (`injection_container.config.dart`) imports every admin bloc eagerly, so it would need a DI restructure; the framework/Firebase/Stripe dominate the bundle, so the gain would be small.
- **Firestore offline cache for instant repeat visits** — `get()` still waits for the server unless reads are changed to cache-first, which risks showing stale catalog data (and the admin screens share the same reads). Low gain vs. correctness risk.
- **CDN in front of Storage (e.g. Cloudflare)** — with caching + small files + thumbnails, repeat visits no longer hit Storage at all; revisit only if first-visit image speed is still a complaint.

## 5. What can't be removed

The Flutter engine download (~1.4–1.9 MB) is inherent to Flutter web; browsers cache it after the first visit, so it mostly affects first-time visitors.

---

## 6. Round 3 roadmap — how the Flutter community gets closer to "native web" (researched + cross-checked)

How this section was built: official Flutter/Google guidance and community write-ups were researched (sources in §6.4), then **every task below was checked against this project** — by measuring the live site with headless Edge on a throttled 6 Mbps / 120 ms connection, by building variants locally, or by reading the plugin source in the pub cache. Items that failed the cross-check are listed separately in §6.3 with the reason.

**The honest ceiling:** a Flutter web app will never be as light as a hand-written HTML page on a *first* visit — the engine (~1.4 MB) + app (~1.2 MB) must download before Flutter can draw anything. The community's answer is therefore not "make Flutter tiny" but **(a)** make every repeat visit near-instant (done in round 2: 0.57 s), **(b)** stop downloading things that aren't needed, and **(c)** put real HTML content in front of Flutter for the first paint and for search engines. Tasks are ordered by impact ÷ effort.

### 6.1 Tasks (ordered)

#### ⬜ R3-1 — Run the image optimization tool for real *(user action — biggest remaining image win)*
- **Evidence:** live network log (2026-09-28) still shows the original files: banners 250–320 KB each, a product photo 625 KB, and Storage still sends `Cache-Control: private, max-age=0`.
- **Cross-check:** tool output on the real 3.1 MB PNG → 270 KB + 81 KB thumbnail; banner → ~150 KB at 1600 px.
- **Expected:** home-page image bytes roughly −60–80 %, and zero image downloads on repeat visits.
- **Verify:** re-run `measure.js` (or DevTools Network): Storage responses show `cache-control: public, max-age=31536000, immutable`; card images ≤ 100 KB.

#### ✅ R3-2 — Stop downloading the full Noto Sans JP font in Japanese mode *(high impact for the store's main audience)*
> **Done — Option B.** Reading the engine source (`flutter_web_sdk/lib/_engine/engine/font_fallbacks.dart`) settled it: the fallback picks Noto Sans JP only when `navigator.language` is *exactly* `ja` — iPhone Safari and Android Chrome report `ja-JP`, so most Japanese phones would have got Chinese-style kanji with Option A.
> Built: `assets/fonts/jp/NotoSansJP-{Regular,Bold}.ttf` — subsets with 8,149 characters (kana, **all JIS X 0208 = level 1 + 2 kanji**, Latin, symbols; level 2 kept because food words like 醤油 and 蕎麦 need it), regenerable via `tool/fonts/subset_noto_sans_jp.js`. Loaded on demand by `JapaneseFont` (`FontLoader`, Regular then Bold) only when Japanese is active — plain assets, *not* pubspec `fonts:`, so English visitors never download them. `google_fonts` removed entirely. `firebase.json` caches `/assets/assets/fonts/**` as immutable (rename files if they ever change).
> **Measured:** Japanese mode now downloads **1.26 MB + 1.28 MB (brotli) once**, cached for a year — was **3.0 MB per weight**, up to 4 weights. English mode downloads **no** Japanese font. Verified rendering (Regular + Bold) in headless Edge with browser language `en-US` and `ja-JP`. On phones the fonts are bundled, so Japanese works offline (was a 5.3 MB-per-weight runtime download).
- **Evidence (measured):** in Japanese mode the app downloads a **3.0 MB** font file (`fonts.gstatic.com/s/a/0eba77…ttf`) — one weight of Noto Sans JP via `google_fonts`. The package source lists each weight at **5.3 MB** uncompressed, and the app uses 4 weights (400/500/600/700), so bold headings/prices can each pull another multi-MB file. Plus ~15 Noto Sans SC fallback chunks (~25 KB each) while it loads.
- **Why it happens:** `google_fonts` ships whole font files; it cannot use Google Fonts' `unicode-range` slicing that normal websites get.
- **Fix — pick after the test below:**
  - **Option A (smallest, test first):** on web, drop the `GoogleFonts.notoSansJp()` body font and let the engine's automatic CJK fallback load only the ~20–40 KB slices it needs. **Caveat found in research:** the engine prefers *Noto Sans JP* slices only when the **browser language is `ja`**; otherwise it uses Noto Sans SC, whose kanji shapes differ slightly from Japanese forms (flutter/flutter#16870). Fine for Japanese customers, slightly off for e.g. a Bangladeshi visitor who switches to 日本語.
  - **Option B (guaranteed, recommended if A looks wrong):** bundle a **subset** Noto Sans JP (kana + JIS level-1/2 kanji + ASCII) in 2 weights (Regular + Bold) as app assets, served from Hosting with long caching; map w500/w600 → Bold, w400 → Regular. Subsetting can be done with the `subset-font` npm package (HarfBuzz-based, works on this machine without Python).
- **Expected:** Japanese-mode font cost 3–12 MB → **Option A:** ~0.1–0.4 MB; **Option B:** ~1–1.5 MB total, cached for returning visitors.
- **Verify:** `ja_fonts.js` style measurement (total font bytes in Japanese mode) + visual check of kanji that differ between JP and SC forms (e.g. 直 骨 海 画 角) with the browser language set to English and to Japanese.

#### ✅ R3-3 — Switch from `#/` URLs to real paths (`usePathUrlStrategy`) *(prerequisite for all SEO work)*
> **Done.** `usePathUrlStrategy()` in `bootstrap.dart`, plus **`GoRouter.optionURLReflectsImperativeAPIs = true`** — found by testing: the app navigates with `context.push`, which go_router otherwise never writes to the address bar (it stayed `/home` on every product page, so nothing could be shared/bookmarked). A small script in `web/index.html` converts old `/#/…` links to their path form before Flutter starts.
> **Verified (headless Edge, production build):** `/` → `/home`; reloading `/home/category/rice_grains` and `…/product/<id>` opens those pages; an old `/#/home/category/…/product/<id>` link opens the product; clicking category → product updates the URL to `/home/category/most_popular/product/<id>`; browser Back returns to the category URL.
- **Evidence:** the app uses Flutter's default hash strategy (`everydaywholesale.jp/#/home/category/…`). Google: *"don't use fragments to load different page content"* — every `#/…` page is the same URL to Google, so no product or category can ever rank on its own.
- **Cross-check:** `firebase.json` already rewrites `**` → `/index.html`, which is exactly what path URLs need on Hosting; go_router supports it with a one-line `usePathUrlStrategy()` in `main.dart`. Old `#/…` links still open (they land on `/`).
- **Expected:** every category/product gets its own crawlable URL; no speed change by itself.
- **Verify:** reload `https://everydaywholesale.jp/home/category/<id>` directly (deep link works, no 404); browser back/forward; Stripe return URL; Google sign-in popup.

#### ✅ R3-4 — Server-rendered HTML for home, category and product pages (Cloud Function + Hosting CDN) *(biggest remaining first-visit AND SEO win)*
> **Done.** `functions/src/seo/` — `render.ts` (pure: routes, HTML, JSON-LD, sitemap), `catalog.ts` (Firestore reads), `handlers.ts` (`ssr` + `sitemap`, `asia-northeast1`). Hosting rewrites `/`, `/home`, `/home/**` → `ssr`, `/sitemap.xml` → `sitemap`, everything else → `/app.html`. `web/robots.txt` added.
> **Key finding:** Hosting serves an exact static file *before* rewrites, so while `index.html` existed `/` could never reach the function — the predeploy step `tool/web/finalize_build.js` renames it to `app.html` (the function fetches `/app.html` as its template, re-checked every 10 s, so Hosting deploys are picked up automatically; Hosting also purges its CDN on every deploy).
> Pages: `<title>` / description / canonical / Open Graph; JSON-LD `GroceryStore` (home), `BreadcrumbList` + `ItemList` (categories), `Product` with JPY price, stock and rating (products); visible HTML with real `<a href>` links; unknown product/category → 404 + `noindex`; CDN cache `s-maxage=300`; any data error falls back to the plain app shell (never takes the site down). Host allow-list on `x-forwarded-host` so the function can't be used to proxy other sites.
> **Measured and adjusted:** a first version put product/banner `<img>` tags in the HTML — on the 6 Mbps profile that made the Flutter first frame *worse* (4.5 s → 7.6 s, 11.3 MB) because the photos competed with the engine download. Grids now use placeholders (photos stay in JSON-LD/`og:image` for Google); product pages keep one thumbnail.
> **Result (6 Mbps / 120 ms, CDN-cached HTML):** real content (heading, all category links, popular products) visible at **0.46 s** (was a logo until 4.5 s); Flutter first frame 4.8 s (unchanged within noise); repeat visit 0.68 s. Verified: 200/404 status per route, private pages get the plain shell, sitemap lists 46 URLs, product page → Flutter takes over on the same URL with no console errors. Escaping tested against `</script>` and attribute injection. Tests: `cd functions && npm test` (6 tests).
> **Update (client decision):** visitors now see the logo loading screen until the app appears, instead of the plain HTML preview — the preview looked unfinished at first glance. The server-rendered content is still in the page underneath the loading screen (what search engines read), and the embedded home data (R3-5) still makes the app appear already filled in.
> **Not verifiable locally:** the Admin SDK loader in `catalog.ts` (the local harness read the same data via Firestore's public REST API with the same compiled renderer) — check `curl https://everydaywholesale.jp/home/category/rice_grains` after deploy.
- **What:** a Cloud Function (the project already has a `functions/` codebase) behind Hosting rewrites for `/`, `/home/category/**` and `…/product/**` returns a real HTML page: `<title>`, meta description, Open Graph image, **Product JSON-LD** (name, price in JPY, availability, image), visible product/category text and images — **and the same Flutter bootstrap**, so Flutter loads on top and takes over (the "HTML landing page while flutter.js preloads" pattern from the Flutter team's loading-speed article). The HTML loader from round 1 becomes real page content instead of a logo.
- **Cross-check:**
  - Google recommends server-side/static rendering over "dynamic rendering" (serving bots different HTML), which it calls a workaround. Serving the *same* HTML to users and bots avoids any cloaking risk.
  - Firebase Hosting supports rewrites to 2nd-gen functions (`"function": { "functionId": …, "region": … }`), and responses with `Cache-Control: public, s-maxage=…` are cached on the Hosting CDN, so Firestore is only queried when the cache expires (cheap, fast). Hosting enforces a 60 s timeout (a Firestore read + HTML template takes well under 1 s).
  - Put the function in `asia-northeast1` (same region as the data) or one of the Hosting-colocated regions listed in the Firebase docs.
- **Expected:** first visit shows **real products/banners as HTML in ~0.5–1 s** instead of a logo for ~4.5 s (measured current); product pages become indexable with rich results (price/stock).
- **Verify:** `curl https://everydaywholesale.jp/home/category/<id>/product/<id>` returns product text + JSON-LD; Google Rich Results Test passes; `measure.js` shows meaningful content (LCP) < 1.5 s on the throttled profile; Flutter still takes over and works.
- **Also in this task:** a `sitemap.xml` function (lists all categories/products from Firestore) + `robots.txt`, then submit the sitemap in Google Search Console.

#### ✅ R3-5 — Embed the home data into the server-rendered page *(after R3-4)*
> **Done.** The home page embeds `{categories, banners, popular}` (~7.7 KB) as `<script type="application/json" id="initial-data">` — raw Firestore documents plus `id`, so the app's existing models parse them. Read via `lib/core/web/embedded_json.dart` (conditional import; `null` on mobile) → `HomeInitialDatasource` → `GetInitialHomeDataUseCase`. `HomeBloc` paints it immediately, then refreshes from Firestore (and keeps it if Firestore fails); the sidebar's category cache uses it too.
> **Verified:** filmstrip shows the full home layout (categories, sidebar) on Flutter's first frame with **no spinner**. Contract test `test/features/home/initial_home_data_test.dart` parses real renderer output (`test/fixtures/initial_home_data.json`), including legacy plain-string names and malformed input.
- **Evidence (measured):** Firestore's web connection needs a handshake round trip before any data (trace: queries sent 0.23 s after first frame, data only after the channel is set up); the home page shows a spinner meanwhile.
- **What:** the R3-4 function already reads categories/banners/popular products — write them into the HTML as a JSON `<script>`; `HomeBloc` uses it for the first paint, then refreshes from Firestore in the background.
- **Expected:** home content appears with Flutter's first frame (no spinner); ~0.5–1.5 s saved on slow links.
- **Verify:** no spinner frame in the filmstrip; data still refreshes when an admin changes a banner.

#### ⏸️ R3-6 — WebP instead of JPEG for uploaded images *(medium, optional)* — deferred
> **Decision: deferred until after R3-1.** Once thumbnails exist, a card image is ~40–80 KB as JPEG; WebP would save roughly 10–25 KB of that. Getting there means running the Resize Images extension *alongside* the app's own resize pipeline and storing a second set of URLs on every product — real complexity and an extra paid function for a small gain. Revisit if image bytes are still the bottleneck after R3-1 (measure first).
- **Evidence:** the Flutter team's own loading-speed article measured PNG 319 KB → WebP 38 KB → AVIF 10 KB for the same image; WebP is typically ~25–35 % smaller than JPEG at equal quality.
- **Cross-check:** the pure-Dart `image` package used by `ImageOptimizer` can decode WebP but **cannot encode it**, so this needs the official **Resize Images** Firebase extension (outputs WebP/AVIF, can keep or delete originals, can set Cache-Control; requires the Blaze plan, which this project already has because of Cloud Functions). The skwasm/CanvasKit renderers decode through the browser, which supports WebP everywhere the app runs.
- **Expected:** a further ~25–35 % off image bytes on top of R3-1.
- **Verify:** thumbnails served as `image/webp`, visual quality check, sizes in the network log.

### 6.2 Already done in rounds 1–2 (matches community best practice)
HTML/CSS splash in `index.html` · Wasm (skwasm) build with automatic JS fallback · versioned, year-long cached app files · non-blocking startup (`unawaited` third-party init, no Stripe.js in `<head>`) · bundled Latin font · preconnect/modulepreload hints · resized, cached, thumbnailed images · no fixed splash delay on web.

### 6.3 Researched but rejected after cross-checking
| Idea | Why not (evidence) |
|---|---|
| **Multi-threaded Wasm via COOP/COEP headers** | Officially needed for multi-threaded rendering, but `Cross-Origin-Opener-Policy: same-origin` breaks Firebase `signInWithPopup` — the Google popup can't message back and the promise never resolves (flutterfire#11466, firebase-js-sdk#8541). It would also put the Stripe card iframe at risk. Mainly improves animation smoothness, not load time. |
| **`-O4` optimization level** | Built and measured here: Wasm 1197 KB → 1169 KB brotli (−2 %); JS unchanged (already `-O4`). It drops some runtime type checks — not worth the risk for 28 KB. |
| **"Use the HTML renderer for SEO"** (common in older articles) | The HTML renderer was **removed in Flutter 3.29**; this project is on 3.44.4. Only CanvasKit/skwasm exist. |
| **Deferred loading of the admin panel now** | Wasm deferred loading is still behind an experimental flag (`--enable-wasm-deferred-loading`), and the DI config imports every admin bloc eagerly. Revisit when it's stable. |
| **Build-time prerender tools (e.g. flutter_prerender)** | They snapshot pages at build time — product prices/stock from Firestore would go stale until the next build. R3-4 renders from live data instead. |
| **Dynamic rendering (bots-only HTML)** | Google explicitly calls it a workaround, not a long-term solution; R3-4 serves the same HTML to everyone. |
| **Jaspr rewrite of the storefront** | Jaspr (Dart SSR framework, used for the Flutter/Dart docs sites) is the "most native" option, but it means rebuilding the customer UI outside Flutter — only worth it if the storefront should become a content/SEO-first site. |

### 6.4 Sources
- Flutter team — [Best practices for optimizing Flutter web loading speed](https://flutter.dev/blog/best-practices-for-optimizing-flutter-web-loading-speed)
- Flutter docs — [Web FAQ (SEO guidance)](https://docs.flutter.dev/platform-integration/web/faq), [WebAssembly support](https://docs.flutter.dev/platform-integration/web/wasm), [URL strategies](https://docs.flutter.dev/ui/navigation/url-strategies), [3.29 release notes (HTML renderer removed)](https://docs.flutter.dev/release/release-notes/release-notes-3.29.0)
- Google Search Central — [JavaScript SEO basics](https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics), [Dynamic rendering as a workaround](https://developers.google.com/search/docs/crawling-indexing/javascript/dynamic-rendering)
- Firebase — [Hosting rewrites to Cloud Functions](https://firebase.google.com/docs/hosting/functions), [Resize Images extension](https://extensions.dev/extensions/firebase/storage-resize-images)
- Issues — [flutterfire#11466 (popup sign-in fails when cross-origin isolated)](https://github.com/firebase/flutterfire/issues/11466), [firebase-js-sdk#8541](https://github.com/firebase/firebase-js-sdk/issues/8541), [flutter#16870 (CJK glyph variants)](https://github.com/flutter/flutter/issues/16870)
- Community — [Real JS vs Wasm numbers from 3 migrated apps](https://flutterstudio.dev/blog/flutter-wasm-web-performance.html), [Flutter web SEO: crawlable content, JSON-LD, share cards](https://dev.to/devshakib/flutter-web-seo-crawlable-content-json-ld-and-share-cards-for-a-canvas-app-4a83), [Jaspr](https://jaspr.site/)
