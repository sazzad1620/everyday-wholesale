import 'package:equatable/equatable.dart';

class PromoBannerEntity extends Equatable {
  const PromoBannerEntity({
    required this.id,
    required this.imagePath,
  });

  final String id;
  final String imagePath;

  @override
  List<Object?> get props => [id, imagePath];
}
