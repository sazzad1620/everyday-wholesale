import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../models/category_model.dart';

abstract class HomeRemoteDatasource {
  Future<List<CategoryModel>> getCategories();
}

@LazySingleton(as: HomeRemoteDatasource)
class HomeRemoteDatasourceImpl implements HomeRemoteDatasource {
  HomeRemoteDatasourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const _categoriesCollection = 'categories';

  @override
  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _firestore.collection(_categoriesCollection).get();
    return snapshot.docs.map((doc) => CategoryModel.fromMap(doc.data(), id: doc.id)).toList();
  }
}
