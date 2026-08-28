import '../../domain/entities/category_entity.dart';
import 'subcategory_model.dart';

/// Mirrors a `categories/{categoryId}` Firestore document. `id` is the
/// document ID, not a stored field.
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.iconKey,
    super.imageUrl,
    super.subcategories,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, {required String id}) {
    final rawSubcategories = map['subcategories'] as List<dynamic>? ?? const [];
    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      iconKey: map['iconKey'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      subcategories: rawSubcategories
          .map((raw) => SubcategoryModel.fromMap(Map<String, dynamic>.from(raw as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'iconKey': iconKey,
    'imageUrl': imageUrl,
    'subcategories': subcategories.map((s) => SubcategoryModel(id: s.id, name: s.name).toMap()).toList(),
  };
}
