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

// Hosting's CDN keeps each rendered page for 5 minutes, so Firestore is read
// at most a few times per page per hour; browsers always re-check (the page
// embeds the current app version, which changes on every deploy).
const PAGE_CACHE = "public, max-age=0, s-maxage=300";

export function seoHandlers(db: Firestore) {
  /** Public storefront pages: `/`, `/home`, `/home/category/**`. */
  const ssr = onRequest({memory: "256MiB", timeoutSeconds: 30}, async (req, res) => {
    const origin = originOf(req.get("x-forwarded-host"));
    let template: string;
    try {
      template = await appShell(origin);
    } catch (e) {
      logger.error("ssr: could not load app shell", e);
      res.status(502).set("Cache-Control", "no-store").send("Temporarily unavailable, please reload.");
      return;
    }

    const route = parseRoute(req.path);
    try {
      const page = renderPage(template, await loadPageData(db, route));
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
