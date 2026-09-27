import 'package:web/web.dart' as web;

String? readEmbeddedJson(String elementId) => web.document.getElementById(elementId)?.textContent;
