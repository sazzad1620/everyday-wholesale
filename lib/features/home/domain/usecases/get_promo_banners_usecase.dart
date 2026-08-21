import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/promo_banner_entity.dart';
import '../repositories/home_repository.dart';

@injectable
class GetPromoBannersUseCase extends UseCase<List<PromoBannerEntity>, NoParams> {
  GetPromoBannersUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, List<PromoBannerEntity>>> call(NoParams params) {
    return _repository.getPromoBanners();
  }
}
