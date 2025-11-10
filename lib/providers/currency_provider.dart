import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wislet/models/currency_model.dart';

class CurrencyProvider with ChangeNotifier {
  CurrencyProvider() {
    _loadCurrency();
  }

  Currency _selectedCurrency = appCurrencies.first;

  Currency get selectedCurrency => _selectedCurrency;

  NumberFormat get currencyFormatter {
    return NumberFormat.currency(
      locale: _selectedCurrency.locale,
      symbol: _selectedCurrency.symbol,
      decimalDigits: 2,
    );
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString('selected_currency_code');
    if (currencyCode != null) {
      _selectedCurrency = appCurrencies.firstWhere(
        (currency) => currency.code == currencyCode,
        orElse: () => appCurrencies.first,
      );
    }
    notifyListeners();
  }

  Future<void> setCurrency(Currency newCurrency) async {
    _selectedCurrency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency_code', newCurrency.code);
    notifyListeners();
  }
}
