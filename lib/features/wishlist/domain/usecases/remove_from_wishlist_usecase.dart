import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../repositories/wishlist_repository.dart';

@injectable
class RemoveFromWishlistUseCase extends UseCase<List<ProductEntity>, String> {
  RemoveFromWishlistUseCase(this._repository);

  final WishlistRepository _repository;

  @override
  Future<Either<Failure, List<ProductEntity>>> call(String productId) => _repository.removeItem(productId);
}
