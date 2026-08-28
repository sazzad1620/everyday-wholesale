import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/address_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateAddressParams extends Equatable {
  const UpdateAddressParams({required this.uid, required this.address});

  final String uid;
  final AddressEntity address;

  @override
  List<Object?> get props => [uid, address];
}

@injectable
class UpdateAddressUseCase extends UseCase<Unit, UpdateAddressParams> {
  UpdateAddressUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(UpdateAddressParams params) =>
      _repository.updateAddress(uid: params.uid, address: params.address);
}
