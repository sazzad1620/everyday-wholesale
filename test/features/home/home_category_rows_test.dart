import 'package:everyday_wholesale/core/errors/failures.dart';
import 'package:everyday_wholesale/core/localization/localized_text.dart';
import 'package:everyday_wholesale/features/home/domain/entities/category_entity.dart';
import 'package:everyday_wholesale/features/home/domain/entities/initial_home_data.dart';
import 'package:everyday_wholesale/features/home/domain/entities/promo_banner_entity.dart';
import 'package:everyday_wholesale/features/home/domain/repositories/home_repository.dart';
import 'package:everyday_wholesale/features/home/domain/usecases/get_categories_usecase.dart';
import 'package:everyday_wholesale/features/home/domain/usecases/get_initial_home_data_usecase.dart';
import 'package:everyday_wholesale/features/home/domain/usecases/get_promo_banners_usecase.dart';
import 'package:everyday_wholesale/features/home/home_layout.dart';
import 'package:everyday_wholesale/features/home/presentation/bloc/home_bloc.dart';
import 'package:everyday_wholesale/features/home/presentation/bloc/home_event.dart';
import 'package:everyday_wholesale/features/home/presentation/bloc/home_state.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_condition.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_entity.dart';
import 'package:everyday_wholesale/features/product/domain/repositories/product_repository.dart';
import 'package:everyday_wholesale/features/product/domain/usecases/get_most_popular_products_usecase.dart';
import 'package:everyday_wholesale/features/product/domain/usecases/get_products_by_category_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

CategoryEntity _category(String id) => CategoryEntity(
  id: id,
  name: LocalizedText(en: id),
  iconKey: id,
);

ProductEntity _product(String id, String categoryId, {bool popular = false}) => ProductEntity(
  id: id,
  name: LocalizedText(en: id),
  price: 100,
  unit: '1 kg',
  categoryId: categoryId,
  iconKey: categoryId,
  description: LocalizedText.empty,
  condition: ProductCondition.dryPackaged,
  origin: 'JP',
  isMostPopular: popular,
);

class _FakeHomeRepository implements HomeRepository {
  _FakeHomeRepository(this.categories);

  final List<CategoryEntity> categories;

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async => Right(categories);
  @override
  Future<Either<Failure, List<PromoBannerEntity>>> getPromoBanners() async => const Right([]);
  @override
  InitialHomeData? initialHomeData() => null;
  @override
  Future<InitialHomeData?> cachedHomeData() async => null;
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.byCategory, {this.failing = const {}});

  final Map<String, List<ProductEntity>> byCategory;
  final Set<String> failing;
  final List<int?> limitsAsked = [];

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory(
    String categoryId, {
    String? subcategoryId,
    int? limit,
  }) async {
    limitsAsked.add(limit);
    if (failing.contains(categoryId)) return const Left(UnexpectedFailure());
    final all = byCategory[categoryId] ?? const [];
    return Right(limit == null ? all : all.take(limit).toList());
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getMostPopularProducts() async =>
      Right([for (final list in byCategory.values) ...list.where((p) => p.isMostPopular)]);
  @override
  Future<Either<Failure, ProductEntity>> getProductById(String id) async => const Left(NotFoundFailure());
  @override
  Future<Either<Failure, List<ProductEntity>>> searchProducts(String query) async => const Right([]);
}

HomeBloc _bloc(_FakeHomeRepository home, _FakeProductRepository products) => HomeBloc(
  GetCategoriesUseCase(home),
  GetPromoBannersUseCase(home),
  GetMostPopularProductsUseCase(products),
  GetInitialHomeDataUseCase(home),
  GetProductsByCategoryUseCase(products),
);

Future<HomeLoaded> _finalState(HomeBloc bloc) async {
  bloc.add(const HomeStarted());
  return bloc.stream
      .where((s) => s is HomeLoaded && s.categoryRows.isNotEmpty)
      .cast<HomeLoaded>()
      .first
      .timeout(const Duration(seconds: 5));
}

void main() {
  test('rows: only categories that have products, in category order, capped', () async {
    final products = _FakeProductRepository(
      {
        'beans': [for (var i = 0; i < 25; i++) _product('b$i', 'beans', popular: i == 0)],
        'dates': const [],
        'fish': [_product('f1', 'fish')],
        'broken': [_product('x1', 'broken')],
      },
      failing: {'broken'},
    );
    final bloc = _bloc(
      _FakeHomeRepository([_category('beans'), _category('dates'), _category('fish'), _category('broken')]),
      products,
    );

    final state = await _finalState(bloc);

    expect(state.categoryRows.map((r) => r.category.id), ['beans', 'fish']);
    expect(state.categoryRows[0].products, hasLength(kHomeRowProductLimit));
    expect(state.categoryRows[0].hasMore, isTrue);
    expect(state.categoryRows[1].products, hasLength(1));
    expect(state.categoryRows[1].hasMore, isFalse);
    expect(products.limitsAsked, everyElement(kHomeRowProductLimit));
    // Most Everyday is the virtual category — it has no row of its own here.
    expect(state.categoryRows.any((r) => r.category.id == 'most_popular'), isFalse);
    expect(state.categories.first.id, 'most_popular');
    expect(state.mostPopularProducts.map((p) => p.id), ['b0']);
    await bloc.close();
  });
}
