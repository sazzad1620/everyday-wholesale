import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/usecase/usecase.dart';
import '../../../../../core/utils/text_normalizer.dart';
import '../../../../product/domain/entities/product_entity.dart';
import '../../../../product/domain/usecases/delete_product_usecase.dart';
import '../../../../product/domain/usecases/get_all_products_usecase.dart';
import 'admin_product_list_event.dart';
import 'admin_product_list_state.dart';

@injectable
class AdminProductListBloc extends Bloc<AdminProductListEvent, AdminProductListState> {
  AdminProductListBloc(this._getAllProductsUseCase, this._deleteProductUseCase) : super(const AdminProductListState()) {
    on<AdminProductListRequested>(_onRequested);
    on<AdminProductDeleteRequested>(_onDeleteRequested);
    on<AdminProductSearchChanged>(_onSearchChanged);
  }

  final GetAllProductsUseCase _getAllProductsUseCase;
  final DeleteProductUseCase _deleteProductUseCase;

  /// Same word-wise rule customers get (see `searchRank`), applied to the
  /// list the admin already has — no extra reads. Matches either language.
  List<ProductEntity> _filter(List<ProductEntity> products, String query) =>
      filterBySearch<ProductEntity>(products, query, (product) => product.name.values);

  Future<void> _onRequested(AdminProductListRequested event, Emitter<AdminProductListState> emit) async {
    // A reload (after save/delete) keeps whatever the admin had typed.
    final query = state.query;
    emit(AdminProductListState(isLoading: true, query: query));
    final result = await _getAllProductsUseCase(const NoParams());
    result.match(
      (failure) => emit(AdminProductListState(errorMessage: failure.messageKey, query: query)),
      (products) =>
          emit(AdminProductListState(products: products, visibleProducts: _filter(products, query), query: query)),
    );
  }

  Future<void> _onDeleteRequested(AdminProductDeleteRequested event, Emitter<AdminProductListState> emit) async {
    emit(
      AdminProductListState(
        products: state.products,
        visibleProducts: state.visibleProducts,
        query: state.query,
        isDeleting: true,
      ),
    );
    final result = await _deleteProductUseCase(event.productId);
    await result.match(
      (failure) async => emit(
        AdminProductListState(
          products: state.products,
          visibleProducts: state.visibleProducts,
          query: state.query,
          errorMessage: failure.messageKey,
        ),
      ),
      (_) async => _onRequested(const AdminProductListRequested(), emit),
    );
  }

  void _onSearchChanged(AdminProductSearchChanged event, Emitter<AdminProductListState> emit) {
    emit(
      AdminProductListState(
        products: state.products,
        visibleProducts: _filter(state.products, event.query),
        query: event.query,
        errorMessage: state.errorMessage,
      ),
    );
  }
}
