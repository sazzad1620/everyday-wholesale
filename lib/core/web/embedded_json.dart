import 'embedded_json_stub.dart' if (dart.library.js_interop) 'embedded_json_web.dart' as impl;

/// Text of the `<script type="application/json" id="[elementId]">` element
/// the `ssr` Cloud Function embeds in server-rendered pages, or null (no
/// such element, or not running on web).
String? readEmbeddedJson(String elementId) => impl.readEmbeddedJson(elementId);
