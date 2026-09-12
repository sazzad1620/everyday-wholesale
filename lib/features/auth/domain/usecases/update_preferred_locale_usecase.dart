import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class UpdatePreferredLocaleParams extends Equatable {
  const UpdatePreferredLocaleParams({required this.uid, required this.languageCode});

  final String uid;
  final String languageCode;

  @override
  List<Object?> get props => [uid, languageCode];
}

@injectable
class UpdatePreferredLocaleUseCase extends UseCase<Unit, UpdatePreferredLocaleParams> {
  UpdatePreferredLocaleUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(UpdatePreferredLocaleParams params) =>
      _repository.updatePreferredLocale(uid: params.uid, languageCode: params.languageCode);
}
