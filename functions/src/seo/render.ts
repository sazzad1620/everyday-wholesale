/**
 * Server-side rendering for the storefront's public pages — pure functions
 * only (no Firebase imports), so they can be tested against any data source.
 *
 * Every public URL still boots the same Flutter app. This only adds, to the
 * app shell (`app.html`):
 *   - a real <title>, meta description, canonical URL and share-card tags,
 *   - JSON-LD structured data (store, breadcrumbs, product price/stock),
 *   - visible, crawlable HTML of the page's content with real <a href> links,
 *     shown until Flutter's first frame replaces it,
 *   - on the home page, the catalog data itself (`#initial-data`), so the
 *     app can paint it without waiting on Firestore.
 * Users and crawlers get the same HTML (no user-agent sniffing), which is
 * what Google recommends instead of "dynamic rendering".
 */

export const SITE_URL = "https://everydaywholesale.jp";
const STORE_NAME = "Everyday Wholesale";
const MOST_POPULAR_ID = "most_popular";
const LOGO_URL = `${SITE_URL}/icons/Icon-512.png`;

/** A Firestore document as plain data, with its id. */
export type Doc = {id: string} & Record<string, unknown>;

export type Route =
  | {kind: "home"}
  | {kind: "category"; categoryId: string; subcategoryId?: string}
  | {kind: "product"; categoryId: string; productId: string}
  | {kind: "other"};

export interface PageData {
  route: Route;
  /** Real categories (never the virtual Most Popular one). */
  categories: Doc[];
  banners: Doc[];
  /** Products flagged Most Popular. */
  popular: Doc[];
  /** Category page: its products. */
  products: Doc[];
  /** Product page: the product (null if it doesn't exist). */
  product: Doc | null;
}

// ------------------------------------------------------------------ routes

const SAFE_ID = /^[A-Za-z0-9_-]{1,128}$/;

/** Maps a request path onto one of the app's public routes. */
export function parseRoute(path: string): Route {
  const clean = path.replace(/\/+$/, "") || "/";
  if (clean === "/" || clean === "/home") return {kind: "home"};

  const parts = clean.split("/").filter(Boolean).map(safeDecode);
  if (parts[0] !== "home" || parts[1] !== "category" || !isId(parts[2])) {
    return {kind: "other"};
  }
  const categoryId = parts[2];
  if (parts.length === 3) return {kind: "category", categoryId};
  if (parts.length === 5 && parts[3] === "browse" && isId(parts[4])) {
    return {kind: "category", categoryId, subcategoryId: parts[4]};
  }
  if (parts.length === 5 && parts[3] === "product" && isId(parts[4])) {
    return {kind: "product", categoryId, productId: parts[4]};
  }
  return {kind: "other"};
}

function safeDecode(s: string): string {
  try {
    return decodeURIComponent(s);
  } catch {
    return "";
  }
}

function isId(s: string | undefined): s is string {
  return typeof s === "string" && SAFE_ID.test(s);
}

// ------------------------------------------------------------------ helpers

interface Text {
  en: string;
  ja: string;
}

/** Reads a `{en, ja}` map or a legacy plain string (mirrors LocalizedText). */
function text(raw: unknown): Text {
  if (raw && typeof raw === "object") {
    const m = raw as Record<string, unknown>;
    return {en: str(m.en), ja: str(m.ja)};
  }
  return {en: str(raw), ja: ""};
}

function str(v: unknown): string {
  return typeof v === "string" ? v : "";
}

function num(v: unknown): number {
  return typeof v === "number" && isFinite(v) ? v : 0;
}

function strList(v: unknown): string[] {
  return Array.isArray(v) ? v.filter((x): x is string => typeof x === "string") : [];
}

export function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;"})[c]!);
}

/** JSON that is safe to put inside a <script> element. */
function scriptJson(value: unknown): string {
  return JSON.stringify(value)
    .replace(/</g, "\\u003c");
}

