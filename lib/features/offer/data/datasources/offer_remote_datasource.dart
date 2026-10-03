import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

import '../models/offer_model.dart';

abstract class OfferRemoteDatasource {
  Future<List<OfferModel>> getOffers({required bool includeExpired});

  Future<void> createOffer(OfferModel offer);

  Future<void> deleteOffer(String id);

  /// `createdAt` of the newest offer, or `null` when there are none.
  Future<DateTime?> getLatestOfferTime();
}

@LazySingleton(as: OfferRemoteDatasource)
class OfferRemoteDatasourceImpl implements OfferRemoteDatasource {
  OfferRemoteDatasourceImpl(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const _collection = 'offers';

  /// Cap on what one visit loads — an offers feed older than this isn't
  /// useful, and it keeps the read cost flat as the list grows.
  static const _limit = 50;

  @override
  Future<List<OfferModel>> getOffers({required bool includeExpired}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .get();
    final offers = snapshot.docs.map((doc) => OfferModel.fromMap(doc.data(), id: doc.id)).toList();
    return includeExpired ? offers : offers.where((offer) => !offer.isExpired).toList();
  }

  /// Goes through the admin-only `sendOffer` Cloud Function, which both
  /// saves the offer and pushes it to every customer — clients can no longer
  /// write `offers/` directly (see `firestore.rules`).
  @override
  Future<void> createOffer(OfferModel offer) async {
    await _functions.httpsCallable('sendOffer').call<Map<String, dynamic>>({
      'title': offer.title.toMap(),
      'body': offer.body.toMap(),
      if (offer.imageUrl != null) 'imageUrl': offer.imageUrl,
      if (offer.expiresAt != null) 'expiresAtMillis': offer.expiresAt!.millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> deleteOffer(String id) => _firestore.collection(_collection).doc(id).delete();

  @override
  Future<DateTime?> getLatestOfferTime() async {
    final snapshot = await _firestore.collection(_collection).orderBy('createdAt', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return OfferModel.fromMap(snapshot.docs.first.data(), id: snapshot.docs.first.id).createdAt;
  }
}
