import 'package:equatable/equatable.dart';

import '../../../../core/localization/localized_text.dart';

class SubcategoryEntity extends Equatable {
  const SubcategoryEntity({required this.id, required this.name, this.imageUrl});

  final String id;
  final LocalizedText name;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, name, imageUrl];
}
