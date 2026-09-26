import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../models/category_model.dart';
import '../models/promo_banner_model.dart';

abstract class HomeRemoteDatasource {
  Future<List<CategoryModel>> getCategories();

  Future<List<PromoBannerModel>> getPromoBanners();
}

@LazySingleton(as: HomeRemoteDatasource)
class HomeRemoteDatasourceImpl implements HomeRemoteDatasource {
  HomeRemoteDatasourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const _categoriesCollection = 'categories';
  static const _bannersCollection = 'banners';

  @override
  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _firestore.collection(_categoriesCollection).get();
    return snapshot.docs.map((doc) => CategoryModel.fromMap(doc.data(), id: doc.id)).toList();
  }

  @override
  Future<List<PromoBannerModel>> getPromoBanners() async {
    final snapshot = await _firestore.collection(_bannersCollection).orderBy('order').get();
    return snapshot.docs.map((doc) => PromoBannerModel.fromMap(doc.data(), id: doc.id)).toList();
  }
}
