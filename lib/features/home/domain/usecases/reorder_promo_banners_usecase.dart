import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/promo_banner_entity.dart';
import '../repositories/admin_banner_repository.dart';

/// Persists each banner's `order` exactly as given — callers renumber the
/// list before passing it in.
@injectable
class ReorderPromoBannersUseCase extends UseCase<void, List<PromoBannerEntity>> {
  ReorderPromoBannersUseCase(this._repository);

  final AdminBannerRepository _repository;

  @override
  Future<Either<Failure, void>> call(List<PromoBannerEntity> params) => _repository.reorderBanners(params);
}
