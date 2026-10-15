import 'image_prefetch_stub.dart' if (dart.library.js_interop) 'image_prefetch_web.dart' as impl;

/// Starts downloading [url] into the browser's HTTP cache (web only; no-op on
/// Android/iOS, which keep their own disk cache). Used when a visitor shows
/// intent to open a product (mouse over / finger down on its card), so the
/// full-size photo is already on its way — or done — when the page opens.
///
/// Safe to call repeatedly: each URL is requested once per session.
void prefetchImage(String url) => impl.prefetchImage(url);
