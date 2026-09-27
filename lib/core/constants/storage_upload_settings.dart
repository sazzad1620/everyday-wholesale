/// Shared settings for every image the app uploads to Firebase Storage.
abstract final class StorageUploadSettings {
  /// Without an explicit `Cache-Control`, Storage serves downloads as
  /// `private, max-age=0` — browsers re-download every image on every visit.
  /// Uploaded files are never modified in place (each upload gets a new,
  /// timestamped name, and replacing a photo writes a new file), so they
  /// can safely be cached for a year and marked immutable.
  static const String cacheControl = 'public, max-age=31536000, immutable';

  /// Longest side of a product photo as shown on the product page.
  static const int productFullSize = 1200;

  /// Longest side of the copy used for cards, lists and category tiles
  /// (~2x their largest on-screen size, for sharp high-DPI screens).
  static const int thumbnailSize = 600;

  /// Longest side of a home banner — shown up to ~950pt wide on a large
  /// desktop and ~375pt on phones, so 1600px covers both at high-DPI.
  static const int bannerSize = 1600;
}
