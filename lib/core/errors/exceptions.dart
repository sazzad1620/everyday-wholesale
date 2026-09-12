/// Data-layer exceptions. Like `Failure`, each carries a **translation key**
/// rather than display text — repositories forward it into the matching
/// `Failure` unchanged, and the UI resolves it with `.tr()`.
class ServerException implements Exception {
  const ServerException([this.messageKey = 'errors.server']);

  final String messageKey;
}

class CacheException implements Exception {
  const CacheException([this.messageKey = 'errors.cache']);

  final String messageKey;
}

class AuthException implements Exception {
  const AuthException([this.messageKey = 'errors.auth']);

  final String messageKey;
}
