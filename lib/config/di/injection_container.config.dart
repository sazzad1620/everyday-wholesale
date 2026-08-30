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
import 'package:everyday_wholesale/features/admin/data/datasources/admin_category_remote_datasource.dart'
    as _i980;
import 'package:everyday_wholesale/features/admin/data/datasources/admin_dashboard_remote_datasource.dart'
    as _i660;
import 'package:everyday_wholesale/features/admin/data/datasources/admin_order_remote_datasource.dart'
    as _i714;
import 'package:everyday_wholesale/features/admin/data/datasources/admin_product_remote_datasource.dart'
    as _i1029;
import 'package:everyday_wholesale/features/admin/data/repositories/admin_category_repository_impl.dart'
    as _i755;
import 'package:everyday_wholesale/features/admin/data/repositories/admin_dashboard_repository_impl.dart'
    as _i702;
import 'package:everyday_wholesale/features/admin/data/repositories/admin_order_repository_impl.dart'
    as _i99;
import 'package:everyday_wholesale/features/admin/data/repositories/admin_product_repository_impl.dart'
    as _i402;
import 'package:everyday_wholesale/features/admin/domain/repositories/admin_category_repository.dart'
    as _i271;
import 'package:everyday_wholesale/features/admin/domain/repositories/admin_dashboard_repository.dart'
    as _i444;
import 'package:everyday_wholesale/features/admin/domain/repositories/admin_order_repository.dart'
    as _i147;
import 'package:everyday_wholesale/features/admin/domain/repositories/admin_product_repository.dart'
    as _i205;
import 'package:everyday_wholesale/features/admin/domain/usecases/create_category_usecase.dart'
    as _i695;
import 'package:everyday_wholesale/features/admin/domain/usecases/create_product_usecase.dart'
    as _i291;
import 'package:everyday_wholesale/features/admin/domain/usecases/delete_category_usecase.dart'
    as _i891;
import 'package:everyday_wholesale/features/admin/domain/usecases/delete_product_usecase.dart'
    as _i634;
import 'package:everyday_wholesale/features/admin/domain/usecases/get_all_orders_usecase.dart'
    as _i724;
import 'package:everyday_wholesale/features/admin/domain/usecases/get_all_products_usecase.dart'
    as _i598;
import 'package:everyday_wholesale/features/admin/domain/usecases/get_dashboard_stats_usecase.dart'
    as _i1031;
import 'package:everyday_wholesale/features/admin/domain/usecases/update_category_usecase.dart'
    as _i412;
import 'package:everyday_wholesale/features/admin/domain/usecases/update_order_status_usecase.dart'
    as _i514;
import 'package:everyday_wholesale/features/admin/domain/usecases/update_product_usecase.dart'
    as _i955;
import 'package:everyday_wholesale/features/admin/domain/usecases/upload_product_image_usecase.dart'
    as _i38;
import 'package:everyday_wholesale/features/admin/presentation/bloc/admin_order_detail_bloc.dart'
    as _i498;
import 'package:everyday_wholesale/features/admin/presentation/bloc/admin_order_list_bloc.dart'
    as _i482;
import 'package:everyday_wholesale/features/admin/presentation/bloc/admin_product_form_bloc.dart'
    as _i676;
import 'package:everyday_wholesale/features/admin/presentation/bloc/admin_product_list_bloc.dart'
    as _i568;
import 'package:everyday_wholesale/features/admin/presentation/bloc/category_form_bloc.dart'
    as _i363;
import 'package:everyday_wholesale/features/admin/presentation/bloc/category_list_bloc.dart'
    as _i75;
import 'package:everyday_wholesale/features/admin/presentation/bloc/dashboard_bloc.dart'
    as _i297;
import 'package:everyday_wholesale/features/auth/data/datasources/auth_remote_datasource.dart'
    as _i965;
import 'package:everyday_wholesale/features/auth/data/repositories/auth_repository_impl.dart'
    as _i403;
import 'package:everyday_wholesale/features/auth/domain/repositories/auth_repository.dart'
    as _i870;
import 'package:everyday_wholesale/features/auth/domain/usecases/is_phone_registered_usecase.dart'
    as _i188;
import 'package:everyday_wholesale/features/auth/domain/usecases/send_password_reset_email_usecase.dart'
    as _i577;
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
import 'package:everyday_wholesale/features/auth/domain/usecases/update_address_usecase.dart'
    as _i379;
import 'package:everyday_wholesale/features/auth/domain/usecases/update_name_usecase.dart'
    as _i171;
import 'package:everyday_wholesale/features/auth/domain/usecases/verify_phone_otp_usecase.dart'
    as _i133;
import 'package:everyday_wholesale/features/auth/presentation/bloc/account_bloc.dart'
    as _i569;
import 'package:everyday_wholesale/features/cart/data/datasources/cart_remote_datasource.dart'
    as _i490;
