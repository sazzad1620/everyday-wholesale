import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../offer/domain/entities/offer_entity.dart';
import '../../../../offer/domain/usecases/create_offer_usecase.dart';

class OfferFormSubmitted extends Equatable {
  const OfferFormSubmitted(this.offer);

  final OfferEntity offer;

  @override
  List<Object?> get props => [offer];
}

class OfferFormState extends Equatable {
  const OfferFormState({this.isSubmitting = false, this.errorMessage, this.success = false});

  final bool isSubmitting;
  final String? errorMessage;

  /// Set once the offer is saved — the form page pops on this.
  final bool success;

  @override
  List<Object?> get props => [isSubmitting, errorMessage, success];
}

/// One per form visit (`@injectable`, not shared) — same shape as
/// [CategoryFormBloc].
@injectable
class OfferFormBloc extends Bloc<OfferFormSubmitted, OfferFormState> {
  OfferFormBloc(this._createOfferUseCase) : super(const OfferFormState()) {
    on<OfferFormSubmitted>(_onSubmitted);
  }

  final CreateOfferUseCase _createOfferUseCase;

  Future<void> _onSubmitted(OfferFormSubmitted event, Emitter<OfferFormState> emit) async {
    emit(const OfferFormState(isSubmitting: true));
    final result = await _createOfferUseCase(event.offer);
    result.match(
      (failure) => emit(OfferFormState(errorMessage: failure.messageKey)),
      (_) => emit(const OfferFormState(success: true)),
    );
  }
}
