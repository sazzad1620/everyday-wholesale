import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/promo_banner_entity.dart';
import '../repositories/admin_banner_repository.dart';

@injectable
class DeletePromoBannerUseCase extends UseCase<void, PromoBannerEntity> {
  DeletePromoBannerUseCase(this._repository);

  final AdminBannerRepository _repository;

  @override
  Future<Either<Failure, void>> call(PromoBannerEntity params) => _repository.deleteBanner(params);
}
