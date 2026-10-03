import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/has_unseen_offers_usecase.dart';
import '../../domain/usecases/mark_offers_seen_usecase.dart';

abstract class OfferBadgeEvent extends Equatable {
  const OfferBadgeEvent();

  @override
  List<Object?> get props => [];
}

/// Re-checks whether there is an offer the customer hasn't seen yet.
class OfferBadgeRefreshed extends OfferBadgeEvent {
  const OfferBadgeRefreshed();
}

/// The customer opened the Offers page.
class OfferBadgeSeen extends OfferBadgeEvent {
  const OfferBadgeSeen();
}

class OfferBadgeState extends Equatable {
  const OfferBadgeState({this.hasUnseen = false});

  final bool hasUnseen;

  @override
  List<Object?> get props => [hasUnseen];
}

/// App-wide (`@lazySingleton`, like `CartBloc`): the header on every page
/// shows the bell's "new" dot from this one state. A failed check just
/// leaves the dot as it was — it is a hint, never worth an error.
@lazySingleton
class OfferBadgeBloc extends Bloc<OfferBadgeEvent, OfferBadgeState> {
  OfferBadgeBloc(this._hasUnseenOffersUseCase, this._markOffersSeenUseCase) : super(const OfferBadgeState()) {
    on<OfferBadgeRefreshed>(_onRefreshed);
    on<OfferBadgeSeen>(_onSeen);
    add(const OfferBadgeRefreshed());
  }

  final HasUnseenOffersUseCase _hasUnseenOffersUseCase;
  final MarkOffersSeenUseCase _markOffersSeenUseCase;

  Future<void> _onRefreshed(OfferBadgeRefreshed event, Emitter<OfferBadgeState> emit) async {
    final result = await _hasUnseenOffersUseCase(const NoParams());
    result.match((_) {}, (hasUnseen) => emit(OfferBadgeState(hasUnseen: hasUnseen)));
  }

  Future<void> _onSeen(OfferBadgeSeen event, Emitter<OfferBadgeState> emit) async {
    // Dot goes off immediately; the stored marker catches up behind it.
    emit(const OfferBadgeState());
    await _markOffersSeenUseCase(const NoParams());
  }
}
