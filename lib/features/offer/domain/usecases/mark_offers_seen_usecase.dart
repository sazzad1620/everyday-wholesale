import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/offer_repository.dart';

@injectable
class MarkOffersSeenUseCase extends UseCase<void, NoParams> {
  MarkOffersSeenUseCase(this._repository);

  final OfferRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) => _repository.markOffersSeen();
}
