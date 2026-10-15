import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

final Set<String> _requested = {};

void prefetchImage(String url) {
  if (!url.startsWith('http') || !_requested.add(url)) return;
  // Same kind of request the app's image loader makes (cross-origin, no
  // credentials), so its later request for this URL is answered from the
  // browser cache — Storage serves photos `immutable`. The body is read so the
  // download completes and is stored.
  unawaited(
    web.window
        .fetch(url.toJS, web.RequestInit(mode: 'cors'))
        .toDart
        .then((response) => response.arrayBuffer().toDart)
        .then<void>((_) {}, onError: (_) => _requested.remove(url)),
  );
}
