import type {Firestore} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onRequest} from "firebase-functions/v2/https";

import {loadPageData, loadSitemapData} from "./catalog";
import {SITE_URL, parseRoute, renderPage, renderSitemap} from "./render";

/**
 * Hosts allowed to serve the app shell. The function trusts the
 * `x-forwarded-host` Firebase Hosting sends only if it's one of these —
 * otherwise anyone calling the function URL directly could make it fetch
 * and re-serve some other site's HTML.
 */
const ALLOWED_HOSTS = new Set([
  "everydaywholesale.jp",
  "www.everydaywholesale.jp",
  "everyday-wholesale.web.app",
  "everyday-wholesale.firebaseapp.com",
]);

// The Flutter app shell, as currently deployed. Re-fetched at most every 10 s
// per instance (Hosting purges its CDN on deploy, and SSR pages are CDN-cached,
// so this is rarely hit), so a Hosting deploy (new versioned bootstrap) is
// picked up without redeploying the function.
const TEMPLATE_TTL_MS = 10 * 1000;
let templateCache: {origin: string; html: string; fetchedAt: number} | null = null;

async function appShell(origin: string): Promise<string> {
  if (templateCache && templateCache.origin === origin && Date.now() - templateCache.fetchedAt < TEMPLATE_TTL_MS) {
    return templateCache.html;
  }
  const res = await fetch(`${origin}/app.html`, {headers: {"cache-control": "no-cache"}});
  if (!res.ok) throw new Error(`app.html fetch failed: ${res.status}`);
  const html = await res.text();
  templateCache = {origin, html, fetchedAt: Date.now()};
  return html;
}

function originOf(forwardedHost: string | undefined): string {
  const host = (forwardedHost ?? "").split(",")[0].trim().toLowerCase();
  return ALLOWED_HOSTS.has(host) ? `https://${host}` : SITE_URL;
}

// Hosting's CDN keeps each rendered page for 30 minutes, and for a day after
// that may still serve the old copy instantly while it fetches a fresh one in
// the background (stale-while-revalidate) — so a visitor only waits for the
// function when a page hasn't been requested for over a day (or right after a
// deploy, which purges the CDN). The embedded data is just the first-paint
// snapshot: the app refreshes from Firestore right after. Browsers always
// re-check (the page embeds the current app version).
const PAGE_CACHE = "public, max-age=0, s-maxage=1800, stale-while-revalidate=86400";

export function seoHandlers(db: Firestore) {
  /** Public storefront pages: `/`, `/home`, `/home/category/**`. */
  // A full vCPU (and 512 MiB, the minimum that allows it) instead of the
  // default 0.17 vCPU: a cold start is almost all CPU-bound work (loading the
  // Firebase SDK) — measured at ~3.5 s for a first request — and the page
  // render is CPU work too. It is billed only while a request is running, so
  // with a CDN in front it costs cents. `keepSsrWarm` (index.ts) pings this
  // function so it rarely goes cold at all, at no extra cost.
  const ssr = onRequest({memory: "512MiB", cpu: 1, timeoutSeconds: 30}, async (req, res) => {
    const origin = originOf(req.get("x-forwarded-host"));
    const route = parseRoute(req.path);

    // The app shell and the page data are independent, so fetch them together
    // instead of one after the other (that sequence was most of a cache miss).
    const [shell, data] = await Promise.allSettled([appShell(origin), loadPageData(db, route)]);

    if (shell.status === "rejected") {
      logger.error("ssr: could not load app shell", shell.reason);
      res.status(502).set("Cache-Control", "no-store").send("Temporarily unavailable, please reload.");
      return;
    }
    const template = shell.value;

    try {
      if (data.status === "rejected") throw data.reason;
      const page = renderPage(template, data.value);
      res.status(page.status).set("Cache-Control", PAGE_CACHE).type("html").send(page.html);
    } catch (e) {
      // Never let a data problem take the storefront down: serve the plain
      // app shell (the app loads its own data) and don't cache it.
      logger.error("ssr: render failed, serving plain shell", {path: req.path, error: e});
      res.status(200).set("Cache-Control", "no-store").type("html").send(template);
    }
  });

  /** `/sitemap.xml` — every public category and product page. */
  const sitemap = onRequest({memory: "256MiB", timeoutSeconds: 30}, async (_req, res) => {
    try {
      const {categories, products, hasPopular} = await loadSitemapData(db);
      res.status(200)
        .set("Cache-Control", "public, max-age=3600, s-maxage=3600")
        .type("application/xml")
        .send(renderSitemap(categories, products, hasPopular));
    } catch (e) {
      logger.error("sitemap failed", e);
      res.status(500).set("Cache-Control", "no-store").send("Sitemap unavailable");
    }
  });

  return {ssr, sitemap};
}
