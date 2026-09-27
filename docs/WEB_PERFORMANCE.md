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

## 3. Your action items

1. **Deploy** (builds automatically first — takes a few minutes):
   ```bash
   firebase deploy --only hosting
   ```
2. **Optimize existing images once** — run the tool locally, sign in as an admin, **dry run first**, then run for real:
   ```bash
   flutter run -t lib/tools/optimize_images.dart -d chrome
   ```
   It's idempotent (already-optimized images are skipped), so it's safe to re-run. Old product/category files are intentionally kept in Storage because past orders reference them; old banner files are deleted.

## 4. Decided against (for now)

- **Splitting admin code out of the customer download (deferred loading)** — DI config (`injection_container.config.dart`) imports every admin bloc eagerly, so it would need a DI restructure; the framework/Firebase/Stripe dominate the bundle, so the gain would be small.
- **Firestore offline cache for instant repeat visits** — `get()` still waits for the server unless reads are changed to cache-first, which risks showing stale catalog data (and the admin screens share the same reads). Low gain vs. correctness risk.
- **CDN in front of Storage (e.g. Cloudflare)** — with caching + small files + thumbnails, repeat visits no longer hit Storage at all; revisit only if first-visit image speed is still a complaint.

## 5. What can't be removed

The Flutter engine download (~1.4–1.9 MB) is inherent to Flutter web; browsers cache it after the first visit, so it mostly affects first-time visitors.
