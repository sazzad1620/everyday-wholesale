import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_product_repository.dart';

class UploadProductImageParams extends Equatable {
  const UploadProductImageParams({required this.bytes, required this.fileExtension});

  final Uint8List bytes;
  final String fileExtension;

  @override
  List<Object?> get props => [bytes, fileExtension];
}

@injectable
class UploadProductImageUseCase extends UseCase<String, UploadProductImageParams> {
  UploadProductImageUseCase(this._repository);

  final AdminProductRepository _repository;

  @override
  Future<Either<Failure, String>> call(UploadProductImageParams params) =>
      _repository.uploadProductImage(params.bytes, params.fileExtension);
}
