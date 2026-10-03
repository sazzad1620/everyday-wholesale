import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/localization/localized_text.dart';
import '../../domain/entities/offer_entity.dart';

/// Mirrors an `offers/{offerId}` Firestore document. `id` is the document
/// ID, not a stored field.
class OfferModel extends OfferEntity {
  const OfferModel({
    required super.id,
    required super.title,
    required super.body,
    required super.createdAt,
    super.imageUrl,
    super.expiresAt,
  });

  factory OfferModel.fromMap(Map<String, dynamic> map, {required String id}) => OfferModel(
    id: id,
    title: LocalizedText.fromFirestore(map['title']),
    body: LocalizedText.fromFirestore(map['body']),
    // Null only for the instant between a local write and the server
    // timestamp resolving — treated as "just now".
    createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    imageUrl: map['imageUrl'] as String?,
    expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
  );

  factory OfferModel.fromEntity(OfferEntity offer) => OfferModel(
    id: offer.id,
    title: offer.title,
    body: offer.body,
    createdAt: offer.createdAt,
    imageUrl: offer.imageUrl,
    expiresAt: offer.expiresAt,
  );

}