/** "English 日本語" when both exist, so both are indexed. */
function bilingual(t: Text): string {
  if (t.ja && t.ja !== t.en) return t.en ? `${t.en} ${t.ja}` : t.ja;
  return t.en || t.ja;
}

function yen(price: number): string {
  return `¥${Math.round(price).toLocaleString("en-US")}`;
}

const categoryPath = (id: string) => `/home/category/${encodeURIComponent(id)}`;
const productPath = (categoryId: string, productId: string) =>
  `${categoryPath(categoryId)}/product/${encodeURIComponent(productId)}`;

const mostPopularCategory: Doc = {
  id: MOST_POPULAR_ID,
  name: {en: "Most Everyday", ja: "エブリデイ定番"},
};

function findCategory(data: PageData, id: string): Doc | undefined {
  if (id === MOST_POPULAR_ID) return data.popular.length > 0 ? mostPopularCategory : undefined;
  return data.categories.find((c) => c.id === id);
}

function thumb(p: Doc): string | undefined {
  return strList(p.thumbnails)[0] ?? strList(p.images)[0];
}

// ------------------------------------------------------------------ page

export interface RenderedPage {
  status: number;
  html: string;
}

interface Meta {
  title: string;
  description: string;
  canonicalPath: string;
  image?: string;
  ogType: "website" | "product";
  jsonLd: unknown[];
  body: string;
  initialData?: unknown;
}

/** Renders [data] into the Flutter app shell [template]. */
export function renderPage(template: string, data: PageData): RenderedPage {
  const meta = buildMeta(data);
  if (!meta) return {status: data.route.kind === "other" ? 200 : 404, html: notFound(template, data)};
  return {status: 200, html: inject(template, meta)};
}

function buildMeta(data: PageData): Meta | null {
  const route = data.route;
  switch (route.kind) {
  case "home":
    return homeMeta(data);
  case "category": {
    const category = findCategory(data, route.categoryId);
    return category ? categoryMeta(data, category, route.subcategoryId) : null;
  }
  case "product":
    return data.product ? productMeta(data, data.product) : null;
  default:
    return null;
  }
}

function homeMeta(data: PageData): Meta {
  const visibleCategories = data.popular.length > 0 ? [mostPopularCategory, ...data.categories] : data.categories;
  const hero = str(data.banners[0]?.imageUrl);
  const popular = data.popular.slice(0, 12);

  // No <img> for the banner/product grid on purpose: the browser would fetch
  // them immediately, competing with the Flutter engine download (measured:
  // first frame 4.5 s → 7.6 s on a 6 Mbps link). Image URLs still reach
  // search engines through JSON-LD / og:image; the app loads the photos.
  const body = [
    hero ? "<div class=\"ssr-hero\"></div>" : "",
    `<h1>${STORE_NAME} — Halal food &amp; groceries in Hanyu, Saitama <span lang="ja">毎日卸売・ハラールフード</span></h1>`,
    "<h2>Categories <span lang=\"ja\">カテゴリー</span></h2>",
    `<ul class="ssr-cats">${visibleCategories.map((c) =>
      `<li><a href="${categoryPath(c.id)}">${escapeHtml(bilingual(text(c.name)))}</a></li>`).join("")}</ul>`,
    popular.length ? "<h2>Most Everyday <span lang=\"ja\">エブリデイ定番</span></h2>" + productGrid(popular) : "",
  ].join("");

  return {
    title: `${STORE_NAME} | Halal Food & Groceries in Hanyu, Saitama | 毎日卸売・ハラールフード`,
    description: "Halal meat, rice, spices, frozen food and groceries at wholesale prices. " +
      "Shop online or visit our store in Hanyu, Saitama. 埼玉県羽生市のハラール食品・食料品の卸売店。",
    canonicalPath: "/",
    image: hero || LOGO_URL,
    ogType: "website",
    jsonLd: [storeJsonLd(hero)],
    body,
    // Exactly the Firestore shape the app's models read (see
    // lib/core/web/initial_data.dart).
    initialData: {categories: data.categories, banners: data.banners, popular},
  };
}

