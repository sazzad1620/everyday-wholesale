import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/offer_entity.dart';
import '../repositories/offer_repository.dart';

@injectable
class CreateOfferUseCase extends UseCase<void, OfferEntity> {
  CreateOfferUseCase(this._repository);

  final OfferRepository _repository;

  @override
  Future<Either<Failure, void>> call(OfferEntity params) => _repository.createOffer(params);
}
