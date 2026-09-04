import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../models/category_model.dart';

abstract class AdminCategoryRemoteDatasource {
  Future<void> createCategory(CategoryModel category);

  Future<void> updateCategory(CategoryModel category);

  Future<void> deleteCategory(String categoryId);
}

@LazySingleton(as: AdminCategoryRemoteDatasource)
class AdminCategoryRemoteDatasourceImpl implements AdminCategoryRemoteDatasource {
  AdminCategoryRemoteDatasourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const _categoriesCollection = 'categories';

  @override
  Future<void> createCategory(CategoryModel category) =>
      _firestore.collection(_categoriesCollection).doc(category.id).set(category.toMap());

  @override
  Future<void> updateCategory(CategoryModel category) =>
      _firestore.collection(_categoriesCollection).doc(category.id).set(category.toMap());

  @override
  Future<void> deleteCategory(String categoryId) =>
      _firestore.collection(_categoriesCollection).doc(categoryId).delete();
}
