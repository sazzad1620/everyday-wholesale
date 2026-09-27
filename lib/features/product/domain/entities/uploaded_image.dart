import 'package:equatable/equatable.dart';

/// Result of uploading one admin-picked photo: the full-size copy (product
/// page) and a smaller [thumbnailUrl] copy (cards, lists, category tiles).
class UploadedImage extends Equatable {
  const UploadedImage({required this.url, required this.thumbnailUrl});

  final String url;
  final String thumbnailUrl;

  @override
  List<Object?> get props => [url, thumbnailUrl];
}
