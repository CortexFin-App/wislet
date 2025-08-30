import 'package:sage_wallet_reborn/models/currency_model.dart';

final List<Currency> appCurrencies = [
  // North America & Europe
  Currency(name: 'US Dollar', code: 'USD', symbol: r'$', locale: 'en_US'),
  Currency(name: 'Euro', code: 'EUR', symbol: '€', locale: 'de_DE'),
  Currency(name: 'British Pound', code: 'GBP', symbol: '£', locale: 'en_GB'),
  Currency(name: 'Swiss Franc', code: 'CHF', symbol: 'Fr', locale: 'de_CH'),
  Currency(name: 'Canadian Dollar', code: 'CAD', symbol: r'C$', locale: 'en_CA'),
  Currency(name: 'Mexican Peso', code: 'MXN', symbol: r'$', locale: 'es_MX'),
  Currency(name: 'Ukrainian Hryvnia', code: 'UAH', symbol: '₴', locale: 'uk_UA'),
  Currency(name: 'Polish Złoty', code: 'PLN', symbol: 'zł', locale: 'pl_PL'),
  Currency(name: 'Czech Koruna', code: 'CZK', symbol: 'Kč', locale: 'cs_CZ'),
  Currency(name: 'Hungarian Forint', code: 'HUF', symbol: 'Ft', locale: 'hu_HU'),
  Currency(name: 'Romanian Leu', code: 'RON', symbol: 'lei', locale: 'ro_RO'),
  Currency(name: 'Bulgarian Lev', code: 'BGN', symbol: 'лв', locale: 'bg_BG'),
  Currency(name: 'Danish Krone', code: 'DKK', symbol: 'kr', locale: 'da_DK'),
  Currency(name: 'Norwegian Krone', code: 'NOK', symbol: 'kr', locale: 'nb_NO'),
  Currency(name: 'Swedish Krona', code: 'SEK', symbol: 'kr', locale: 'sv_SE'),
  Currency(name: 'Icelandic Króna', code: 'ISK', symbol: 'kr', locale: 'is_IS'),
  Currency(name: 'Turkish Lira', code: 'TRY', symbol: '₺', locale: 'tr_TR'),

  // Asia-Pacific
  Currency(name: 'Japanese Yen', code: 'JPY', symbol: '¥', locale: 'ja_JP'),
  Currency(name: 'Chinese Yuan', code: 'CNY', symbol: '¥', locale: 'zh_CN'),
  Currency(name: 'South Korean Won', code: 'KRW', symbol: '₩', locale: 'ko_KR'),
  Currency(name: 'Indian Rupee', code: 'INR', symbol: '₹', locale: 'hi_IN'),
  Currency(name: 'Australian Dollar', code: 'AUD', symbol: r'A$', locale: 'en_AU'),
  Currency(name: 'New Zealand Dollar', code: 'NZD', symbol: r'NZ$', locale: 'en_NZ'),
  Currency(name: 'Singapore Dollar', code: 'SGD', symbol: r'S$', locale: 'en_SG'),
  Currency(name: 'Hong Kong Dollar', code: 'HKD', symbol: r'HK$', locale: 'zh_HK'),
  Currency(name: 'Taiwan Dollar', code: 'TWD', symbol: r'NT$', locale: 'zh_TW'),
  Currency(name: 'Thai Baht', code: 'THB', symbol: '฿', locale: 'th_TH'),
  Currency(name: 'Indonesian Rupiah', code: 'IDR', symbol: 'Rp', locale: 'id_ID'),
  Currency(name: 'Malaysian Ringgit', code: 'MYR', symbol: 'RM', locale: 'ms_MY'),
  Currency(name: 'Philippine Peso', code: 'PHP', symbol: '₱', locale: 'en_PH'),
  Currency(name: 'Vietnamese Đồng', code: 'VND', symbol: '₫', locale: 'vi_VN'),

  // Middle East & North Africa
  Currency(name: 'Israeli New Shekel', code: 'ILS', symbol: '₪', locale: 'he_IL'),
  Currency(name: 'UAE Dirham', code: 'AED', symbol: 'د.إ', locale: 'ar_AE'),
  Currency(name: 'Saudi Riyal', code: 'SAR', symbol: 'ر.س', locale: 'ar_SA'),
  Currency(name: 'Kuwaiti Dinar', code: 'KWD', symbol: 'د.ك', locale: 'ar_KW'),
  Currency(name: 'Qatari Riyal', code: 'QAR', symbol: 'ر.ق', locale: 'ar_QA'),
  Currency(name: 'Egyptian Pound', code: 'EGP', symbol: 'E£', locale: 'ar_EG'),
  Currency(name: 'Moroccan Dirham', code: 'MAD', symbol: 'د.م.', locale: 'fr_MA'),

  // Africa
  Currency(name: 'South African Rand', code: 'ZAR', symbol: 'R', locale: 'en_ZA'),
  Currency(name: 'Nigerian Naira', code: 'NGN', symbol: '₦', locale: 'en_NG'),
  Currency(name: 'Kenyan Shilling', code: 'KES', symbol: 'KSh', locale: 'en_KE'),
  Currency(name: 'Ghanaian Cedi', code: 'GHS', symbol: '₵', locale: 'en_GH'),

  // Latin America
  Currency(name: 'Brazilian Real', code: 'BRL', symbol: r'R$', locale: 'pt_BR'),
  Currency(name: 'Argentine Peso', code: 'ARS', symbol: r'$', locale: 'es_AR'),
  Currency(name: 'Chilean Peso', code: 'CLP', symbol: r'$', locale: 'es_CL'),
  Currency(name: 'Colombian Peso', code: 'COP', symbol: r'$', locale: 'es_CO'),
  Currency(name: 'Peruvian Sol', code: 'PEN', symbol: 'S/', locale: 'es_PE'),
  Currency(name: 'Venezuelan Bolívar', code: 'VES', symbol: 'Bs.', locale: 'es_VE'),
];
