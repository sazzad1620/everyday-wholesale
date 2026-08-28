// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:everyday_wholesale/config/di/firebase_module.dart' as _i301;
import 'package:everyday_wholesale/features/auth/data/datasources/auth_remote_datasource.dart'
    as _i965;
import 'package:everyday_wholesale/features/auth/data/repositories/auth_repository_impl.dart'
    as _i402;
import 'package:everyday_wholesale/features/auth/domain/repositories/auth_repository.dart'
    as _i870;
import 'package:everyday_wholesale/features/auth/domain/usecases/is_phone_registered_usecase.dart'
    as _i188;
import 'package:everyday_wholesale/features/auth/domain/usecases/send_phone_otp_usecase.dart'
    as _i309;
import 'package:everyday_wholesale/features/auth/domain/usecases/sign_in_usecase.dart'
    as _i456;
import 'package:everyday_wholesale/features/auth/domain/usecases/sign_in_with_google_usecase.dart'
    as _i877;
import 'package:everyday_wholesale/features/auth/domain/usecases/sign_out_usecase.dart'
    as _i736;
import 'package:everyday_wholesale/features/auth/domain/usecases/sign_up_usecase.dart'
    as _i260;
import 'package:everyday_wholesale/features/auth/domain/usecases/verify_phone_otp_usecase.dart'
    as _i133;
import 'package:everyday_wholesale/features/auth/presentation/bloc/account_bloc.dart'
    as _i569;
import 'package:everyday_wholesale/features/cart/data/datasources/cart_local_datasource.dart'
    as _i951;
import 'package:everyday_wholesale/features/cart/data/repositories/cart_repository_impl.dart'
    as _i184;
import 'package:everyday_wholesale/features/cart/domain/repositories/cart_repository.dart'
    as _i175;
import 'package:everyday_wholesale/features/cart/domain/usecases/add_to_cart_usecase.dart'
    as _i430;
import 'package:everyday_wholesale/features/cart/domain/usecases/clear_cart_usecase.dart'
    as _i883;
import 'package:everyday_wholesale/features/cart/domain/usecases/remove_from_cart_usecase.dart'
    as _i931;
import 'package:everyday_wholesale/features/cart/domain/usecases/update_cart_quantity_usecase.dart'
    as _i900;
import 'package:everyday_wholesale/features/cart/presentation/bloc/cart_bloc.dart'
    as _i632;
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
import 'package:everyday_wholesale/features/wishlist/data/datasources/wishlist_local_datasource.dart'
    as _i51;
import 'package:everyday_wholesale/features/wishlist/data/repositories/wishlist_repository_impl.dart'
    as _i609;
import 'package:everyday_wholesale/features/wishlist/domain/repositories/wishlist_repository.dart'
    as _i93;
import 'package:everyday_wholesale/features/wishlist/domain/usecases/add_to_wishlist_usecase.dart'
    as _i305;
import 'package:everyday_wholesale/features/wishlist/domain/usecases/remove_from_wishlist_usecase.dart'
    as _i574;