import 'package:everyday_wholesale/features/cart/data/repositories/cart_repository_impl.dart'
    as _i184;
import 'package:everyday_wholesale/features/cart/domain/repositories/cart_repository.dart'
    as _i175;
import 'package:everyday_wholesale/features/cart/domain/usecases/add_to_cart_usecase.dart'
    as _i430;
import 'package:everyday_wholesale/features/cart/domain/usecases/clear_cart_usecase.dart'
    as _i883;
import 'package:everyday_wholesale/features/cart/domain/usecases/get_cart_usecase.dart'
    as _i30;
import 'package:everyday_wholesale/features/cart/domain/usecases/remove_from_cart_usecase.dart'
    as _i931;
import 'package:everyday_wholesale/features/cart/domain/usecases/update_cart_quantity_usecase.dart'
    as _i900;
import 'package:everyday_wholesale/features/cart/presentation/bloc/cart_bloc.dart'
    as _i632;
import 'package:everyday_wholesale/features/checkout/presentation/bloc/checkout_bloc.dart'
    as _i441;
import 'package:everyday_wholesale/features/home/data/datasources/home_local_datasource.dart'
    as _i940;
import 'package:everyday_wholesale/features/home/data/datasources/home_remote_datasource.dart'
    as _i1056;
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
import 'package:everyday_wholesale/features/order/data/datasources/order_remote_datasource.dart'
    as _i62;
import 'package:everyday_wholesale/features/order/data/repositories/order_repository_impl.dart'
    as _i506;
import 'package:everyday_wholesale/features/order/domain/repositories/order_repository.dart'
    as _i193;
import 'package:everyday_wholesale/features/order/domain/usecases/get_order_history_usecase.dart'
    as _i191;
import 'package:everyday_wholesale/features/order/domain/usecases/place_order_usecase.dart'
    as _i504;
import 'package:everyday_wholesale/features/order/presentation/bloc/order_history_bloc.dart'
    as _i419;
import 'package:everyday_wholesale/features/product/data/datasources/product_remote_datasource.dart'
    as _i581;
import 'package:everyday_wholesale/features/product/data/repositories/product_repository_impl.dart'
    as _i137;
import 'package:everyday_wholesale/features/product/domain/repositories/product_repository.dart'
    as _i411;
import 'package:everyday_wholesale/features/product/domain/usecases/get_product_by_id_usecase.dart'
    as _i682;
import 'package:everyday_wholesale/features/product/domain/usecases/get_products_by_category_usecase.dart'
    as _i706;
import 'package:everyday_wholesale/features/product/domain/usecases/search_products_usecase.dart'
    as _i58;
import 'package:everyday_wholesale/features/product/presentation/bloc/product_detail_bloc.dart'
    as _i785;
import 'package:everyday_wholesale/features/product/presentation/bloc/product_list_bloc.dart'
    as _i37;