function categoryMeta(data: PageData, category: Doc, subcategoryId?: string): Meta {
  const name = text(category.name);
  const sub = subcategoryId ?
    (Array.isArray(category.subcategories) ? category.subcategories as Doc[] : []).find((s) => s.id === subcategoryId) :
    undefined;
  const subName = sub ? text(sub.name) : undefined;
  const heading = subName ? `${bilingual(subName)} — ${bilingual(name)}` : bilingual(name);
  const products = data.products.slice(0, 60);
  const path = subcategoryId ? `${categoryPath(category.id)}/browse/${encodeURIComponent(subcategoryId)}` : categoryPath(category.id);

  const crumbs = [{name: "Home", path: "/"}, {name: bilingual(name), path: categoryPath(category.id)}];
  if (subName) crumbs.push({name: bilingual(subName), path});

  return {
    title: `${heading} | ${STORE_NAME}`,
    description: `${heading} — ${products.length} products at wholesale prices from ${STORE_NAME}, ` +
      "a halal food store in Hanyu, Saitama. Order online.",
    canonicalPath: path,
    image: products.map(thumb).find(Boolean),
    ogType: "website",
    jsonLd: [
      breadcrumbJsonLd(crumbs),
      {
        "@context": "https://schema.org",
        "@type": "ItemList",
        "name": heading,
        "itemListElement": products.map((p, i) => ({
          "@type": "ListItem",
          "position": i + 1,
          "url": SITE_URL + productPath(str(p.categoryId) || category.id, p.id),
          "name": bilingual(text(p.name)),
        })),
      },
    ],
    body: breadcrumbHtml(crumbs) + `<h1>${escapeHtml(heading)}</h1>` +
      (products.length ? productGrid(products) : "<p>No products yet.</p>"),
  };
}

function productMeta(data: PageData, product: Doc): Meta {
  const name = text(product.name);
  const description = text(product.description);
  const categoryId = str(product.categoryId);
  const category = findCategory(data, categoryId);
  const images = strList(product.images);
  const price = num(product.price);
  const unit = str(product.unit);
  const inStock = product.inStock !== false;
  const reviewCount = num(product.reviewCount);
  const ratingSum = num(product.ratingSum);
  const canonicalPath = productPath(categoryId, product.id);
  const heading = bilingual(name);

  const crumbs = [{name: "Home", path: "/"}];
  if (category) crumbs.push({name: bilingual(text(category.name)), path: categoryPath(category.id)});
  crumbs.push({name: heading, path: canonicalPath});

  const productLd: Record<string, unknown> = {
    "@context": "https://schema.org",
    "@type": "Product",
    "name": heading,
    "sku": product.id,
    "image": images,
    "description": [description.en, description.ja].filter(Boolean).join("\n") || heading,
    "brand": {"@type": "Brand", "name": STORE_NAME},
    "offers": {
      "@type": "Offer",
      "url": SITE_URL + canonicalPath,
      "priceCurrency": "JPY",
      "price": Math.round(price),
      "availability": inStock ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
      "itemCondition": "https://schema.org/NewCondition",
      "seller": {"@type": "Organization", "name": STORE_NAME},
    },
  };
  if (reviewCount > 0) {
    productLd.aggregateRating = {
      "@type": "AggregateRating",
      "ratingValue": Math.round((ratingSum / reviewCount) * 10) / 10,
      "reviewCount": reviewCount,
    };
  }

  const priceLine = `${yen(price)}${unit ? ` · ${escapeHtml(unit)}` : ""}`;
  const body = breadcrumbHtml(crumbs) +
    "<div class=\"ssr-product\">" +
    // One photo (the small thumbnail) — it's the page's main content and
    // what image search indexes; far cheaper than a whole product grid.
    (thumb(product) ? `<img src="${escapeHtml(thumb(product)!)}" alt="${escapeHtml(heading)}" ` +
      "width=\"440\" height=\"440\" crossorigin=\"anonymous\" fetchpriority=\"low\">" : "") +
    `<div><h1>${escapeHtml(heading)}</h1>` +
    `<p class="ssr-price">${priceLine}</p>` +
    `<p>${inStock ? "In stock <span lang=\"ja\">在庫あり</span>" : "Out of stock <span lang=\"ja\">在庫切れ</span>"}</p>` +
    (description.en ? `<p>${escapeHtml(description.en)}</p>` : "") +
    (description.ja ? `<p lang="ja">${escapeHtml(description.ja)}</p>` : "") +
    "</div></div>";

  return {
    title: `${heading} — ${yen(price)} | ${STORE_NAME}`,
    description: (description.en || description.ja || heading).slice(0, 155),
    canonicalPath,
    image: images[0],
    ogType: "product",
    jsonLd: [productLd, breadcrumbJsonLd(crumbs)],
    body,
  };
}

