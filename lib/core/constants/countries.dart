import 'package:easy_localization/easy_localization.dart';

/// Product origin countries — ISO 3166-1 alpha-2 codes, stored on the
/// product doc as-is and translated at display time (`country.<CODE>` in the
/// translation files). Covers every UN member state plus the Holy See and
/// Palestine, so admin is never stuck without a real option; [unknownCode]
/// is the one non-ISO entry, for when the origin genuinely isn't known.
abstract final class Countries {
  /// Not a real country — a deliberate "unknown" choice so the origin field
  /// can stay required (every product shows an Origin box on the customer
  /// page) without forcing admin to guess. Sorted first in [codes] so it's
  /// always at the top of the picker, above the alphabetical list.
  static const String unknownCode = 'UNKNOWN';

  static const List<String> codes = [
    unknownCode,
    'AF', // Afghanistan
    'AL', // Albania
    'DZ', // Algeria
    'AD', // Andorra
    'AO', // Angola
    'AG', // Antigua and Barbuda
    'AR', // Argentina
    'AM', // Armenia
    'AU', // Australia
    'AT', // Austria
    'AZ', // Azerbaijan
    'BS', // Bahamas
    'BH', // Bahrain
    'BD', // Bangladesh
    'BB', // Barbados
    'BY', // Belarus
    'BE', // Belgium
    'BZ', // Belize
    'BJ', // Benin
    'BT', // Bhutan
    'BO', // Bolivia
    'BA', // Bosnia and Herzegovina
    'BW', // Botswana
    'BR', // Brazil
    'BN', // Brunei
    'BG', // Bulgaria
    'BF', // Burkina Faso
    'BI', // Burundi
    'CV', // Cabo Verde
    'KH', // Cambodia
    'CM', // Cameroon
    'CA', // Canada
    'CF', // Central African Republic
    'TD', // Chad
    'CL', // Chile
    'CN', // China
    'CO', // Colombia
    'KM', // Comoros
    'CD', // Congo (Democratic Republic of the)
    'CG', // Congo (Republic of the)
    'CR', // Costa Rica
    'CI', // Côte d'Ivoire
    'HR', // Croatia
    'CU', // Cuba
    'CY', // Cyprus
    'CZ', // Czechia
    'DK', // Denmark
    'DJ', // Djibouti
    'DM', // Dominica
    'DO', // Dominican Republic
    'EC', // Ecuador
    'EG', // Egypt
    'SV', // El Salvador
    'GQ', // Equatorial Guinea
    'ER', // Eritrea
    'EE', // Estonia
    'SZ', // Eswatini
    'ET', // Ethiopia
    'FJ', // Fiji
    'FI', // Finland
    'FR', // France
    'GA', // Gabon
    'GM', // Gambia
    'GE', // Georgia
    'DE', // Germany
    'GH', // Ghana
    'GR', // Greece
    'GD', // Grenada
    'GT', // Guatemala
    'GN', // Guinea
    'GW', // Guinea-Bissau
    'GY', // Guyana
    'HT', // Haiti
    'VA', // Holy See
    'HN', // Honduras
    'HU', // Hungary
    'IS', // Iceland
    'IN', // India
    'ID', // Indonesia
    'IR', // Iran
    'IQ', // Iraq
    'IE', // Ireland
    'IL', // Israel
    'IT', // Italy
    'JM', // Jamaica
    'JP', // Japan
    'JO', // Jordan
    'KZ', // Kazakhstan
    'KE', // Kenya
    'KI', // Kiribati
    'KW', // Kuwait
    'KG', // Kyrgyzstan
    'LA', // Laos
    'LV', // Latvia
    'LB', // Lebanon
    'LS', // Lesotho
    'LR', // Liberia
    'LY', // Libya
    'LI', // Liechtenstein
    'LT', // Lithuania
    'LU', // Luxembourg
    'MG', // Madagascar
    'MW', // Malawi
    'MY', // Malaysia
    'MV', // Maldives
    'ML', // Mali
    'MT', // Malta
    'MH', // Marshall Islands
    'MR', // Mauritania
    'MU', // Mauritius
    'MX', // Mexico
    'FM', // Micronesia
    'MD', // Moldova
    'MC', // Monaco
    'MN', // Mongolia
    'ME', // Montenegro
    'MA', // Morocco
    'MZ', // Mozambique
    'MM', // Myanmar
    'NA', // Namibia
    'NR', // Nauru
    'NP', // Nepal
    'NL', // Netherlands
    'NZ', // New Zealand
    'NI', // Nicaragua
    'NE', // Niger
    'NG', // Nigeria
    'KP', // North Korea
    'MK', // North Macedonia
    'NO', // Norway
    'OM', // Oman
    'PK', // Pakistan
    'PW', // Palau
    'PS', // Palestine
    'PA', // Panama
    'PG', // Papua New Guinea
    'PY', // Paraguay
    'PE', // Peru
    'PH', // Philippines
    'PL', // Poland
    'PT', // Portugal
    'QA', // Qatar
    'RO', // Romania
    'RU', // Russia
    'RW', // Rwanda
    'KN', // Saint Kitts and Nevis
    'LC', // Saint Lucia
    'VC', // Saint Vincent and the Grenadines
    'WS', // Samoa
    'SM', // San Marino
    'ST', // Sao Tome and Principe
    'SA', // Saudi Arabia
    'SN', // Senegal
    'RS', // Serbia
    'SC', // Seychelles
    'SL', // Sierra Leone
    'SG', // Singapore
    'SK', // Slovakia
    'SI', // Slovenia
    'SB', // Solomon Islands
    'SO', // Somalia
    'ZA', // South Africa
    'KR', // South Korea
    'SS', // South Sudan
    'ES', // Spain
    'LK', // Sri Lanka
    'SD', // Sudan
    'SR', // Suriname
    'SE', // Sweden
    'CH', // Switzerland
    'SY', // Syria
    'TJ', // Tajikistan
    'TZ', // Tanzania
    'TH', // Thailand
    'TL', // Timor-Leste
    'TG', // Togo
    'TO', // Tonga
    'TT', // Trinidad and Tobago
    'TN', // Tunisia
    'TR', // Turkey
    'TM', // Turkmenistan
    'TV', // Tuvalu
    'UG', // Uganda
    'UA', // Ukraine
    'AE', // United Arab Emirates
    'GB', // United Kingdom
    'US', // United States
    'UY', // Uruguay
    'UZ', // Uzbekistan
    'VU', // Vanuatu
    'VE', // Venezuela
    'VN', // Vietnam
    'YE', // Yemen
    'ZM', // Zambia
    'ZW', // Zimbabwe
  ];

  static bool isKnown(String code) => codes.contains(code);

  /// Translated country name; an unknown code (e.g. an unmigrated legacy
  /// free-text origin) is shown verbatim rather than as a raw key.
  static String label(String code) =>
      isKnown(code) ? 'country.$code'.tr() : code;

  /// Accepts a stored code, or — for documents written before origins were
  /// codes — the old free-text English name ("Bangladesh" → `BD`). Unknown
  /// text is returned unchanged so nothing is silently lost.
  static String parse(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final upper = raw.trim().toUpperCase();
    if (isKnown(upper)) return upper;
    return _legacyNames[raw.trim().toLowerCase()] ?? raw.trim();
  }

  static const Map<String, String> _legacyNames = {
    'bangladesh': 'BD',
    'india': 'IN',
    'brazil': 'BR',
    'japan': 'JP',
    'thailand': 'TH',
    'vietnam': 'VN',
    'philippines': 'PH',
    'indonesia': 'ID',
    'nepal': 'NP',
    'sri lanka': 'LK',
    'pakistan': 'PK',
    'china': 'CN',
    'usa': 'US',
    'united states': 'US',
    'australia': 'AU',
  };
}
