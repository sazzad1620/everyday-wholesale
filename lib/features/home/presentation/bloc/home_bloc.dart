import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../product/domain/usecases/get_most_popular_products_usecase.dart';
import '../../../product/domain/usecases/get_products_by_category_usecase.dart';
import '../../home_layout.dart';
import '../../domain/entities/category_entity.dart';
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
    this._getProductsByCategoryUseCase,
  ) : super(const HomeInitial()) {
    on<HomeStarted>(_onHomeStarted);
  }

  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetPromoBannersUseCase _getPromoBannersUseCase;
  final GetMostPopularProductsUseCase _getMostPopularProductsUseCase;
  final GetInitialHomeDataUseCase _getInitialHomeDataUseCase;
  final GetProductsByCategoryUseCase _getProductsByCategoryUseCase;

  Future<void> _onHomeStarted(HomeStarted event, Emitter<HomeState> emit) async {
    // Paint data we already have straight away instead of a spinner, then
    // refresh from Firestore below (Equatable state: no rebuild if nothing
    // changed): on web the server-rendered page carries the home data; on
    // Android/iOS it's whatever Firestore cached on the device last time.
    var initial = _getInitialHomeDataUseCase();
    if (initial == null) {
      emit(const HomeLoading());
      initial = await _getInitialHomeDataUseCase.cached();
    }
    if (initial != null) {
      emit(
        HomeLoaded(
          categories: withMostPopular(initial.categories, hasMostPopular: initial.popular.isNotEmpty),
          promoBanners: initial.banners,
          mostPopularProducts: initial.popular,
        ),
      );
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

    List<CategoryEntity>? loadedCategories;
    categoriesResult.match(
      // Keep showing the server's data rather than replacing it with an error.
      (failure) {
        if (initial == null) emit(HomeError(failure.messageKey));
      },
      (categories) {
        loadedCategories = categories;
        emit(
          HomeLoaded(
            categories: withMostPopular(categories, hasMostPopular: mostPopular.isNotEmpty),
            promoBanners: banners,
            mostPopularProducts: mostPopular,
          ),
        );
      },
    );

    // The product rows come last, so the banner, categories and Most Everyday
    // are already on screen while they load.
    final categories = loadedCategories;
    if (kHomeShowsCategoryRows && categories != null) {
      final rows = await _loadCategoryRows(categories);
      if (!emit.isDone) {
        emit(
          HomeLoaded(
            categories: withMostPopular(categories, hasMostPopular: mostPopular.isNotEmpty),
            promoBanners: banners,
            mostPopularProducts: mostPopular,
            categoryRows: rows,
          ),
        );
      }
    }
  }

  /// First [kHomeRowProductLimit] products of every category, loaded in
  /// parallel. Categories with no products — or whose lookup failed — are
  /// left out, so a hiccup in one never blocks the others.
  Future<List<HomeCategoryRow>> _loadCategoryRows(List<CategoryEntity> categories) async {
    final results = await Future.wait([
      for (final category in categories)
        _getProductsByCategoryUseCase(
          GetProductsByCategoryParams(categoryId: category.id, limit: kHomeRowProductLimit),
        ),
    ]);
    return [
      for (var i = 0; i < categories.length; i++)
        ...results[i].match(
          (_) => const <HomeCategoryRow>[],
          (products) => products.isEmpty
              ? const <HomeCategoryRow>[]
              : [
                  HomeCategoryRow(
                    category: categories[i],
                    products: products,
                    hasMore: products.length >= kHomeRowProductLimit,
                  ),
                ],
        ),
    ];
  }
}