function storeJsonLd(image: string): unknown {
  return {
    "@context": "https://schema.org",
    "@type": "GroceryStore",
    "name": STORE_NAME,
    "alternateName": "毎日卸売",
    "url": SITE_URL,
    "logo": LOGO_URL,
    "image": image || LOGO_URL,
    "telephone": "+81-48-577-5313",
    "servesCuisine": "Halal",
    "address": {
      "@type": "PostalAddress",
      "streetAddress": "中央3丁目3-19",
      "addressLocality": "羽生市",
      "addressRegion": "埼玉県",
      "addressCountry": "JP",
    },
  };
}

function breadcrumbJsonLd(crumbs: {name: string; path: string}[]): unknown {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": crumbs.map((c, i) => ({
      "@type": "ListItem",
      "position": i + 1,
      "name": c.name,
      "item": SITE_URL + c.path,
    })),
  };
}

function breadcrumbHtml(crumbs: {name: string; path: string}[]): string {
  return `<nav class="ssr-crumbs">${crumbs.map((c, i) => i === crumbs.length - 1 ?
    `<span>${escapeHtml(c.name)}</span>` :
    `<a href="${c.path}">${escapeHtml(c.name)}</a> › `).join("")}</nav>`;
}

/** Product cards with a photo-sized placeholder (see homeMeta for why no <img>). */
function productGrid(products: Doc[]): string {
  return `<ul class="ssr-grid">${products.map((p) => {
    const name = bilingual(text(p.name));
    return `<li><a href="${productPath(str(p.categoryId), p.id)}"><span class="ssr-ph"></span>` +
      `<span>${escapeHtml(name)}</span><b>${yen(num(p.price))}</b></a></li>`;
  }).join("")}</ul>`;
}

// ------------------------------------------------------------------ template

