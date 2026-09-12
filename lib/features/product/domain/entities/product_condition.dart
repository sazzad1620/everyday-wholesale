/// How a product is stored/handled — one of a fixed set the admin picks from,
/// so it's stored as a language-neutral [code] and translated at display
/// time (`product.condition.<code>` in the translation files) instead of
/// being free text the admin would have to type in both languages.
enum ProductCondition {
  fresh('fresh'),
  frozen('frozen'),
  dryPackaged('dry_packaged'),
  ambient('ambient'),
  freshlyPrepared('freshly_prepared');

  const ProductCondition(this.code);

  /// The Firestore value.
  final String code;

  String get labelKey => 'product.condition.$code';

  /// Accepts the stored [code], and — so documents written before this
  /// enum existed still load until `migrate_localized_fields.dart` has run —
  /// the old free-text English labels ("Dry / Packaged", "Frozen", ...).
  /// Anything unrecognised lands on [dryPackaged], the most neutral option.
  static ProductCondition parse(String? raw) {
    if (raw == null) return dryPackaged;
    for (final value in values) {
      if (value.code == raw) return value;
    }
    return _legacyLabels[_normalize(raw)] ?? dryPackaged;
  }

  static String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  static final Map<String, ProductCondition> _legacyLabels = {
    'fresh': fresh,
    'frozen': frozen,
    'drypackaged': dryPackaged,
    'dry': dryPackaged,
    'packaged': dryPackaged,
    'ambient': ambient,
    'freshlyprepared': freshlyPrepared,
  };
}
