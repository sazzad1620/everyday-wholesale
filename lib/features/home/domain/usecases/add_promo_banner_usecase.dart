import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_banner_repository.dart';

class AddPromoBannerParams extends Equatable {
  const AddPromoBannerParams({required this.bytes, required this.fileExtension, required this.order});

  final Uint8List bytes;
  final String fileExtension;
  final int order;

  @override
  List<Object?> get props => [bytes, fileExtension, order];
}

/// Uploads the image and creates its `banners` doc in one step — a banner
/// has nothing else to fill in, so there's no separate form to save.
@injectable
class AddPromoBannerUseCase extends UseCase<void, AddPromoBannerParams> {
  AddPromoBannerUseCase(this._repository);

  final AdminBannerRepository _repository;

  @override
  Future<Either<Failure, void>> call(AddPromoBannerParams params) =>
      _repository.addBanner(params.bytes, params.fileExtension, params.order);
}
