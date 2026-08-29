import 'package:equatable/equatable.dart';

import '../../domain/entities/product_entity.dart';

/// Single-class, flag-based state (matching [ProductListState]'s siblings
/// like `CategoryListState`) — `query` is kept alongside `results` so the
/// page can tell "no query yet" (empty query, show the search prompt) apart
/// from "searched and found nothing" (non-empty query, empty results).
class SearchState extends Equatable {
  const SearchState({this.query = '', this.isLoading = false, this.results = const [], this.errorMessage});

  final String query;
  final bool isLoading;
  final List<ProductEntity> results;
  final String? errorMessage;

  @override
  List<Object?> get props => [query, isLoading, results, errorMessage];
}