// Visitors keep seeing the logo loading screen (#app-loader, a fixed
// full-screen overlay from app.html) until Flutter's first frame — a bare
// HTML preview flashing first looked unfinished (client decision). The
// content below stays in the DOM, laid out under that overlay, which is what
// crawlers read; `overflow:hidden` stops the page scrolling behind it.
const SSR_STYLE = "<style>" +
  "body{overflow:hidden}" +
  "#ssr-content{font:15px/1.5 system-ui,-apple-system,'Segoe UI',Roboto,'Hiragino Sans','Noto Sans JP',sans-serif;" +
  "color:#212121;max-width:1180px;margin:0 auto;padding:0 16px 32px}" +
  "#ssr-content a{color:inherit;text-decoration:none}" +
  ".ssr-head{display:flex;align-items:center;gap:8px;padding:12px 0;border-bottom:1px solid #eee;margin-bottom:16px}" +
  ".ssr-head img{width:40px;height:auto}.ssr-head b{font-size:18px;letter-spacing:-.2px}" +
  ".ssr-hero{width:100%;aspect-ratio:12/5;border-radius:20px;background:linear-gradient(135deg,#1b5e20,#2e7d32 60%,#a5d6a7)}" +
  "#ssr-content h1{font-size:22px;margin:16px 0 8px}#ssr-content h2{font-size:18px;margin:20px 0 8px}" +
  ".ssr-cats{list-style:none;padding:0;display:flex;flex-wrap:wrap;gap:8px}" +
  ".ssr-cats a{display:block;padding:8px 14px;border:1px solid #e0e0e0;border-radius:12px;background:#fafafa}" +
  ".ssr-grid{list-style:none;padding:0;display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px}" +
  ".ssr-grid a{display:flex;flex-direction:column;gap:4px;padding:8px;border-radius:16px;box-shadow:0 1px 4px rgba(0,0,0,.12)}" +
  ".ssr-ph{display:block;width:100%;aspect-ratio:1;border-radius:10px;background:#eef5ee}" +
  ".ssr-grid b,.ssr-price{color:#2E7D32;font-weight:700}" +
  ".ssr-crumbs{font-size:13px;color:#757575;margin:8px 0}" +
  ".ssr-product{display:flex;flex-wrap:wrap;gap:24px}.ssr-product>img{width:min(440px,100%);height:auto;aspect-ratio:1;object-fit:cover;border-radius:16px;background:#eef5ee}" +
  ".ssr-product>div{flex:1;min-width:260px}.ssr-price{font-size:22px}" +
  "</style>";

function inject(template: string, meta: Meta): string {
  const url = SITE_URL + meta.canonicalPath;
  const head = [
    `<link rel="canonical" href="${url}">`,
    `<meta property="og:site_name" content="${STORE_NAME}">`,
    `<meta property="og:type" content="${meta.ogType}">`,
    `<meta property="og:title" content="${escapeHtml(meta.title)}">`,
    `<meta property="og:description" content="${escapeHtml(meta.description)}">`,
    `<meta property="og:url" content="${url}">`,
    meta.image ? `<meta property="og:image" content="${escapeHtml(meta.image)}">` : "",
    "<meta name=\"twitter:card\" content=\"summary_large_image\">",
    ...meta.jsonLd.map((ld) => `<script type="application/ld+json">${scriptJson(ld)}</script>`),
  ].join("\n  ");

  const body = SSR_STYLE +
    "<div id=\"ssr-content\">" +
    `<header class="ssr-head"><a href="/"><img src="/icons/loader-logo.webp" alt="${STORE_NAME}" width="40" height="37"></a>` +
    `<a href="/"><b>EVERYDAY WHOLESALE</b></a></header>` +
    meta.body + "</div>" +
    (meta.initialData ? `<script type="application/json" id="initial-data">${scriptJson(meta.initialData)}</script>` : "");

  return template
    .replace(/<title>[^<]*<\/title>/, `<title>${escapeHtml(meta.title)}</title>`)
    .replace(/<meta name="description" content="[^"]*">/, `<meta name="description" content="${escapeHtml(meta.description)}">`)
    .replace("</head>", `  ${head}\n</head>`)
    .replace(/<body>/, `<body>\n  ${body}`);
}

function notFound(template: string, data: PageData): string {
  // Unknown product/category: plain app shell (the app shows its own "not
  // found" UI), but tell crawlers not to index it.
  if (data.route.kind === "other") return template;
  return template.replace("</head>", "  <meta name=\"robots\" content=\"noindex\">\n</head>");
}

// ------------------------------------------------------------------ sitemap

export function renderSitemap(categories: Doc[], products: Doc[], hasPopular: boolean): string {
  const urls = [
    "/",
    ...(hasPopular ? [categoryPath(MOST_POPULAR_ID)] : []),
    ...categories.map((c) => categoryPath(c.id)),
    ...products.filter((p) => str(p.categoryId)).map((p) => productPath(str(p.categoryId), p.id)),
  ];
  return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n" +
    urls.map((u) => `  <url><loc>${escapeHtml(SITE_URL + u)}</loc></url>`).join("\n") +
    "\n</urlset>\n";
}
