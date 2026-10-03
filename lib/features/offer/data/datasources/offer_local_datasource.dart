import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, on this device only, the newest offer the customer has already
/// seen — what the bell's "new" dot is measured against.
abstract class OfferLocalDatasource {
  Future<DateTime?> getLastSeen();

  Future<void> setLastSeen(DateTime value);
}

@LazySingleton(as: OfferLocalDatasource)
class OfferLocalDatasourceImpl implements OfferLocalDatasource {
  static const _key = 'offers_last_seen_ms';

  @override
  Future<DateTime?> getLastSeen() async {
    final millis = (await SharedPreferences.getInstance()).getInt(_key);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> setLastSeen(DateTime value) async {
    await (await SharedPreferences.getInstance()).setInt(_key, value.millisecondsSinceEpoch);
  }
}
