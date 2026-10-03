import 'package:equatable/equatable.dart';

abstract class OfferListEvent extends Equatable {
  const OfferListEvent();

  @override
  List<Object?> get props => [];
}

/// [includeExpired] is `true` only for the admin list.
class OfferListRequested extends OfferListEvent {
  const OfferListRequested({this.includeExpired = false});

  final bool includeExpired;

  @override
  List<Object?> get props => [includeExpired];
}

class OfferDeleteRequested extends OfferListEvent {
  const OfferDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