import 'package:everyday_wholesale/features/product/presentation/bloc/search_bloc.dart'
    as _i380;
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
import 'package:firebase_storage/firebase_storage.dart' as _i457;
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
    gh.lazySingleton<_i457.FirebaseStorage>(
      () => firebaseModule.firebaseStorage,
    );
    gh.lazySingleton<_i204.AppReadinessLocalDatasource>(
      () => _i204.AppReadinessLocalDatasourceImpl(),
    );
    gh.lazySingleton<_i940.HomeLocalDatasource>(
      () => _i940.HomeLocalDatasourceImpl(),
    );
    gh.lazySingleton<_i1029.AdminProductRemoteDatasource>(
      () => _i1029.AdminProductRemoteDatasourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i457.FirebaseStorage>(),
      ),
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
    gh.lazySingleton<_i205.AdminProductRepository>(
      () => _i402.AdminProductRepositoryImpl(
        gh<_i1029.AdminProductRemoteDatasource>(),
      ),
    );
    gh.lazySingleton<_i870.AuthRepository>(
      () => _i403.AuthRepositoryImpl(gh<_i965.AuthRemoteDatasource>()),
    );
    gh.lazySingleton<_i581.ProductRemoteDatasource>(
      () => _i581.ProductRemoteDatasourceImpl(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i660.AdminDashboardRemoteDatasource>(
      () => _i660.AdminDashboardRemoteDatasourceImpl(
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i1056.HomeRemoteDatasource>(
      () => _i1056.HomeRemoteDatasourceImpl(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i339.HomeRepository>(
      () => _i734.HomeRepositoryImpl(
        gh<_i1056.HomeRemoteDatasource>(),
        gh<_i940.HomeLocalDatasource>(),
      ),
    );
    gh.lazySingleton<_i980.AdminCategoryRemoteDatasource>(
      () => _i980.AdminCategoryRemoteDatasourceImpl(
        gh<_i974.FirebaseFirestore>(),
      ),
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
    gh.lazySingleton<_i490.CartRemoteDatasource>(
      () => _i490.CartRemoteDatasourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
        gh<_i581.ProductRemoteDatasource>(),
      ),
    );
    gh.lazySingleton<_i714.AdminOrderRemoteDatasource>(
      () => _i714.AdminOrderRemoteDatasourceImpl(gh<_i974.FirebaseFirestore>()),
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
    gh.lazySingleton<_i62.OrderRemoteDatasource>(
      () => _i62.OrderRemoteDatasourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i444.AdminDashboardRepository>(
      () => _i702.AdminDashboardRepositoryImpl(
        gh<_i660.AdminDashboardRemoteDatasource>(),
      ),
    );
    gh.factory<_i1013.HomeBloc>(
      () => _i1013.HomeBloc(
        gh<_i353.GetCategoriesUseCase>(),
        gh<_i674.GetPromoBannersUseCase>(),
      ),
    );
    gh.lazySingleton<_i193.OrderRepository>(
      () => _i506.OrderRepositoryImpl(
        gh<_i62.OrderRemoteDatasource>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i291.CreateProductUseCase>(
      () => _i291.CreateProductUseCase(gh<_i205.AdminProductRepository>()),
    );
    gh.factory<_i634.DeleteProductUseCase>(
      () => _i634.DeleteProductUseCase(gh<_i205.AdminProductRepository>()),
    );
    gh.factory<_i598.GetAllProductsUseCase>(
      () => _i598.GetAllProductsUseCase(gh<_i205.AdminProductRepository>()),
    );
    gh.factory<_i955.UpdateProductUseCase>(
      () => _i955.UpdateProductUseCase(gh<_i205.AdminProductRepository>()),
    );
    gh.factory<_i38.UploadProductImageUseCase>(
      () => _i38.UploadProductImageUseCase(gh<_i205.AdminProductRepository>()),
    );
    gh.factory<_i188.IsPhoneRegisteredUseCase>(
      () => _i188.IsPhoneRegisteredUseCase(gh<_i870.AuthRepository>()),
    );
    gh.factory<_i577.SendPasswordResetEmailUseCase>(
      () => _i577.SendPasswordResetEmailUseCase(gh<_i870.AuthRepository>()),
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
    gh.factory<_i379.UpdateAddressUseCase>(
      () => _i379.UpdateAddressUseCase(gh<_i870.AuthRepository>()),
    );
    gh.factory<_i171.UpdateNameUseCase>(
      () => _i171.UpdateNameUseCase(gh<_i870.AuthRepository>()),
    );
    gh.factory<_i133.VerifyPhoneOtpUseCase>(
      () => _i133.VerifyPhoneOtpUseCase(gh<_i870.AuthRepository>()),
    );
    gh.factory<_i191.GetOrderHistoryUseCase>(
      () => _i191.GetOrderHistoryUseCase(gh<_i193.OrderRepository>()),
    );
    gh.factory<_i504.PlaceOrderUseCase>(
      () => _i504.PlaceOrderUseCase(gh<_i193.OrderRepository>()),
    );
    gh.factory<_i105.CheckAppReadyUseCase>(
      () => _i105.CheckAppReadyUseCase(gh<_i246.AppReadinessRepository>()),
    );
    gh.lazySingleton<_i411.ProductRepository>(
      () => _i137.ProductRepositoryImpl(gh<_i581.ProductRemoteDatasource>()),
    );
    gh.lazySingleton<_i271.AdminCategoryRepository>(
      () => _i755.AdminCategoryRepositoryImpl(
        gh<_i980.AdminCategoryRemoteDatasource>(),
      ),
    );
    gh.lazySingleton<_i175.CartRepository>(
      () => _i184.CartRepositoryImpl(gh<_i490.CartRemoteDatasource>()),
    );
    gh.lazySingleton<_i147.AdminOrderRepository>(
      () =>
          _i99.AdminOrderRepositoryImpl(gh<_i714.AdminOrderRemoteDatasource>()),
    );
    gh.factory<_i724.GetAllOrdersUseCase>(
      () => _i724.GetAllOrdersUseCase(gh<_i147.AdminOrderRepository>()),
    );
    gh.factory<_i514.UpdateOrderStatusUseCase>(
      () => _i514.UpdateOrderStatusUseCase(gh<_i147.AdminOrderRepository>()),
    );
    gh.factory<_i676.AdminProductFormBloc>(
      () => _i676.AdminProductFormBloc(
        gh<_i291.CreateProductUseCase>(),
        gh<_i955.UpdateProductUseCase>(),
      ),
    );
    gh.factory<_i1031.GetDashboardStatsUseCase>(
      () =>
          _i1031.GetDashboardStatsUseCase(gh<_i444.AdminDashboardRepository>()),
    );
    gh.factory<_i498.AdminOrderDetailBloc>(
      () => _i498.AdminOrderDetailBloc(gh<_i514.UpdateOrderStatusUseCase>()),
    );
    gh.factory<_i568.AdminProductListBloc>(
      () => _i568.AdminProductListBloc(
        gh<_i598.GetAllProductsUseCase>(),
        gh<_i634.DeleteProductUseCase>(),
      ),
    );
    gh.factory<_i297.DashboardBloc>(
      () => _i297.DashboardBloc(gh<_i1031.GetDashboardStatsUseCase>()),
    );
    gh.factory<_i419.OrderHistoryBloc>(
      () => _i419.OrderHistoryBloc(gh<_i191.GetOrderHistoryUseCase>()),
    );
    gh.factory<_i682.GetProductByIdUseCase>(
      () => _i682.GetProductByIdUseCase(gh<_i411.ProductRepository>()),
    );
    gh.factory<_i706.GetProductsByCategoryUseCase>(
      () => _i706.GetProductsByCategoryUseCase(gh<_i411.ProductRepository>()),
    );
    gh.factory<_i58.SearchProductsUseCase>(
      () => _i58.SearchProductsUseCase(gh<_i411.ProductRepository>()),
    );
    gh.factory<_i86.SplashBloc>(
      () => _i86.SplashBloc(gh<_i105.CheckAppReadyUseCase>()),
    );
    gh.factory<_i785.ProductDetailBloc>(
      () => _i785.ProductDetailBloc(gh<_i682.GetProductByIdUseCase>()),
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
        gh<_i577.SendPasswordResetEmailUseCase>(),
        gh<_i379.UpdateAddressUseCase>(),
        gh<_i171.UpdateNameUseCase>(),
      ),
    );
    gh.factory<_i482.AdminOrderListBloc>(
      () => _i482.AdminOrderListBloc(
        gh<_i724.GetAllOrdersUseCase>(),
        gh<_i514.UpdateOrderStatusUseCase>(),
      ),
    );
    gh.factory<_i695.CreateCategoryUseCase>(
      () => _i695.CreateCategoryUseCase(gh<_i271.AdminCategoryRepository>()),
    );
    gh.factory<_i891.DeleteCategoryUseCase>(
      () => _i891.DeleteCategoryUseCase(gh<_i271.AdminCategoryRepository>()),
    );
    gh.factory<_i412.UpdateCategoryUseCase>(
      () => _i412.UpdateCategoryUseCase(gh<_i271.AdminCategoryRepository>()),
    );
    gh.factory<_i430.AddToCartUseCase>(
      () => _i430.AddToCartUseCase(gh<_i175.CartRepository>()),
    );
    gh.factory<_i883.ClearCartUseCase>(
      () => _i883.ClearCartUseCase(gh<_i175.CartRepository>()),
    );
    gh.factory<_i30.GetCartUseCase>(
      () => _i30.GetCartUseCase(gh<_i175.CartRepository>()),
    );
    gh.factory<_i931.RemoveFromCartUseCase>(
      () => _i931.RemoveFromCartUseCase(gh<_i175.CartRepository>()),
    );
    gh.factory<_i900.UpdateCartQuantityUseCase>(
      () => _i900.UpdateCartQuantityUseCase(gh<_i175.CartRepository>()),
    );
    gh.factory<_i380.SearchBloc>(
      () => _i380.SearchBloc(gh<_i58.SearchProductsUseCase>()),
    );
    gh.factory<_i75.CategoryListBloc>(
      () => _i75.CategoryListBloc(
        gh<_i353.GetCategoriesUseCase>(),
        gh<_i891.DeleteCategoryUseCase>(),
      ),
    );
    gh.factory<_i363.CategoryFormBloc>(
      () => _i363.CategoryFormBloc(
        gh<_i695.CreateCategoryUseCase>(),
        gh<_i412.UpdateCategoryUseCase>(),
      ),
    );
    gh.factory<_i37.ProductListBloc>(
      () => _i37.ProductListBloc(gh<_i706.GetProductsByCategoryUseCase>()),
    );
    gh.lazySingleton<_i632.CartBloc>(
      () => _i632.CartBloc(
        gh<_i870.AuthRepository>(),
        gh<_i30.GetCartUseCase>(),
        gh<_i430.AddToCartUseCase>(),
        gh<_i900.UpdateCartQuantityUseCase>(),
        gh<_i931.RemoveFromCartUseCase>(),
        gh<_i883.ClearCartUseCase>(),
      ),
    );
    gh.factory<_i441.CheckoutBloc>(
      () => _i441.CheckoutBloc(
        gh<_i504.PlaceOrderUseCase>(),
        gh<_i632.CartBloc>(),
      ),
    );
    return this;
  }
}

class _$FirebaseModule extends _i301.FirebaseModule {}
