import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../product/domain/entities/product_entity.dart';

/// Write-side (+ unscoped list-read) counterpart to [ProductRepository],
/// which only ever reads scoped by category — the admin list needs every
/// product regardless of category, and only the admin side ever mutates one.
abstract class AdminProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getAllProducts();

  Future<Either<Failure, void>> createProduct(ProductEntity product);

  Future<Either<Failure, void>> updateProduct(ProductEntity product);

  Future<Either<Failure, void>> deleteProduct(String productId);

  /// Uploads a picked photo to Firebase Storage and returns its public
  /// download URL — the caller is responsible for saving that URL onto the
  /// product afterwards (via [createProduct]/[updateProduct]), same
  /// two-step flow `BACKEND_SETUP.md` Part B4 describes.
  Future<Either<Failure, String>> uploadProductImage(Uint8List bytes, String fileExtension);
}
