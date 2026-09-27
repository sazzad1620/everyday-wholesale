import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/storage_upload_settings.dart';
import '../../../../core/utils/image_optimizer.dart';
import '../models/promo_banner_model.dart';

abstract class AdminBannerRemoteDatasource {
  Future<void> createBanner(Uint8List bytes, String fileExtension, int order);

  Future<void> deleteBanner(PromoBannerModel banner);

  Future<void> reorderBanners(List<PromoBannerModel> banners);
}

@LazySingleton(as: AdminBannerRemoteDatasource)
class AdminBannerRemoteDatasourceImpl implements AdminBannerRemoteDatasource {
  AdminBannerRemoteDatasourceImpl(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _bannersCollection = 'banners';
  static const _bannerImagesFolder = 'banner_images';

  @override
  Future<void> createBanner(Uint8List bytes, String fileExtension, int order) async {
    final encoded = await ImageOptimizer.toJpegs(bytes, maxDimensions: const [StorageUploadSettings.bannerSize]);
    // Undecodable here (e.g. HEIC) — upload the original as-is.
    final (uploadBytes, extension, contentType) = encoded == null
        ? (bytes, fileExtension, _contentTypeFor(fileExtension))
        : (encoded.first, ImageOptimizer.fileExtension, ImageOptimizer.contentType);

    final path = '$_bannerImagesFolder/${DateTime.now().microsecondsSinceEpoch}.$extension';
    final ref = _storage.ref(path);
    await ref.putData(
      uploadBytes,
      SettableMetadata(contentType: contentType, cacheControl: StorageUploadSettings.cacheControl),
    );
    final url = await ref.getDownloadURL();
    await _firestore
        .collection(_bannersCollection)
        .doc()
        .set(PromoBannerModel(id: '', imageUrl: url, storagePath: path, order: order).toMap());
  }

  @override
  Future<void> deleteBanner(PromoBannerModel banner) async {
    await _firestore.collection(_bannersCollection).doc(banner.id).delete();
    // The doc is what customers see, so it goes first; a leftover file
    // (already gone, or a failed delete) is harmless and shouldn't surface
    // as an error once the banner itself is removed.
    if (banner.storagePath.isNotEmpty) {
      try {
        await _storage.ref(banner.storagePath).delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> reorderBanners(List<PromoBannerModel> banners) {
    final batch = _firestore.batch();
    for (final banner in banners) {
      batch.update(_firestore.collection(_bannersCollection).doc(banner.id), {'order': banner.order});
    }
    return batch.commit();
  }

  // Same mapping as product images — `image/jpg` isn't a registered type.
  String _contentTypeFor(String fileExtension) => switch (fileExtension.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'heic' => 'image/heic',
    final other => 'image/$other',
  };
}
