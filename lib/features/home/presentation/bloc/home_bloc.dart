import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../product/domain/usecases/get_most_popular_products_usecase.dart';
import '../../domain/entities/most_popular_category.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_initial_home_data_usecase.dart';
import '../../domain/usecases/get_promo_banners_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(
    this._getCategoriesUseCase,
    this._getPromoBannersUseCase,
    this._getMostPopularProductsUseCase,
    this._getInitialHomeDataUseCase,
  ) : super(const HomeInitial()) {
    on<HomeStarted>(_onHomeStarted);
  }

  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetPromoBannersUseCase _getPromoBannersUseCase;
  final GetMostPopularProductsUseCase _getMostPopularProductsUseCase;
  final GetInitialHomeDataUseCase _getInitialHomeDataUseCase;

  Future<void> _onHomeStarted(HomeStarted event, Emitter<HomeState> emit) async {
    // On web the server-rendered page carries the home data — paint it
    // straight away instead of a spinner, then refresh from Firestore below
    // (Equatable state: no rebuild if nothing changed).
    final initial = _getInitialHomeDataUseCase();
    if (initial != null) {
      emit(
        HomeLoaded(
          categories: withMostPopular(initial.categories, hasMostPopular: initial.popular.isNotEmpty),
          promoBanners: initial.banners,
          mostPopularProducts: initial.popular,
        ),
      );
    } else {
      emit(const HomeLoading());
    }

    final categoriesFuture = _getCategoriesUseCase(const NoParams());
    final bannersFuture = _getPromoBannersUseCase(const NoParams());
    final popularFuture = _getMostPopularProductsUseCase(const NoParams());
    final categoriesResult = await categoriesFuture;
    final bannersResult = await bannersFuture;
    final popularResult = await popularFuture;

    // Banners and Most Popular are extras — if either fails to load the home
    // page still works, just without that section (same as when the admin
    // hasn't set any up).
    final banners = bannersResult.getOrElse((_) => const []);
    final mostPopular = popularResult.getOrElse((_) => const []);

    categoriesResult.match(
      // Keep showing the server's data rather than replacing it with an error.
      (failure) {
        if (initial == null) emit(HomeError(failure.messageKey));
      },
      (categories) => emit(
        HomeLoaded(
          categories: withMostPopular(categories, hasMostPopular: mostPopular.isNotEmpty),
          promoBanners: banners,
          mostPopularProducts: mostPopular,
        ),
      ),
    );
  }
}
