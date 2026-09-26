import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../home/domain/entities/promo_banner_entity.dart';

abstract class BannerListEvent extends Equatable {
  const BannerListEvent();

  @override
  List<Object?> get props => [];
}

class BannerListRequested extends BannerListEvent {
  const BannerListRequested();
}

class BannerAddRequested extends BannerListEvent {
  const BannerAddRequested({required this.bytes, required this.fileExtension});

  final Uint8List bytes;
  final String fileExtension;

  @override
  List<Object?> get props => [bytes, fileExtension];
}

class BannerDeleteRequested extends BannerListEvent {
  const BannerDeleteRequested(this.banner);

  final PromoBannerEntity banner;

  @override
  List<Object?> get props => [banner];
}

/// Moves the banner at [from] to position [to] in the carousel.
class BannerMoved extends BannerListEvent {
  const BannerMoved({required this.from, required this.to});

  final int from;
  final int to;

  @override
  List<Object?> get props => [from, to];
}
