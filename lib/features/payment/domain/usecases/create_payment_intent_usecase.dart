import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/payment_repository.dart';

@injectable
class CreatePaymentIntentUseCase extends UseCase<String, String> {
  CreatePaymentIntentUseCase(this._repository);

  final PaymentRepository _repository;

  @override
  Future<Either<Failure, String>> call(String params) => _repository.createPaymentIntent(params);
}
