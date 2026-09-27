import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/web/embedded_json.dart';
import '../../../product/data/models/product_model.dart';
import '../../domain/entities/initial_home_data.dart';
import '../models/category_model.dart';
import '../models/promo_banner_model.dart';

abstract class HomeInitialDatasource {
  /// The server-embedded home data, or null (mobile, non-home pages, or
  /// anything unparseable). Parsed once and then served from memory.
  InitialHomeData? read();
}

@LazySingleton(as: HomeInitialDatasource)
class HomeInitialDatasourceImpl implements HomeInitialDatasource {
  static const _elementId = 'initial-data';

  bool _parsed = false;
  InitialHomeData? _data;

  @override
  InitialHomeData? read() {
    if (_parsed) return _data;
    _parsed = true;
    final raw = readEmbeddedJson(_elementId);
    if (raw == null || raw.isEmpty) return null;
    return _data = parseInitialHomeData(raw);
  }
}

/// Parses the JSON written by `functions/src/seo/render.ts` (`homeMeta`'s
/// `initialData`). The server embeds raw Firestore documents plus their
/// `id`, so the regular models parse them exactly as they parse Firestore
/// reads. Returns null for anything malformed, so the app just loads
/// normally.
@visibleForTesting
InitialHomeData? parseInitialHomeData(String raw) {
  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    List<Map<String, dynamic>> docs(String key) =>
        (json[key] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return InitialHomeData(
      categories: [for (final d in docs('categories')) CategoryModel.fromMap(d, id: d['id'] as String)],
      banners: [for (final d in docs('banners')) PromoBannerModel.fromMap(d, id: d['id'] as String)],
      popular: [for (final d in docs('popular')) ProductModel.fromMap(d, id: d['id'] as String)],
    );
  } catch (_) {
    return null;
  }
}
