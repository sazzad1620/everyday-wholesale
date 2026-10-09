{{flutter_js}}
{{flutter_build_config}}

// Versioned app URLs (main.dart.wasm?v=…, main.dart.mjs?v=…, main.dart.js?v=…).
//
// Firebase Hosting answers revalidation requests with a full 200 instead of
// a 304, so the old `no-cache` header made every visit re-download the whole
// ~1 MB app. With a per-build version in the URL, firebase.json can mark
// these files `immutable` for a year: returning visitors load them straight
// from the browser cache, and a new deploy changes the version (and so the
// URL), so nobody is ever stuck on an old build. This script itself is
// inlined into index.html, which is never cached.
(function () {
  // Flutter expands this token to a quoted build hash (plus a comment), so
  // it must stay unquoted here.
  var version = {{flutter_service_worker_version}};
  var keys = ['mainWasmPath', 'jsSupportRuntimePath', 'mainJsPath'];
  _flutter.buildConfig.builds.forEach(function (build) {
    keys.forEach(function (key) {
      if (build[key]) build[key] += '?v=' + version;
    });
  });
})();

// Start the app download right away instead of after its helper module.
//
// Flutter's loader fetches `main.dart.wasm` only once `main.dart.mjs` has
// been downloaded *and run* (`(await import(mjs)).compileStreaming(fetch(wasm))`),
// so the ~1 MB download waited for a tiny module — about one extra round trip
// on every first visit. A preload hint lets both travel at once; the loader's
// own fetch then reuses the response. Only for browsers that will pick the
// Wasm build (Chromium with WasmGC — the same test the loader makes, narrowed
// to Chromium so Safari/Firefox, which use the JS build, never download a
// file they won't run). Anything unexpected here just skips the hint.
(function () {
  try {
    var brands = (navigator.userAgentData && navigator.userAgentData.brands) || [];
    var chromium = brands.some(function (b) { return b.brand === 'Chromium'; });
    // Smallest module containing a WasmGC struct type (wasm-feature-detect).
    var wasmGc = WebAssembly.validate(new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 95, 1, 120, 0]));
    if (!chromium || !wasmGc) return;
    var wasmBuild = _flutter.buildConfig.builds.filter(function (b) {
      return b.compileTarget === 'dart2wasm' && b.mainWasmPath;
    })[0];
    if (!wasmBuild) return;
    var link = document.createElement('link');
    link.rel = 'preload';
    link.as = 'fetch';
    link.crossOrigin = 'anonymous';
    link.href = wasmBuild.mainWasmPath;
    document.head.appendChild(link);
  } catch (e) {
    // Optional optimisation only.
  }
})();

// No service worker: Flutter's is deprecated, and it was only an extra
// request on every load.
_flutter.loader.load();
