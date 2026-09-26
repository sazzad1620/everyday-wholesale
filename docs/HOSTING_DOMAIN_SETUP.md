# Firebase Hosting & Custom Domain Setup — Plan & Status

Companion doc for [PLAN.md](PLAN.md). The web build has never been deployed anywhere — `firebase.json` has no `hosting` block today, and there's no Netlify/Vercel config either. The client has now bought the real domain, so this doc covers getting the Flutter web build onto Firebase Hosting for the first time and pointing that domain at it. Update **§6 (Roadmap & Status)** as work lands, same convention as [PAYMENTS_PLAN.md](PAYMENTS_PLAN.md).

## 1. Scope

- Stand up Firebase Hosting for the `everyday-wholesale` Firebase project (same project already used for Auth/Firestore/Storage/Functions — one project, one bill, no new account needed).
- Deploy the release web build there, first at Firebase's own free subdomain for review, then behind the client's real domain.
- Wire the domain's DNS to Firebase Hosting and get it serving over HTTPS.
- Cover the easy-to-miss follow-on step: registering the new domain with Firebase Auth, so sign-in doesn't break the moment the domain goes live.
- Out of scope: CI/CD automation (deploys stay manual via the Firebase CLI, matching how Functions are deployed today — see [PAYMENTS_PLAN.md](PAYMENTS_PLAN.md) §6 Phase A), and any change to the Stripe/Functions setup (a different subdomain, unaffected by this).

## 2. Key decisions

| Decision | Choice | Why |
|---|---|---|
| Primary domain form | **Apex** (`example.com`) is primary; `www.example.com` redirects to it | What people type and share by default. Firebase Hosting's "Add custom domain" flow supports adding both and auto-configures the redirect in one pass — no separate reverse-proxy needed. |
| Rollout sequencing | **Deploy first to Firebase's default `*.web.app` URL, review there, attach the real domain after** | Keeps the DNS change — the one step with real propagation/SSL delay (up to ~24h) — as a deliberate last step, not something rushed through before the build has even been looked at live. |
| Deploy method | Manual `firebase deploy --only hosting` from a developer machine | Matches the project's current pattern (Functions are deployed manually too, no CI exists yet). Revisit later if deploys become frequent enough to be worth automating. |
| Hosting site count | **One** Hosting site, no separate "staging" site | The default `*.web.app` URL Firebase gives every project for free already serves as the staging URL for Phase B below — a second site would just be a second thing to keep in sync for no real benefit at this scale. |
| SPA rewrite | Added anyway, even though not strictly required today | The app currently uses Flutter's default **hash-based** URL strategy (no `usePathUrlStrategy()` call in the codebase — confirmed by grep), so the browser only ever requests `/`; everything after `#` is client-side and Hosting never sees it. The rewrite is a no-op today but is one line and prevents a 404 if the app ever switches to path-based URLs later. |

## 3. How it fits together

```
Browser
   │  https://everydaywholesale.example  (or the *.web.app URL, during Phase B)
   ▼
Firebase Hosting (global CDN, managed by Google)
   │  serves the static files in build/web/ — same compiled Flutter web
   │  output already produced by `flutter build web --release` today
   ▼
index.html + main.dart.js + assets  →  app boots, then talks to
Firebase Auth / Firestore / Storage / Cloud Functions exactly as it
does now — Hosting only changes *where the static files are served from*,
nothing about the backend.
```

Custom domain flow, once you get to Phase C: Firebase Console → Hosting → **Add custom domain** → you type the domain → Firebase gives you one **TXT record** to prove you own it → once verified, Firebase gives you **A/AAAA records** (for the apex) and a **CNAME** (for `www`) → you add those at the registrar → Firebase auto-provisions a **managed SSL certificate** (Google-run, auto-renewing, no manual cert work ever) once DNS resolves correctly.

## 4. Pre-flight checklist

Do these before touching any DNS record, in order:

