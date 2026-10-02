import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

@injectable
class ClearCartUseCase extends UseCase<void, NoParams> {
  ClearCartUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) => _repository.clear();
}
