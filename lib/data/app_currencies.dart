import 'package:wislet/models/currency_model.dart';

final List<Currency> appCurrencies = [
  // North America & Europe
  const Currency(name: 'US Dollar', code: 'USD', symbol: r'$', locale: 'en_US'),
  const Currency(name: 'Euro', code: 'EUR', symbol: '€', locale: 'de_DE'),
  const Currency(name: 'British Pound', code: 'GBP', symbol: '£', locale: 'en_GB'),
  const Currency(name: 'Swiss Franc', code: 'CHF', symbol: 'Fr', locale: 'de_CH'),
  const Currency(
      name: 'Canadian Dollar', code: 'CAD', symbol: r'C$', locale: 'en_CA',),
  const Currency(name: 'Mexican Peso', code: 'MXN', symbol: r'$', locale: 'es_MX'),
  const Currency(
      name: 'Ukrainian Hryvnia', code: 'UAH', symbol: '₴', locale: 'uk_UA',),
  const Currency(name: 'Polish Złoty', code: 'PLN', symbol: 'zł', locale: 'pl_PL'),
  const Currency(name: 'Czech Koruna', code: 'CZK', symbol: 'Kč', locale: 'cs_CZ'),
  const Currency(
      name: 'Hungarian Forint', code: 'HUF', symbol: 'Ft', locale: 'hu_HU',),
  const Currency(name: 'Romanian Leu', code: 'RON', symbol: 'lei', locale: 'ro_RO'),
  const Currency(name: 'Bulgarian Lev', code: 'BGN', symbol: 'лв', locale: 'bg_BG'),
  const Currency(name: 'Danish Krone', code: 'DKK', symbol: 'kr', locale: 'da_DK'),
  const Currency(name: 'Norwegian Krone', code: 'NOK', symbol: 'kr', locale: 'nb_NO'),
  const Currency(name: 'Swedish Krona', code: 'SEK', symbol: 'kr', locale: 'sv_SE'),
  const Currency(name: 'Icelandic Króna', code: 'ISK', symbol: 'kr', locale: 'is_IS'),
  const Currency(name: 'Turkish Lira', code: 'TRY', symbol: '₺', locale: 'tr_TR'),

  // Asia-Pacific
  const Currency(name: 'Japanese Yen', code: 'JPY', symbol: '¥', locale: 'ja_JP'),
  const Currency(name: 'Chinese Yuan', code: 'CNY', symbol: '¥', locale: 'zh_CN'),
  const Currency(name: 'South Korean Won', code: 'KRW', symbol: '₩', locale: 'ko_KR'),
  const Currency(name: 'Indian Rupee', code: 'INR', symbol: '₹', locale: 'hi_IN'),
  const Currency(
      name: 'Australian Dollar', code: 'AUD', symbol: r'A$', locale: 'en_AU',),
  const Currency(
      name: 'New Zealand Dollar', code: 'NZD', symbol: r'NZ$', locale: 'en_NZ',),
  const Currency(
      name: 'Singapore Dollar', code: 'SGD', symbol: r'S$', locale: 'en_SG',),
  const Currency(
      name: 'Hong Kong Dollar', code: 'HKD', symbol: r'HK$', locale: 'zh_HK',),
  const Currency(name: 'Taiwan Dollar', code: 'TWD', symbol: r'NT$', locale: 'zh_TW'),
  const Currency(name: 'Thai Baht', code: 'THB', symbol: '฿', locale: 'th_TH'),
  const Currency(
      name: 'Indonesian Rupiah', code: 'IDR', symbol: 'Rp', locale: 'id_ID',),
  const Currency(
      name: 'Malaysian Ringgit', code: 'MYR', symbol: 'RM', locale: 'ms_MY',),
  const Currency(name: 'Philippine Peso', code: 'PHP', symbol: '₱', locale: 'en_PH'),
  const Currency(name: 'Vietnamese Đồng', code: 'VND', symbol: '₫', locale: 'vi_VN'),

  // Middle East & North Africa
  const Currency(
      name: 'Israeli New Shekel', code: 'ILS', symbol: '₪', locale: 'he_IL',),
  const Currency(name: 'UAE Dirham', code: 'AED', symbol: 'د.إ', locale: 'ar_AE'),
  const Currency(name: 'Saudi Riyal', code: 'SAR', symbol: 'ر.س', locale: 'ar_SA'),
  const Currency(name: 'Kuwaiti Dinar', code: 'KWD', symbol: 'د.ك', locale: 'ar_KW'),
  const Currency(name: 'Qatari Riyal', code: 'QAR', symbol: 'ر.ق', locale: 'ar_QA'),
  const Currency(name: 'Egyptian Pound', code: 'EGP', symbol: 'E£', locale: 'ar_EG'),
  const Currency(
      name: 'Moroccan Dirham', code: 'MAD', symbol: 'د.م.', locale: 'fr_MA',),

  // Africa
  const Currency(
      name: 'South African Rand', code: 'ZAR', symbol: 'R', locale: 'en_ZA',),
  const Currency(name: 'Nigerian Naira', code: 'NGN', symbol: '₦', locale: 'en_NG'),
  const Currency(
      name: 'Kenyan Shilling', code: 'KES', symbol: 'KSh', locale: 'en_KE',),
  const Currency(name: 'Ghanaian Cedi', code: 'GHS', symbol: '₵', locale: 'en_GH'),

  // Latin America
  const Currency(name: 'Brazilian Real', code: 'BRL', symbol: r'R$', locale: 'pt_BR'),
  const Currency(name: 'Argentine Peso', code: 'ARS', symbol: r'$', locale: 'es_AR'),
  const Currency(name: 'Chilean Peso', code: 'CLP', symbol: r'$', locale: 'es_CL'),
  const Currency(name: 'Colombian Peso', code: 'COP', symbol: r'$', locale: 'es_CO'),
  const Currency(name: 'Peruvian Sol', code: 'PEN', symbol: 'S/', locale: 'es_PE'),
  const Currency(
      name: 'Venezuelan Bolívar', code: 'VES', symbol: 'Bs.', locale: 'es_VE',),
];
