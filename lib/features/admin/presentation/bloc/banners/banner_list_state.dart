import 'package:equatable/equatable.dart';

import '../../../../home/domain/entities/promo_banner_entity.dart';

/// Flag-based like [CategoryListState] — uploads, deletes and reorders all
/// keep the current list on screen and just toggle [isBusy].
class BannerListState extends Equatable {
  const BannerListState({
    this.isLoading = false,
    this.banners = const [],
    this.isBusy = false,
    this.errorMessage,
  });

  final bool isLoading;
  final List<PromoBannerEntity> banners;

  /// An upload, delete or reorder is in flight.
  final bool isBusy;
  final String? errorMessage;

  bool get isFull => banners.length >= PromoBannerEntity.maxBanners;

  BannerListState copyWith({
    bool? isLoading,
    List<PromoBannerEntity>? banners,
    bool? isBusy,
    String? errorMessage,
  }) => BannerListState(
    isLoading: isLoading ?? this.isLoading,
    banners: banners ?? this.banners,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [isLoading, banners, isBusy, errorMessage];
}
