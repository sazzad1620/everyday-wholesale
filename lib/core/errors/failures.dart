/// Every failure carries a **translation key** (`errors.*` in
/// `assets/translations/*.json`), never display text — the data layer has no
/// locale, so the presentation layer resolves it with `.tr()` at the moment
/// it's shown. Keeping the key (not the resolved string) in bloc state also
/// means an error that's still on screen re-renders correctly after a
/// language switch.
abstract class Failure {
  const Failure(this.messageKey);

  final String messageKey;
}

class ServerFailure extends Failure {
  const ServerFailure([super.messageKey = 'errors.server']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.messageKey = 'errors.cache']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.messageKey = 'errors.unexpected']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.messageKey = 'errors.not_found']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.messageKey = 'errors.auth']);
}
