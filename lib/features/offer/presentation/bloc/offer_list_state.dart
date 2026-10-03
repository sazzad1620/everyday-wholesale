import 'package:equatable/equatable.dart';

import '../../domain/entities/offer_entity.dart';

class OfferListState extends Equatable {
  const OfferListState({this.isLoading = false, this.offers = const [], this.isBusy = false, this.errorMessage});

  final bool isLoading;
  final List<OfferEntity> offers;

  /// A delete is in flight; the list stays on screen.
  final bool isBusy;
  final String? errorMessage;

  OfferListState copyWith({bool? isLoading, List<OfferEntity>? offers, bool? isBusy, String? errorMessage}) =>
      OfferListState(
        isLoading: isLoading ?? this.isLoading,
        offers: offers ?? this.offers,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [isLoading, offers, isBusy, errorMessage];
}
