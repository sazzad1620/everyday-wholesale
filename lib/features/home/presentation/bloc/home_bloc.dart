import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_promo_banners_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._getCategoriesUseCase, this._getPromoBannersUseCase) : super(const HomeInitial()) {
    on<HomeStarted>(_onHomeStarted);
  }

  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetPromoBannersUseCase _getPromoBannersUseCase;

  Future<void> _onHomeStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());

    final categoriesResult = await _getCategoriesUseCase(const NoParams());
    final bannersResult = await _getPromoBannersUseCase(const NoParams());

    categoriesResult.match(
      (failure) => emit(HomeError(failure.message)),
      (categories) => bannersResult.match(
        (failure) => emit(HomeError(failure.message)),
        (banners) => emit(HomeLoaded(categories: categories, promoBanners: banners)),
      ),
    );
  }
}
