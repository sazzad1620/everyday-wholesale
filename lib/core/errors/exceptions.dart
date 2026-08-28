class ServerException implements Exception {
  const ServerException([this.message = 'Something went wrong on the server.']);

  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Something went wrong reading local data.']);

  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Something went wrong with authentication.']);

  final String message;
}
