import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/di/injector.dart';
import '../../models/currency_model.dart';
import '../../services/exchange_rate_service.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();
  final TextEditingController _amountController = TextEditingController(text: '100');
  Currency? _fromCurrency;
  Currency? _toCurrency;
  DateTime _selectedRateDate = DateTime.now();
  String _convertedAmountStr = "";
  bool _isLoading = false;
  String? _errorMessage;
  String? _rateInfoMessage;
  final List<Currency> _availableCurrencies = appCurrencies;

  @override
  void initState() {
    super.initState();
    if (_availableCurrencies.isNotEmpty) {
      _fromCurrency = _availableCurrencies.firstWhere((c) => c.code == "USD", orElse: () => _availableCurrencies.first);
      _toCurrency = _availableCurrencies.firstWhere((c) => c.code == "UAH", orElse: () => _availableCurrencies.length > 1 ? _availableCurrencies[1] : _availableCurrencies.first);
    }
    _amountController.addListener(_triggerConversion);
    _triggerConversion();
  }

  Future<void> _pickRateDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedRateDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedRateDate) {
      if (mounted) {
        setState(() {
          _selectedRateDate = pickedDate;
        });
      }
      _triggerConversion();
    }
  }

  void _triggerConversion() {
    final String amountText = _amountController.text.replaceAll(',', '.');
    final double? amount = double.tryParse(amountText);
    if (amount != null && amount > 0 && _fromCurrency != null && _toCurrency != null) {
      _convertCurrency(amount);
    } else {
      if (mounted) {
        setState(() {
          _convertedAmountStr = "";
          _errorMessage = null;
          _rateInfoMessage = null;
        });
      }
    }
  }

  Future<void> _convertCurrency(double amount) async {
    if (_fromCurrency == null || _toCurrency == null) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _rateInfoMessage = null;
    });

    try {
      final ConversionRateInfo rateInfo = await _exchangeRateService.getConversionRate(
        _fromCurrency!.code,
        _toCurrency!.code,
        date: _selectedRateDate,
      );
      final double convertedValue = amount * rateInfo.rate;
      
      final targetCurrencyFormat = NumberFormat.currency(
        locale: _toCurrency!.locale, 
        symbol: _toCurrency!.symbol,
        decimalDigits: 2
      );
      String rateDateInfo = "(курс від ${DateFormat('dd.MM.yy').format(rateInfo.effectiveRateDate)})";

      if (mounted) {
        setState(() {
          _convertedAmountStr = targetCurrencyFormat.format(convertedValue);
          _rateInfoMessage = rateInfo.isRateStale ? "Використано кешований курс $rateDateInfo" : "Актуальний курс $rateDateInfo";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _convertedAmountStr = "";
          _errorMessage = "Помилка: ${e.toString().replaceFirst("Exception: ", "")}";
          _rateInfoMessage = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _swapCurrencies() {
    if (_fromCurrency == null && _toCurrency == null) return;
    if(mounted){
      setState(() {
        final Currency? temp = _fromCurrency;
        _fromCurrency = _toCurrency;
        _toCurrency = temp;
      });
    }
    _triggerConversion();
  }

  @override
  void dispose() {
    _amountController.removeListener(_triggerConversion);
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конвертер валют'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Сума для конвертації',
                hintText: 'Введіть суму',
                border: const OutlineInputBorder(),
                prefixIcon: _fromCurrency != null ? Padding(padding: const EdgeInsets.all(12.0), child: Text(_fromCurrency!.symbol, style: const TextStyle(fontSize: 18))) : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<Currency>(
                    value: _fromCurrency,
                    decoration: const InputDecoration(
                      labelText: 'З валюти',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (BuildContext context) {
                      return _availableCurrencies.map<Widget>((Currency item) {
                        return Text(item.code, overflow: TextOverflow.ellipsis);
                      }).toList();
                    },
                    items: _availableCurrencies.map((Currency currency) {
                      return DropdownMenuItem<Currency>(
                        value: currency,
                        child: Text('${currency.code} (${currency.name})'),
                      );
                    }).toList(),
                    onChanged: (Currency? newValue) {
                      if (newValue != null) {
                        if(mounted){
                          setState(() {
                            _fromCurrency = newValue;
                          });
                        }
                        _triggerConversion();
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 28),
                    tooltip: 'Поміняти валюти місцями',
                    onPressed: _swapCurrencies,
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<Currency>(
                    value: _toCurrency,
                    decoration: const InputDecoration(
                      labelText: 'В валюту',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (BuildContext context) {
                      return _availableCurrencies.map<Widget>((Currency item) {
                        return Text(item.code, overflow: TextOverflow.ellipsis);
                      }).toList();
                    },
                    items: _availableCurrencies.map((Currency currency) {
                      return DropdownMenuItem<Currency>(
                        value: currency,
                        child: Text('${currency.code} (${currency.name})'),
                      );
                    }).toList(),
                    onChanged: (Currency? newValue) {
                        if (newValue != null) {
                          if(mounted){
                            setState(() {
                              _toCurrency = newValue;
                            });
                          }
                          _triggerConversion();
                        }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Курс на дату: ${DateFormat('dd.MM.yyyy').format(_selectedRateDate)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Змінити дату'),
                  onPressed: _pickRateDate,
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_convertedAmountStr.isNotEmpty)
              Column(
                children: [
                  Text(
                    'Результат конвертації:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _convertedAmountStr,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                   if (_rateInfoMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _rateInfoMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ]
                ],
              )
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            Text(
              'Курси валют надаються НБУ. Конвертація є орієнтовною.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}