- [ ] Confirm CLI access: `firebase projects:list` shows `everyday-wholesale` and you can deploy to it (same account already used for Functions deploys).
- [ ] Confirm `flutter build web --release` completes clean locally and produces a working `build/web/` (this doc assumes that output, doesn't change how it's built).
- [ ] **Check what's already on the domain's DNS before adding anything** — if the client already receives email at this domain (Google Workspace, Microsoft 365, or anything else), it'll have existing `MX` records. Only ever *add* the records Firebase's wizard specifies; never delete or replace an existing record you don't recognize without asking the client what it's for first. This is the single most common way a hosting migration accidentally breaks a client's email.
- [ ] Confirm who has access to the domain's DNS panel — the client (registrar account holder) or a developer with delegated access. Either can add the records; just needs to be settled before Phase C so it isn't a blocker mid-setup.

## 5. Environment & access (your action items, not code)

- [ ] Domain name + registrar confirmed (e.g. GoDaddy, Namecheap, Cloudflare, Google Domains/Squarespace, etc.) — the exact click-path for adding a DNS record differs slightly by registrar; this doc stays generic and points to "your registrar's DNS management page" rather than hardcoding one.
- [ ] Decide who applies the DNS records in Phase C: client applies them themselves (developer supplies the exact values), or client grants the developer temporary DNS access.
- [ ] (Carried over from [PAYMENTS_PLAN.md](PAYMENTS_PLAN.md) §5, not done yet) — the Stripe **publishable** key still needs to go into the Flutter app's build-time config before Phase 6 can be considered finished. Unrelated to hosting mechanically, but worth doing in the same pass since both are "getting ready for the real domain" work.

## 6. Roadmap & Status

### Phase A — Firebase Hosting setup ✅ done

- [x] Added the `hosting` block to [firebase.json](../firebase.json) — plus a `headers` block not in the original plan (see the Phase B note on stale JS below):
  ```json
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }],
    "headers": [
      { "source": "**/*.@(js|json)", "headers": [{ "key": "Cache-Control", "value": "no-cache" }] },
      { "source": "/index.html", "headers": [{ "key": "Cache-Control", "value": "no-cache" }] }
    ]
  }
  ```
- [x] `flutter build web --release`
- [x] `firebase deploy --only hosting` — live at **https://everyday-wholesale.web.app**
- [x] Sanity check passed: site loads, boots, Auth/Firestore/Storage/Functions all reachable from the new URL

### Phase B — Review pass on the default URL ✅ done

Manual QA run on `everyday-wholesale.web.app`, signed in as a real (test) customer and — once the developer temporarily granted `role: admin` on the test account — as admin too:

