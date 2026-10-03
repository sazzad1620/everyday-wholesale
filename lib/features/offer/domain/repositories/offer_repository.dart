import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/offer_entity.dart';

abstract class OfferRepository {
  /// Newest first. Customers pass `includeExpired: false`.
  Future<Either<Failure, List<OfferEntity>>> getOffers({required bool includeExpired});

  Future<Either<Failure, void>> createOffer(OfferEntity offer);

  Future<Either<Failure, void>> deleteOffer(String id);

  /// Whether the newest offer is newer than the last one this device has
  /// seen (drives the bell's "new" dot).
  Future<Either<Failure, bool>> hasUnseenOffers();

  /// Records the newest offer as seen. Uses the offer's own timestamp, not
  /// the device clock, so a skewed clock can't leave the dot stuck on.
  Future<Either<Failure, void>> markOffersSeen();
}
