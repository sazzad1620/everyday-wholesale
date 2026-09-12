import '../../../../core/localization/localized_text.dart';
import '../../domain/entities/subcategory_entity.dart';

class SubcategoryModel extends SubcategoryEntity {
  const SubcategoryModel({required super.id, required super.name, super.imageUrl});

  factory SubcategoryModel.fromMap(Map<String, dynamic> map) {
    return SubcategoryModel(
      id: map['id'] as String? ?? '',
      name: LocalizedText.fromFirestore(map['name']),
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name.toMap(), 'imageUrl': imageUrl};
}
