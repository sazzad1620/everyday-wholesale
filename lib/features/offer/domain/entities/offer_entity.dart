import 'package:equatable/equatable.dart';

import '../../../../core/localization/localized_text.dart';

/// One admin-written offer/announcement. [title] and [body] are stored in
/// every supported language; the customer app resolves them against the
/// current locale. [expiresAt] is optional — an expired offer disappears
/// from the customer list but stays visible to the admin.
class OfferEntity extends Equatable {
  const OfferEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.imageUrl,
    this.expiresAt,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText body;
  final DateTime createdAt;
  final String? imageUrl;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && !expiresAt!.isAfter(DateTime.now());

  @override
  List<Object?> get props => [id, title, body, createdAt, imageUrl, expiresAt];
}
