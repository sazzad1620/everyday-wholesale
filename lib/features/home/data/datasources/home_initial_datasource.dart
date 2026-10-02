import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/web/embedded_json.dart';
import '../../../product/data/models/product_model.dart';
import '../../domain/entities/initial_home_data.dart';
import '../models/category_model.dart';
import '../models/promo_banner_model.dart';

/// Home data available *before* a network round trip, used for the first
/// paint and then refreshed from Firestore:
/// - web: embedded in the server-rendered page ([read]);
/// - Android/iOS: Firestore's on-device offline cache ([readCached]).
abstract class HomeInitialDatasource {
  /// The server-embedded home data, or null (mobile, non-home pages, or
  /// anything unparseable). Parsed once and then served from memory.
  InitialHomeData? read();

  /// Mobile only: the home data from Firestore's local cache (what the app
  /// showed last time), or null on web / first launch / empty cache.
  Future<InitialHomeData?> readCached();
}

@LazySingleton(as: HomeInitialDatasource)
class HomeInitialDatasourceImpl implements HomeInitialDatasource {
  HomeInitialDatasourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const _elementId = 'initial-data';
  static const _fromCache = GetOptions(source: Source.cache);

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

  @override
  Future<InitialHomeData?> readCached() async {
    // Web keeps no persistent Firestore cache (and gets server-embedded
    // data instead).
    if (kIsWeb) return null;
    try {
      final results = await Future.wait([
        _firestore.collection('categories').get(_fromCache),
        _firestore.collection('banners').orderBy('order').get(_fromCache),
        _firestore.collection('products').where('isMostPopular', isEqualTo: true).get(_fromCache),
      ]);
      final categories = results[0].docs.map((d) => CategoryModel.fromMap(d.data(), id: d.id)).toList();
      if (categories.isEmpty) return null; // nothing cached yet (first launch)
      return InitialHomeData(
        categories: categories,
        banners: results[1].docs.map((d) => PromoBannerModel.fromMap(d.data(), id: d.id)).toList(),
        popular: results[2].docs.map((d) => ProductModel.fromMap(d.data(), id: d.id)).toList(),
      );
    } catch (_) {
      return null;
    }
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
