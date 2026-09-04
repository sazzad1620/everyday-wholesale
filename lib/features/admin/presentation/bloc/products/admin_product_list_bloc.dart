import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/usecase/usecase.dart';
import '../../../../product/domain/usecases/delete_product_usecase.dart';
import '../../../../product/domain/usecases/get_all_products_usecase.dart';
import 'admin_product_list_event.dart';
import 'admin_product_list_state.dart';

@injectable
class AdminProductListBloc extends Bloc<AdminProductListEvent, AdminProductListState> {
  AdminProductListBloc(this._getAllProductsUseCase, this._deleteProductUseCase) : super(const AdminProductListState()) {
    on<AdminProductListRequested>(_onRequested);
    on<AdminProductDeleteRequested>(_onDeleteRequested);
  }

  final GetAllProductsUseCase _getAllProductsUseCase;
  final DeleteProductUseCase _deleteProductUseCase;

  Future<void> _onRequested(AdminProductListRequested event, Emitter<AdminProductListState> emit) async {
    emit(const AdminProductListState(isLoading: true));
    final result = await _getAllProductsUseCase(const NoParams());
    result.match(
      (failure) => emit(AdminProductListState(errorMessage: failure.message)),
      (products) => emit(AdminProductListState(products: products)),
    );
  }

  Future<void> _onDeleteRequested(AdminProductDeleteRequested event, Emitter<AdminProductListState> emit) async {
    emit(AdminProductListState(products: state.products, isDeleting: true));
    final result = await _deleteProductUseCase(event.productId);
    await result.match(
      (failure) async => emit(AdminProductListState(products: state.products, errorMessage: failure.message)),
      (_) async => _onRequested(const AdminProductListRequested(), emit),
    );
  }
}
