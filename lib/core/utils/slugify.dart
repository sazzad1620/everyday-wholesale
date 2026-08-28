/// Turns display text into a Firestore-doc-id-safe slug (lowercase,
/// alphanumeric words joined by underscores). Used by the admin category
/// form to derive category/subcategory ids from their names, matching the
/// `snake_case` ids already used by the seeded categories.
String slugify(String input) {
  final lower = input.trim().toLowerCase();
  final underscored = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return underscored.replaceAll(RegExp(r'^_+|_+$'), '');
}
