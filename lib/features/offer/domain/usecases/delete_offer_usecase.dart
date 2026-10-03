import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/offer_repository.dart';

@injectable
class DeleteOfferUseCase extends UseCase<void, String> {
  DeleteOfferUseCase(this._repository);

  final OfferRepository _repository;

  @override
  Future<Either<Failure, void>> call(String params) => _repository.deleteOffer(params);
}
