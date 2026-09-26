import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/usecase/usecase.dart';
import '../../../../home/domain/usecases/add_promo_banner_usecase.dart';
import '../../../../home/domain/usecases/delete_promo_banner_usecase.dart';
import '../../../../home/domain/usecases/get_promo_banners_usecase.dart';
import '../../../../home/domain/usecases/reorder_promo_banners_usecase.dart';
import 'banner_list_event.dart';
import 'banner_list_state.dart';

@injectable
class BannerListBloc extends Bloc<BannerListEvent, BannerListState> {
  BannerListBloc(
    this._getPromoBannersUseCase,
    this._addPromoBannerUseCase,
    this._deletePromoBannerUseCase,
    this._reorderPromoBannersUseCase,
  ) : super(const BannerListState()) {
    on<BannerListRequested>(_onRequested);
    on<BannerAddRequested>(_onAddRequested);
    on<BannerDeleteRequested>(_onDeleteRequested);
    on<BannerMoved>(_onMoved);
  }

  final GetPromoBannersUseCase _getPromoBannersUseCase;
  final AddPromoBannerUseCase _addPromoBannerUseCase;
  final DeletePromoBannerUseCase _deletePromoBannerUseCase;
  final ReorderPromoBannersUseCase _reorderPromoBannersUseCase;

  Future<void> _onRequested(BannerListRequested event, Emitter<BannerListState> emit) async {
    emit(const BannerListState(isLoading: true));
    await _reload(emit);
  }

  Future<void> _onAddRequested(BannerAddRequested event, Emitter<BannerListState> emit) async {
    if (state.isFull) return;
    emit(state.copyWith(isBusy: true));
    // New banners go to the end of the rotation.
    final nextOrder = state.banners.isEmpty ? 0 : state.banners.last.order + 1;
    final result = await _addPromoBannerUseCase(
      AddPromoBannerParams(bytes: event.bytes, fileExtension: event.fileExtension, order: nextOrder),
    );
    await result.match(
      (failure) async => emit(state.copyWith(isBusy: false, errorMessage: failure.messageKey)),
      (_) async => _reload(emit),
    );
  }

  Future<void> _onDeleteRequested(BannerDeleteRequested event, Emitter<BannerListState> emit) async {
    emit(state.copyWith(isBusy: true));
    final result = await _deletePromoBannerUseCase(event.banner);
    await result.match(
      (failure) async => emit(state.copyWith(isBusy: false, errorMessage: failure.messageKey)),
      (_) async => _reload(emit),
    );
  }

  Future<void> _onMoved(BannerMoved event, Emitter<BannerListState> emit) async {
    if (event.to < 0 || event.to >= state.banners.length || event.from == event.to) return;
    final reordered = [...state.banners];
    reordered.insert(event.to, reordered.removeAt(event.from));
    final renumbered = [for (var i = 0; i < reordered.length; i++) reordered[i].copyWith(order: i)];

    // Shown immediately so the move feels instant; reloaded from Firestore
    // only if saving fails, to put the real order back.
    emit(state.copyWith(banners: renumbered, isBusy: true));
    final result = await _reorderPromoBannersUseCase(renumbered);
    await result.match(
      (failure) async {
        await _reload(emit);
        emit(state.copyWith(errorMessage: failure.messageKey));
      },
      (_) async => emit(state.copyWith(isBusy: false)),
    );
  }

  Future<void> _reload(Emitter<BannerListState> emit) async {
    final result = await _getPromoBannersUseCase(const NoParams());
    result.match(
      (failure) => emit(BannerListState(banners: state.banners, errorMessage: failure.messageKey)),
      (banners) => emit(BannerListState(banners: banners)),
    );
  }
}
