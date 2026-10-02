import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductsByCategoryParams extends Equatable {
  const GetProductsByCategoryParams({required this.categoryId, this.subcategoryId, this.limit});

  final String categoryId;

  /// Null means "browse all" — every product in the category regardless of
  /// which subcategory it's in.
  final String? subcategoryId;

  /// Null means no cap.
  final int? limit;

  @override
  List<Object?> get props => [categoryId, subcategoryId, limit];
}

@injectable
class GetProductsByCategoryUseCase extends UseCase<List<ProductEntity>, GetProductsByCategoryParams> {
  GetProductsByCategoryUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<Either<Failure, List<ProductEntity>>> call(GetProductsByCategoryParams params) {
    return _repository.getProductsByCategory(
      params.categoryId,
      subcategoryId: params.subcategoryId,
      limit: params.limit,
    );
  }
}
