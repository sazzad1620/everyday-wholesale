// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:everyday_wholesale/features/account/presentation/bloc/account_bloc.dart'
    as _i1047;
import 'package:everyday_wholesale/features/home/data/datasources/home_mock_datasource.dart'
    as _i589;
import 'package:everyday_wholesale/features/home/data/repositories/home_repository_impl.dart'
    as _i734;
import 'package:everyday_wholesale/features/home/domain/repositories/home_repository.dart'
    as _i339;
import 'package:everyday_wholesale/features/home/domain/usecases/get_categories_usecase.dart'
    as _i353;
import 'package:everyday_wholesale/features/home/domain/usecases/get_promo_banners_usecase.dart'
    as _i674;
import 'package:everyday_wholesale/features/home/presentation/bloc/home_bloc.dart'
    as _i1013;
import 'package:everyday_wholesale/features/product/data/datasources/product_mock_datasource.dart'
    as _i585;
import 'package:everyday_wholesale/features/product/data/repositories/product_repository_impl.dart'
    as _i137;
import 'package:everyday_wholesale/features/product/domain/repositories/product_repository.dart'
    as _i411;
import 'package:everyday_wholesale/features/product/domain/usecases/get_product_by_id_usecase.dart'
    as _i682;
import 'package:everyday_wholesale/features/product/domain/usecases/get_products_by_category_usecase.dart'
    as _i706;
import 'package:everyday_wholesale/features/product/presentation/bloc/product_detail_bloc.dart'
    as _i785;
import 'package:everyday_wholesale/features/product/presentation/bloc/product_list_bloc.dart'
    as _i37;
import 'package:everyday_wholesale/features/splash/data/datasources/app_readiness_local_datasource.dart'
    as _i204;
import 'package:everyday_wholesale/features/splash/data/repositories/app_readiness_repository_impl.dart'
    as _i398;
import 'package:everyday_wholesale/features/splash/domain/repositories/app_readiness_repository.dart'
    as _i246;
import 'package:everyday_wholesale/features/splash/domain/usecases/check_app_ready_usecase.dart'
    as _i105;
import 'package:everyday_wholesale/features/splash/presentation/bloc/splash_bloc.dart'
    as _i86;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i1047.AccountBloc>(() => _i1047.AccountBloc());
    gh.lazySingleton<_i589.HomeMockDatasource>(
      () => _i589.HomeMockDatasourceImpl(),
    );
    gh.lazySingleton<_i585.ProductMockDatasource>(
      () => _i585.ProductMockDatasourceImpl(),
    );
    gh.lazySingleton<_i204.AppReadinessLocalDatasource>(
      () => _i204.AppReadinessLocalDatasourceImpl(),
    );
    gh.lazySingleton<_i339.HomeRepository>(
      () => _i734.HomeRepositoryImpl(gh<_i589.HomeMockDatasource>()),
    );
    gh.factory<_i353.GetCategoriesUseCase>(
      () => _i353.GetCategoriesUseCase(gh<_i339.HomeRepository>()),
    );
    gh.factory<_i674.GetPromoBannersUseCase>(
      () => _i674.GetPromoBannersUseCase(gh<_i339.HomeRepository>()),
    );
    gh.lazySingleton<_i246.AppReadinessRepository>(
      () => _i398.AppReadinessRepositoryImpl(
        gh<_i204.AppReadinessLocalDatasource>(),
      ),
    );
    gh.lazySingleton<_i411.ProductRepository>(
      () => _i137.ProductRepositoryImpl(gh<_i585.ProductMockDatasource>()),
    );
    gh.factory<_i1013.HomeBloc>(
      () => _i1013.HomeBloc(
        gh<_i353.GetCategoriesUseCase>(),
        gh<_i674.GetPromoBannersUseCase>(),
      ),
    );
    gh.factory<_i682.GetProductByIdUseCase>(
      () => _i682.GetProductByIdUseCase(gh<_i411.ProductRepository>()),
    );
    gh.factory<_i706.GetProductsByCategoryUseCase>(
      () => _i706.GetProductsByCategoryUseCase(gh<_i411.ProductRepository>()),
    );
    gh.factory<_i785.ProductDetailBloc>(
      () => _i785.ProductDetailBloc(gh<_i682.GetProductByIdUseCase>()),
    );
    gh.factory<_i105.CheckAppReadyUseCase>(
      () => _i105.CheckAppReadyUseCase(gh<_i246.AppReadinessRepository>()),
    );
    gh.factory<_i37.ProductListBloc>(
      () => _i37.ProductListBloc(gh<_i706.GetProductsByCategoryUseCase>()),
    );
    gh.factory<_i86.SplashBloc>(
      () => _i86.SplashBloc(gh<_i105.CheckAppReadyUseCase>()),
    );
    return this;
  }
}