- [x] Customer flow: sign-up → address → cart → checkout → **real Stripe test-card payment (4242...) → webhook flipped `paymentStatus: paid` → live-updating confirmation page** → Order History/Detail, all correct
- [x] Admin flow: dashboard stats, Products/Categories/Orders/Reviews lists, order status change (tested on the QA order only — flipped it to `Cancelled`, dashboard's pending count updated live from 14→13)
- [x] Both languages (EN/JA) — storefront and admin panel both switch correctly; categories/products with no Japanese name entered yet correctly fall back to English (expected — matches the still-open data-entry item in [JAPANESE_BILINGUAL_SUPPORT.md](JAPANESE_BILINGUAL_SUPPORT.md) §9 Phase 9, not a bug)
- [x] Mobile-width (375px) check — bottom nav, 2-column grid, no regressions

**Bugs found during this pass, fixed and redeployed:**
- **Storage CORS** — product/category images didn't render on web at all (Firebase Storage sends no CORS headers by default; browsers block cross-origin image reads without one). Fixed by applying a bucket-level CORS policy (`gsutil cors set`, run from Cloud Shell — see chat history for the exact command). Not a code change; a one-time cloud-infra step now done for the `everyday-wholesale.firebasestorage.app` bucket.
- **Checkout Order Summary showed raw `LocalizedText(en: ..., ja: ...)` text** instead of the resolved product name — [order_summary_card.dart](../lib/features/checkout/presentation/widgets/order_summary_card.dart) was missed when the Japanese bilingual work changed `product.name`'s type. Fixed to use `context.localized(...)`, matching every other call site in the codebase.
- **Stale JS after redeploy** — Firebase Hosting's default `Cache-Control: max-age=3600` on `main.dart.js`/`index.html` meant a browser that had visited before a fix shipped could keep running the old code for up to an hour. Added the `no-cache` (always-revalidate) headers above so every redeploy reaches visitors immediately, not just new ones.

**Found, not fixed — flagged for you:** one real product ("Keri Samba Rice") has what look like unrelated app screenshots (a checkout confirmation page, a payment-method sheet) mixed into its 5 product photos alongside what appears to be the real rice-bag photo. Left untouched since it's live catalog content, not something to silently edit — worth a look in Admin → Products → Keri Samba Rice.

### Phase C — Connect the custom domain ⬜

- [ ] Firebase Console → Hosting → **Add custom domain** → enter the apex domain (e.g. `everydaywholesale.com`)
- [ ] Add the **TXT** verification record Firebase gives you at the registrar; wait for Firebase to confirm ownership
- [ ] Add the **A/AAAA** records Firebase gives you for the apex
- [ ] Repeat "Add custom domain" for the `www` subdomain, or accept Firebase's offer to auto-redirect it if prompted during the apex setup — add the **CNAME** record it gives you for `www`
- [ ] Confirm in the registrar's DNS panel that no pre-existing record (especially `MX`) was overwritten — cross-check against the pre-flight snapshot from §4
- [ ] Wait for DNS propagation (minutes to a few hours depending on the registrar's TTL) and SSL provisioning (Firebase-managed, typically under 24h) — check status in the Hosting console, or independently via a DNS checker
- [ ] **Record the exact records Firebase issued in this doc** (append a small table below once you have them) so there's a single source of truth if DNS ever needs to be re-verified or moved to a new registrar later

### Phase D — Post-connect verification & cutover ⬜

- [ ] `https://<domain>` loads the app, padlock/SSL valid, `www` correctly redirects to the apex (or vice versa, per §2)
- [ ] **Firebase Console → Authentication → Settings → Authorized domains → add the new domain.** Easy to forget, and sign-in (Google popup especially) will fail with an unauthorized-domain error on the new domain until this is added — the `*.web.app` default domain is authorized automatically, but a custom domain is not.
- [ ] Re-run the Phase B QA checklist once more, this time against the real domain specifically (Google Sign-In popup is the item most likely to behave differently here — worth testing explicitly)
- [ ] Confirm nothing in the app hardcodes the old `*.web.app` URL (share links, meta tags, etc.) — a quick grep, not expected to find anything since the app has never referenced its own hosting URL

### Phase E — Ongoing / later ⬜

- [ ] Once deploys become frequent, consider a GitHub Actions workflow for `firebase deploy --only hosting` on merge to `main` — not needed yet, called out here so it isn't forgotten as a "someday" item
- [x] ~~Cache-control tuning for `main.dart.js`/`index.html`~~ — done early, in Phase A, after hitting the stale-JS problem firsthand during Phase B testing

## 7. DNS records reference (fill in once Phase C is run)

| Type | Host | Value | Purpose |
|---|---|---|---|
| TXT | _(from Firebase)_ | _(from Firebase)_ | Domain ownership verification |
| A | `@` (apex) | _(from Firebase)_ | Points apex at Hosting |
| AAAA | `@` (apex) | _(from Firebase)_ | IPv6 equivalent, if Firebase issues one |
| CNAME | `www` | _(from Firebase)_ | Points `www` at Hosting / apex redirect |

## 8. Open questions

All resolved so far:
- Primary domain form → **resolved: apex primary, `www` redirects** (§2)
- Rollout sequencing → **resolved: deploy to `*.web.app` first, attach domain after review** (§2)

Still open — flag if either comes up during Phase C:
- Exact registrar and who holds DNS access — not blocking to start Phase A/B, only needed by Phase C (§5)
- Whether the domain already has email/MX records to protect (§4) — unknown until someone actually looks at the registrar's current DNS panel
