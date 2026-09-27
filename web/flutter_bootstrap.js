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

// No service worker: Flutter's is deprecated, and it was only an extra
// request on every load.
_flutter.loader.load();
