import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../product/data/models/product_model.dart';

abstract class AdminProductRemoteDatasource {
  Future<List<ProductModel>> getAllProducts();

  Future<void> createProduct(ProductModel product);

  Future<void> updateProduct(ProductModel product);

  Future<void> deleteProduct(String productId);

  Future<String> uploadProductImage(Uint8List bytes, String fileExtension);
}

@LazySingleton(as: AdminProductRemoteDatasource)
class AdminProductRemoteDatasourceImpl implements AdminProductRemoteDatasource {
  AdminProductRemoteDatasourceImpl(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _productsCollection = 'products';
  static const _productImagesFolder = 'product_images';

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final snapshot = await _firestore.collection(_productsCollection).get();
    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), id: doc.id)).toList();
  }

  @override
  // `product.id` is a caller-side placeholder here (unlike categories,
  // products have no natural stable slug) — a fresh Firestore-generated doc
  // id is used instead, same as any other auto-id collection.
  Future<void> createProduct(ProductModel product) =>
      _firestore.collection(_productsCollection).doc().set(product.toMap());

  @override
  Future<void> updateProduct(ProductModel product) =>
      _firestore.collection(_productsCollection).doc(product.id).set(product.toMap());

  @override
  Future<void> deleteProduct(String productId) =>
      _firestore.collection(_productsCollection).doc(productId).delete();

  @override
  Future<String> uploadProductImage(Uint8List bytes, String fileExtension) async {
    // Filename only needs to be unique, not meaningful — nothing reads it
    // back except via the download URL saved on the product doc.
    final path = '$_productImagesFolder/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: _contentTypeFor(fileExtension)));
    return ref.getDownloadURL();
  }

  // 'jpg'/'jpeg' both map to the one registered `image/jpeg` MIME type —
  // `image/jpg` isn't a real one and some browsers/viewers mishandle it.
  String _contentTypeFor(String fileExtension) => switch (fileExtension.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'heic' => 'image/heic',
    final other => 'image/$other',
  };
}
