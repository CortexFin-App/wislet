import 'package:intl/intl.dart';
import '../models/receipt_parse_result.dart';

class ReceiptParser {
  ParseResult parseQrCode(String qrData) {
    if (qrData.startsWith('https://cabinet.tax.gov.ua')) {
      return _parseStateTaxServiceUrl(qrData);
    }
    try {
      final params =
          Uri.parse(qrData.contains('?') ? qrData : '?$qrData').queryParameters;
      final sumString = params['s'];
      final timeString = params['t'];
      final fiscalNumber = params['fn'];
      double? amount;
      if (sumString != null) {
        final sumAsDouble = double.tryParse(sumString);
        if (sumAsDouble != null) {
          amount =
              sumString.contains('.') ? sumAsDouble : sumAsDouble / 100.0;
        }
      }
      DateTime? date =
          timeString != null ? _parseFiscalDateTime(timeString) : null;

      if (amount == null && date == null) {
        return parseFromText(qrData);
      }
      return ParseResult(
        totalAmount: amount,
        date: date,
        merchantName: fiscalNumber != null ? 'Чек QR: $fiscalNumber' : null,
      );
    } catch (e) {
      return parseFromText(qrData);
    }
  }

  ParseResult _parseStateTaxServiceUrl(String url) {
    try {
      final params = Uri.parse(url).queryParameters;
      final sumString = params['sm'];
      final dateString = params['date'];
      final timeString = params['time'];
      final fiscalNumber = params['fn'];
      double? amount;
      if (sumString != null) {
        amount = double.tryParse(sumString.replaceAll(',', '.'));
      }
      DateTime? date;
      if (dateString != null && timeString != null) {
        date = _parseDpsDateTime(dateString, timeString);
      }
      return ParseResult(
        totalAmount: amount,
        date: date,
        merchantName: fiscalNumber != null ? 'Чек ДПС: $fiscalNumber' : null,
      );
    } catch (e) {
      return parseFromText(url);
    }
  }

  DateTime? _parseDpsDateTime(String dateStr, String timeStr) {
    if (dateStr.length != 8) return null;
    try {
      // Нормалізуємо рядок часу: видаляємо пробіли та розділювачі
      final cleanedTimeStr = timeStr.trim().replaceAll(':', '');
      final fullDateTimeString = '$dateStr$cleanedTimeStr';
      
      // Використовуємо універсальний парсер, що обробляє формати з/без секунд
      return _parseFiscalDateTime(fullDateTimeString);
    } catch (e) {
      return null;
    }
  }

  DateTime? _parseFiscalDateTime(String dateTimeString) {
    final cleanString = dateTimeString.replaceAll('T', '');
    try {
      if (cleanString.length >= 12) {
        final year = int.parse(cleanString.substring(0, 4));
        final month = int.parse(cleanString.substring(4, 6));
        final day = int.parse(cleanString.substring(6, 8));
        final hour = int.parse(cleanString.substring(8, 10));
        final minute = int.parse(cleanString.substring(10, 12));
        final seconds = cleanString.length == 14
            ? int.parse(cleanString.substring(12, 14))
            : 0;
        return DateTime(year, month, day, hour, minute, seconds);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  ParseResult parseFromText(String text) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return ParseResult(merchantName: text);
    }
    final double? amount = _findTotalAmountFromText(lines);
    final DateTime? date = _findDateFromText(lines);
    final String? merchant = _findMerchantFromText(lines);
    return ParseResult(
        totalAmount: amount, date: date, merchantName: merchant ?? text);
  }

  double? _findTotalAmountFromText(List<String> lines) {
    final specificPatternRegex = RegExp(r'(\d+[,.]\d{2})\s*rph', caseSensitive: false);
    for (final line in lines.reversed) {
      final match = specificPatternRegex.firstMatch(line);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '.');
        return double.tryParse(amountStr);
      }
    }
    return null;
  }

  DateTime? _findDateFromText(List<String> lines) {
    final dateTimeRegex = RegExp(r'(\d{2,4}[./-]\d{2}[./-]\d{2,4})[\sT]*(\d{2}\s*:\s*\d{2}(?:\s*:\s*\d{2})?)?');
    final dateFormats = [
      DateFormat('dd.MM.yyyy'),
      DateFormat('dd.MM.yy'),
      DateFormat('yyyy-MM-dd')
    ];
    for (String line in lines) {
      final match = dateTimeRegex.firstMatch(line);
      if (match != null) {
        String dateStr = match.group(1)!.replaceAll('-', '.').replaceAll('/', '.');
        String? timeStr = match.group(2);
        DateTime? parsedDate;
        for (var format in dateFormats) {
          try {
            parsedDate = format.parse(dateStr);
            break;
          } catch (_) {
            continue;
          }
        }
        if (parsedDate != null) {
          if (timeStr != null) {
            final timeParts = timeStr.replaceAll(' ', '').split(':');
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            return DateTime(
                parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
          } else {
            final now = DateTime.now();
            return DateTime(
                parsedDate.year, parsedDate.month, parsedDate.day, now.hour, now.minute);
          }
        }
      }
    }
    return null;
  }

  String? _findMerchantFromText(List<String> lines) {
    if (lines.isNotEmpty) {
      final firstLine = lines.first.trim();
      if (!_isLineLikelyDateOrAmount(firstLine)) {
        return firstLine;
      }
    }
    return null;
  }

  bool _isLineLikelyDateOrAmount(String line) {
    final dateTimeRegex = RegExp(r'\d{2}[./-]\d{2}[./-]\d{2,4}');
    final amountRegex = RegExp(r'\d+[,.]\d{2}');
    return dateTimeRegex.hasMatch(line) || amountRegex.hasMatch(line);
  }
}