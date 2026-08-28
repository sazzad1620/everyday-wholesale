import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class UpdateNameParams extends Equatable {
  const UpdateNameParams({required this.uid, required this.name});

  final String uid;
  final String name;

  @override
  List<Object?> get props => [uid, name];
}

@injectable
class UpdateNameUseCase extends UseCase<Unit, UpdateNameParams> {
  UpdateNameUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(UpdateNameParams params) =>
      _repository.updateName(uid: params.uid, name: params.name);
}
