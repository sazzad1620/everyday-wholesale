// Tests for the SSR renderer (compiled output). Run: npm test
const test = require("node:test");
const assert = require("node:assert/strict");
const {parseRoute, renderPage, renderSitemap} = require("../lib/seo/render");

const TEMPLATE = "<html><head><title>Everyday Wholesale</title>" +
  "<meta name=\"description\" content=\"x\"></head><body><div id=\"app-loader\"></div></body></html>";

const category = {id: "rice_grains", name: {en: "Rice & Grains", ja: "米・穀類"}};
const product = {
  id: "p1", categoryId: "rice_grains", name: {en: "Keri Samba Rice", ja: "ケリサンバライス"},
  description: {en: "Flavorful rice.", ja: ""}, price: 3550, unit: "5 kg", inStock: true,
  images: ["https://img/full.jpg"], thumbnails: ["https://img/thumb.jpg"], reviewCount: 2, ratingSum: 9,
};
const page = (route, extra = {}) =>
  renderPage(TEMPLATE, {route, categories: [category], banners: [], popular: [], products: [], product: null, ...extra});
const jsonLd = (html) => [...html.matchAll(/<script type="application\/ld\+json">([^<]*)<\/script>/g)].map((m) => JSON.parse(m[1]));

test("parses public routes and rejects everything else", () => {
  assert.deepEqual(parseRoute("/"), {kind: "home"});
  assert.deepEqual(parseRoute("/home/"), {kind: "home"});
  assert.deepEqual(parseRoute("/home/category/rice_grains"), {kind: "category", categoryId: "rice_grains"});
  assert.deepEqual(parseRoute("/home/category/a/browse/b"), {kind: "category", categoryId: "a", subcategoryId: "b"});
  assert.deepEqual(parseRoute("/home/category/a/product/p1"), {kind: "product", categoryId: "a", productId: "p1"});
  assert.equal(parseRoute("/home/category/<x>").kind, "other");
  assert.equal(parseRoute("/cart").kind, "other");
});

test("product page: title, canonical, Product JSON-LD with JPY price and stock", () => {
  const {status, html} = page({kind: "product", categoryId: "rice_grains", productId: "p1"}, {product});
  assert.equal(status, 200);
  assert.match(html, /<title>Keri Samba Rice ケリサンバライス — ¥3,550 \| Everyday Wholesale<\/title>/);
  assert.match(html, /<link rel="canonical" href="https:\/\/everydaywholesale\.jp\/home\/category\/rice_grains\/product\/p1">/);
  const ld = jsonLd(html).find((j) => j["@type"] === "Product");
  assert.equal(ld.offers.price, 3550);
  assert.equal(ld.offers.priceCurrency, "JPY");
  assert.equal(ld.offers.availability, "https://schema.org/InStock");
  assert.equal(ld.aggregateRating.ratingValue, 4.5);
  assert.match(html, /src="https:\/\/img\/thumb\.jpg"/, "uses the thumbnail, not the full image");
});

test("unknown product/category → 404 + noindex, never crashes", () => {
  const missing = page({kind: "product", categoryId: "rice_grains", productId: "nope"});
  assert.equal(missing.status, 404);
  assert.match(missing.html, /noindex/);
  assert.equal(page({kind: "category", categoryId: "nope"}).status, 404);
});

test("escapes hostile catalog text in HTML and JSON-LD", () => {
  const evil = {...product, name: {en: "</script><script>alert(1)</script>\"><img onerror=x>", ja: ""}};
  const {html} = page({kind: "product", categoryId: "rice_grains", productId: "p1"}, {product: evil});
  assert.ok(!html.includes("<script>alert(1)"));
  assert.ok(!html.includes("<img onerror"));
  assert.ok(jsonLd(html).length >= 2, "JSON-LD still parses");
});

test("home embeds initial data and links every category; grid has no <img>", () => {
  const popular = [{...product, isMostPopular: true}];
  const {html} = page({kind: "home"}, {popular, banners: [{id: "b", imageUrl: "https://img/banner.jpg", order: 0}]});
  const data = JSON.parse(html.match(/<script type="application\/json" id="initial-data">([^<]*)<\/script>/)[1]);
  assert.equal(data.categories.length, 1);
  assert.equal(data.popular.length, 1);
  assert.match(html, /href="\/home\/category\/most_popular"/);
  assert.match(html, /href="\/home\/category\/rice_grains"/);
  const body = html.slice(html.indexOf("id=\"ssr-content\""));
  assert.equal((body.match(/<img /g) || []).length, 1, "only the small header logo");
});

test("sitemap lists home, categories and products", () => {
  const xml = renderSitemap([category], [product], true);
  assert.match(xml, /<loc>https:\/\/everydaywholesale\.jp\/<\/loc>/);
  assert.match(xml, /most_popular/);
  assert.match(xml, /\/home\/category\/rice_grains\/product\/p1/);
});

test("home preloads banners, phone-only category pictures and product photos, first in <head>", () => {
  const popular = Array.from({length: 8}, (_, i) => ({
    ...product, id: `p${i}`, isMostPopular: true, thumbnails: [`https://img/t${i}.jpg`],
  }));
  const banners = [0, 1, 2].map((i) => ({id: `b${i}`, imageUrl: `https://img/banner${i}.jpg`, order: i}));
  const categories = Array.from({length: 8}, (_, i) => ({id: `c${i}`, name: {en: `C${i}`, ja: ""}, imageUrl: i === 1 ? "" : `https://img/c${i}.jpg`}));
  const {html} = page({kind: "home"}, {popular, banners, categories});
  const links = [...html.matchAll(/<link rel="preload" as="fetch" href="([^"]+)" crossorigin="anonymous" fetchpriority="low"(?: media="([^"]+)")?>/g)]
    .map((m) => m[2] ? `${m[1]} @${m[2]}` : m[1]);
  const phone = "(max-width: 599px)", wide = "(min-width: 600px)";
  assert.deepEqual(links, [
    "https://img/banner0.jpg",
    // first 6 categories, the one without a picture skipped; phones only
    ...[0, 2, 3, 4, 5].map((i) => `https://img/c${i}.jpg @${phone}`),
    "https://img/t0.jpg", "https://img/t1.jpg", "https://img/t2.jpg",
    "https://img/banner1.jpg",
    // cards a phone does not show without scrolling: wide screens only
    ...[3, 4, 5].map((i) => `https://img/t${i}.jpg @${wide}`),
  ]);
  assert.ok(html.indexOf("rel=\"preload\"") < html.indexOf("<title>"), "before everything else in the head");
  // Other pages, and non-https URLs, get none.
  assert.ok(!page({kind: "category", categoryId: "rice_grains"}, {products: [product]}).html.includes("rel=\"preload\""));
  const odd = page({kind: "home"}, {banners: [{id: "b", imageUrl: "javascript:alert(1)", order: 0}]}).html;
  assert.ok(!odd.includes("rel=\"preload\""));
});
