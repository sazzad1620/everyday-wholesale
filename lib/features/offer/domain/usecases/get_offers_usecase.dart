import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/offer_entity.dart';
import '../repositories/offer_repository.dart';

/// Param is `includeExpired` — `false` for customers, `true` for the admin.
@injectable
class GetOffersUseCase extends UseCase<List<OfferEntity>, bool> {
  GetOffersUseCase(this._repository);

  final OfferRepository _repository;

  @override
  Future<Either<Failure, List<OfferEntity>>> call(bool params) => _repository.getOffers(includeExpired: params);
}
