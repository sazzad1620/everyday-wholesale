import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/offer_repository.dart';

@injectable
class HasUnseenOffersUseCase extends UseCase<bool, NoParams> {
  HasUnseenOffersUseCase(this._repository);

  final OfferRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) => _repository.hasUnseenOffers();
}
