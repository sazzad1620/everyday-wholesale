import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/admin_category_repository.dart';
import '../datasources/admin_category_remote_datasource.dart';
import '../models/category_model.dart';

@LazySingleton(as: AdminCategoryRepository)
class AdminCategoryRepositoryImpl implements AdminCategoryRepository {
  AdminCategoryRepositoryImpl(this._datasource);

  final AdminCategoryRemoteDatasource _datasource;

  @override
  Future<Either<Failure, void>> createCategory(CategoryEntity category) async {
    try {
      await _datasource.createCategory(_toModel(category));
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(CategoryEntity category) async {
    try {
      await _datasource.updateCategory(_toModel(category));
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String categoryId) async {
    try {
      await _datasource.deleteCategory(categoryId);
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  CategoryModel _toModel(CategoryEntity category) => CategoryModel(
    id: category.id,
    name: category.name,
    iconKey: category.iconKey,
    imageUrl: category.imageUrl,
    subcategories: category.subcategories,
  );
}