import 'package:everyday_wholesale/features/wishlist/presentation/bloc/wishlist_bloc.dart'
    as _i863;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(
      () => firebaseModule.firebaseFirestore,
    );
    gh.lazySingleton<_i589.HomeMockDatasource>(
      () => _i589.HomeMockDatasourceImpl(),
    );
    gh.lazySingleton<_i585.ProductMockDatasource>(
      () => _i585.ProductMockDatasourceImpl(),
    );
    gh.lazySingleton<_i951.CartLocalDatasource>(
      () => _i951.CartLocalDatasourceImpl(),
    );
    gh.lazySingleton<_i204.AppReadinessLocalDatasource>(
      () => _i204.AppReadinessLocalDatasourceImpl(),
    );
    gh.lazySingleton<_i339.HomeRepository>(
      () => _i734.HomeRepositoryImpl(gh<_i589.HomeMockDatasource>()),
    );
    gh.lazySingleton<_i51.WishlistLocalDatasource>(
      () => _i51.WishlistLocalDatasourceImpl(),
    );
    gh.lazySingleton<_i93.WishlistRepository>(
      () => _i609.WishlistRepositoryImpl(gh<_i51.WishlistLocalDatasource>()),
    );
    gh.lazySingleton<_i965.AuthRemoteDatasource>(
      () => _i965.AuthRemoteDatasourceImpl(
        gh<_i59.FirebaseAuth>(),
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i175.CartRepository>(
      () => _i184.CartRepositoryImpl(gh<_i951.CartLocalDatasource>()),
    );
    gh.factory<_i430.AddToCartUseCase>(
      () => _i430.AddToCartUseCase(gh<_i175.CartRepository>()),
    );
    gh.factory<_i883.ClearCartUseCase>(
      () => _i883.ClearCartUseCase(gh<_i175.CartRepository>()),
    );
    gh.factory<_i931.RemoveFromCartUseCase>(
      () => _i931.RemoveFromCartUseCase(gh<_i175.CartRepository>()),
    );
    gh.factory<_i900.UpdateCartQuantityUseCase>(
      () => _i900.UpdateCartQuantityUseCase(gh<_i175.CartRepository>()),
    );
    gh.lazySingleton<_i870.AuthRepository>(
      () => _i402.AuthRepositoryImpl(gh<_i965.AuthRemoteDatasource>()),
    );
    gh.factory<_i305.AddToWishlistUseCase>(
      () => _i305.AddToWishlistUseCase(gh<_i93.WishlistRepository>()),
    );
    gh.factory<_i574.RemoveFromWishlistUseCase>(
      () => _i574.RemoveFromWishlistUseCase(gh<_i93.WishlistRepository>()),
    );
    gh.lazySingleton<_i863.WishlistBloc>(
      () => _i863.WishlistBloc(
        gh<_i305.AddToWishlistUseCase>(),
        gh<_i574.RemoveFromWishlistUseCase>(),
      ),
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
    gh.factory<_i188.IsPhoneRegisteredUseCase>(
      () => _i188.IsPhoneRegisteredUseCase(gh<_i870.AuthRepository>()),
    );
    gh.factory<_i309.SendPhoneOtpUseCase>(
      () => _i309.SendPhoneOtpUseCase(gh<_i870.AuthRepository>()),
    );
    gh.factory<_i456.SignInUseCase>(
      () => _i456.SignInUseCase(gh<_i870.AuthRepository>()),
    );
    gh.factory<_i877.SignInWithGoogleUseCase>(
      () => _i877.SignInWithGoogleUseCase(gh<_i870.AuthRepository>()),
    );
    gh.factory<_i736.SignOutUseCase>(
      () => _i736.SignOutUseCase(gh<_i870.AuthRepository>()),
    );
    gh.factory<_i260.SignUpUseCase>(
      () => _i260.SignUpUseCase(gh<_i870.AuthRepository>()),
    );
    gh.factory<_i133.VerifyPhoneOtpUseCase>(
      () => _i133.VerifyPhoneOtpUseCase(gh<_i870.AuthRepository>()),
    );
    gh.lazySingleton<_i632.CartBloc>(
      () => _i632.CartBloc(
        gh<_i430.AddToCartUseCase>(),
        gh<_i900.UpdateCartQuantityUseCase>(),
        gh<_i931.RemoveFromCartUseCase>(),
        gh<_i883.ClearCartUseCase>(),
      ),
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
    gh.lazySingleton<_i569.AccountBloc>(
      () => _i569.AccountBloc(
        gh<_i870.AuthRepository>(),
        gh<_i456.SignInUseCase>(),
        gh<_i260.SignUpUseCase>(),
        gh<_i736.SignOutUseCase>(),
        gh<_i309.SendPhoneOtpUseCase>(),
        gh<_i133.VerifyPhoneOtpUseCase>(),
        gh<_i188.IsPhoneRegisteredUseCase>(),
        gh<_i877.SignInWithGoogleUseCase>(),
      ),
    );
    return this;
  }
}

class _$FirebaseModule extends _i301.FirebaseModule {}
