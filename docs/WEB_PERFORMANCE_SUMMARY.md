# Web performance — summary and rules for new features

Short reference. The full history, measurements and reasoning are in [WEB_PERFORMANCE.md](WEB_PERFORMANCE.md) (§ numbers below point there).

## 1. Where we got to (live site, from Bangladesh, 2026-10-15)

| | Before | After |
|---|---|---|
| First visit, page visible | ~10 s | ~2.6–3 s |
| First visit, with photos | — | ~5 s (before the image preloads, §16b) |
| Repeat visit | 5–7 s | ~1.5 s |

The practical floor for Flutter web is roughly 2.5 s on a first visit (about 2.2 MB must download and compile before anything draws). Further gains are small; the repeat-visit and photo times are where there was room.

## 2. What was done (and why it worked)

**Download size and caching** (§1–2)
- Wasm (`--wasm`) build, with automatic JS fallback for Safari/Firefox.
- Versioned app files (`main.dart.wasm?v=…`) cached for a year; `index.html` / `app.html` never cached.
- Fonts bundled (Plus Jakarta Sans, Oswald; Japanese subset loaded only in Japanese mode); no Google Fonts requests.
- Stripe.js is not in `<head>` and (since §16) not loaded at startup on web — checkout starts it.

**Startup chain** (§2b, §13, §16)
- HTML/CSS loading screen in `web/index.html`, removed on Flutter's first frame.
- Firebase JS SDK `modulepreload` hints, rewritten to the installed version on every deploy (`tool/web/finalize_build.js`).
- `.wasm` preloaded in parallel with `main.dart.mjs` (`web/flutter_bootstrap.js`).
- **`<link rel="preload">` for `FontManifest.json`, `AssetManifest.bin.json`, `en.json` and the 6 fonts** (§16) — they used to download one after another.
- Those three JSON files are `max-age=300` instead of `no-cache` so the CDN can serve them (a `no-cache` file is a CDN `MISS` every time, 0.3–1.2 s from Bangladesh).

**Data** (§3, §13, §16)
- Server-rendered pages (`ssr` Cloud Function) with the home data embedded as `#initial-data`, so the app paints with no Firestore wait; CDN-cached 30 min with `stale-while-revalidate`.
- Home product rows read **one shared catalogue query** instead of one Firestore query per category (§16): each web query costs a ~0.2–0.3 s round trip, ~40 requests became ~6.
- Rows start from the embedded categories instead of waiting for the refresh.
- Catalogue cached 2 min in the datasource (also used by search).

**Images** (§1–2, §16b, §16c)
- Uploads resized + compressed, thumbnails (600 px) for cards, long-lived `immutable` cache headers.
- Photos decoded at display size (`AppNetworkImage`).
- The server adds `preload` tags (first thing in `<head>`) for the first 2 banners, first 6 category pictures (phones only, via `media`), first 6 Most Everyday thumbnails (cards 4–6 wide screens only). Switch: `PRELOAD_FIRST_SCREEN_IMAGES` in `functions/src/seo/render.ts`.
- Product cards prefetch the full-size photo on hover / touch-down; the product page shows the card thumbnail until the full photo arrives.

## 3. Rules to keep in mind when adding features

