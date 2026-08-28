import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import 'admin_product_form_event.dart';
import 'admin_product_form_state.dart';

/// One per form visit (`@injectable`, not shared) — mirrors [CategoryFormBloc].
@injectable
class AdminProductFormBloc extends Bloc<AdminProductFormEvent, AdminProductFormState> {
  AdminProductFormBloc(this._createProductUseCase, this._updateProductUseCase) : super(const AdminProductFormState()) {
    on<AdminProductFormSubmitted>(_onSubmitted);
  }

  final CreateProductUseCase _createProductUseCase;
  final UpdateProductUseCase _updateProductUseCase;

  Future<void> _onSubmitted(AdminProductFormSubmitted event, Emitter<AdminProductFormState> emit) async {
    emit(const AdminProductFormState(isSubmitting: true));
    final result = event.isEditing
        ? await _updateProductUseCase(event.product)
        : await _createProductUseCase(event.product);
    result.match(
      (failure) => emit(AdminProductFormState(errorMessage: failure.message)),
      (_) => emit(const AdminProductFormState(success: true)),
    );
  }
}
