import 'package:intl/intl.dart';

class Currency {
  final String code;
  final String name;
  final String symbol;
  final String locale;

  Currency({required this.code, required this.name, required this.symbol, required this.locale});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

final List<Currency> appCurrencies = [
  Currency(code: 'UAH', name: 'Українська гривня', symbol: '₴', locale: 'uk_UA'),
  Currency(code: 'USD', name: 'Долар США', symbol: '\$', locale: 'en_US'),
  Currency(code: 'EUR', name: 'Євро', symbol: '€', locale: 'de_DE'),
];

extension CurrencyFormatterExtension on NumberFormat {
  static NumberFormat getFormatterForCurrency(Currency currency) {
    return NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: 2,
    );
  }
}