1. **Nothing third-party at startup.** Any SDK, script, font or analytics tag must load lazily (when its page opens), never in `bootstrap.dart` or `index.html` `<head>`. Stripe is the model: `StripeSetup.ensureReady()` when checkout opens.
2. **Don't add serial work before `runApp`.** Anything awaited in `bootstrap()` delays the first frame; run independent things in `Future.wait`, or start them with `unawaited` and await at the point of use.
3. **Every Firestore query on the first screen costs ~0.25 s on web.** Don't add one query per row/category/widget. Batch (one query, group in memory), reuse the embedded data, or load lazily when scrolled into view. Count `Listen/channel` requests in DevTools before and after.
4. **New data on the home page → embed it in `#initial-data`** (`render.ts` + `lib/core/web/…`) rather than fetching after the app starts, if it is needed for the first screen.
5. **New small startup files = new serial round trips.** Any file the app fetches before the first frame (translations, config, manifests) should be preloaded in `index.html` and be CDN-cacheable (not `no-cache`). New fonts: add to `pubspec.yaml` **and** the preload list in `web/index.html`; keep them subsetted.
6. **Images:** always upload through the admin flow (resizes + thumbnails + cache headers). Use `AppNetworkImage` / `ProductImage`, never raw `Image.network` at full size. Cards use thumbnails; full-size only on the detail page. New first-screen images → add to the preload list (and think about phone vs desktop with `media`).
7. **Keep the preload list small** (~10–15 images, < ~1 MB): preloads share bandwidth with the app download. More is not better.
8. **New heavy packages** (maps, charts, PDF, rich text, video): check the `main.dart.wasm` size before and after (`build/web/main.dart.wasm`, currently ~1.1 MB brotli). Deferred loading isn't available for Wasm yet (§4, §6.3), so a big package is paid for by every visitor — prefer a lighter option or a separate page.
9. **No cookies/headers that break caching.** Don't set `Cache-Control: no-cache` on static assets; don't add rules to `firebase.json` that override the immutable/long-cache ones (later rules win).
10. **Don't enable COOP/COEP** (multi-threaded Wasm) — it breaks Google sign-in popups and Stripe (§6.3).
11. **Firebase JS SDK version in `web/index.html`** is rewritten automatically by `finalize_build.js` on deploy. Don't hand-edit it, and don't skip the predeploy step.
12. **Measure after every feature that touches startup or the home page** (checklist below). Regressions here were found by measuring, not by looking (e.g. a package upgrade silently invalidated the Firebase preload, +1–3 s).

## 4. Check after each deploy (5 minutes)

```powershell
# headers (CDN caching of the startup JSON; expect max-age=300, then x-cache: HIT on repeat)
curl.exe -sI https://everydaywholesale.jp/assets/assets/translations/en.json
# image preload tags on the home page (file preloads from index.html + images)
curl.exe -s https://everydaywholesale.jp/ | Select-String -Pattern 'rel="preload" as="fetch"' -AllMatches | ForEach-Object { $_.Matches.Count }
```

In Chrome DevTools → Network (Disable cache, Slow 4G, Ctrl+Shift+R):
- no `js.stripe.com` request on the home page;
- a handful of `Listen/channel` requests, not dozens;
- `main.dart.wasm` and `main.dart.mjs` start together; the small startup files start at ~0 s, not after the Wasm;
- the loading screen disappears in about 3 s on Slow 4G, photos right after.

Deploy commands (PowerShell): app only `firebase deploy --only hosting`; with the server pages `$env:FUNCTIONS_DISCOVERY_TIMEOUT=60; firebase deploy --only functions:ssr,hosting` (a hosting deploy also clears the CDN's cached home page; a function-only deploy does not, for up to 30 min).

## 5. Ideas not done (for later)

- **Hero animation** from the product card photo into the product page (decided to skip for now). Needs a short page transition on web (§7 removed it), a unique Hero tag per card (the same product can appear in two home rows), first photo only.
- **Embed the first rows' products in `#initial-data`** — would remove the product query on the home page completely (the 2 s-ish data tail).
- **Cloudflare Pages (free) in front of the static files** — A/B test from Bangladesh; Firebase Hosting's edge cache is often cold for low-traffic files (`X-Cache: MISS`).
- **CDN in front of Firebase Storage** — Storage's first byte is ~0.75 s from Bangladesh.
- **Profile on a mid-range Android phone** — CPU time (Wasm compile, app start) was never measured; the desktop numbers above are optimistic for phones.
- **WebP/AVIF thumbnails** (§6, R3-6) — ~25–35 % smaller photos; needs the Resize Images extension.
- **Load category rows lazily as they scroll into view** if the catalogue grows to many categories (§11); today the one shared catalogue read is fine at tens of products.

## 6. Measuring notes

- The in-app Browser pane here doesn't render frames until a screenshot is taken, so photo timings from automated runs in it are unreliable; use real DevTools on a real browser/phone.
- Resource Timing buffer fills at ~250 entries; many `Listen/channel` requests can hide later image requests in scripted measurements.
