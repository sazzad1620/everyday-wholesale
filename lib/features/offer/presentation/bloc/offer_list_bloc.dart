import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/delete_offer_usecase.dart';
import '../../domain/usecases/get_offers_usecase.dart';
import 'offer_list_event.dart';
import 'offer_list_state.dart';

/// Shared by the customer Offers page and the admin Offers tab — one per
/// screen visit (`@injectable`, not shared).
@injectable
class OfferListBloc extends Bloc<OfferListEvent, OfferListState> {
  OfferListBloc(this._getOffersUseCase, this._deleteOfferUseCase) : super(const OfferListState()) {
    on<OfferListRequested>(_onRequested);
    on<OfferDeleteRequested>(_onDeleteRequested);
  }

  final GetOffersUseCase _getOffersUseCase;
  final DeleteOfferUseCase _deleteOfferUseCase;

  bool _includeExpired = false;

  Future<void> _onRequested(OfferListRequested event, Emitter<OfferListState> emit) async {
    _includeExpired = event.includeExpired;
    emit(const OfferListState(isLoading: true));
    await _reload(emit);
  }

  Future<void> _onDeleteRequested(OfferDeleteRequested event, Emitter<OfferListState> emit) async {
    emit(state.copyWith(isBusy: true));
    final result = await _deleteOfferUseCase(event.id);
    await result.match(
      (failure) async => emit(state.copyWith(isBusy: false, errorMessage: failure.messageKey)),
      (_) async => _reload(emit),
    );
  }

  Future<void> _reload(Emitter<OfferListState> emit) async {
    final result = await _getOffersUseCase(_includeExpired);
    result.match(
      (failure) => emit(OfferListState(offers: state.offers, errorMessage: failure.messageKey)),
      (offers) => emit(OfferListState(offers: offers)),
    );
  }
}
