import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class Currency {
  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.locale,
  });

  final String code;
  final String name;
  final String symbol;
  final String locale;
}

const List<Currency> appCurrencies = [
  Currency(
    code: 'UAH',
    name: 'Українська гривня',
    symbol: '₴',
    locale: 'uk_UA',
  ),
  Currency(
    code: 'USD',
    name: 'Долар США',
    symbol: r'$',
    locale: 'en_US',
  ),
  Currency(
    code: 'EUR',
    name: 'Євро',
    symbol: '€',
    locale: 'de_DE',
  ),
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
