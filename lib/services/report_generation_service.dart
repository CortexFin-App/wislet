import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:wislet/models/transaction.dart' as fin_transaction;
import 'package:wislet/models/transaction_view_data.dart';

class ReportGenerationService {
  Future<Uint8List> generateCsvBytes(
    List<TransactionViewData> transactions,
  ) async {
    final rows = <List<dynamic>>[];
    rows.add(
      [
        'Р”Р°С‚Р°',
        'Р§Р°СЃ',
        'РљР°С‚РµРіРѕСЂС–СЏ',
        'РћРїРёСЃ',
        'РЎСѓРјР°',
        'Р’Р°Р»СЋС‚Р°',
        'РўРёРї',
      ],
    );

    for (final tx in transactions) {
      rows.add([
        DateFormat('dd.MM.yyyy').format(tx.date),
        DateFormat('HH:mm').format(tx.date),
        tx.categoryName,
        tx.description ?? '',
        tx.originalAmount,
        tx.originalCurrencyCode,
        if (tx.type == fin_transaction.TransactionType.income)
          'Р”РѕС…С–Рґ'
        else
          'Р’РёС‚СЂР°С‚Р°',
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    return Uint8List.fromList(utf8.encode(csv));
  }

  Future<Uint8List> generatePdfBytes(
    List<TransactionViewData> transactions,
    String period,
  ) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldFontData =
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    final headers = ['Р”Р°С‚Р°', 'РљР°С‚РµРіРѕСЂС–СЏ', 'РћРїРёСЃ', 'РЎСѓРјР°'];

    final data = transactions.map((tx) {
      final amountPrefix =
          tx.type == fin_transaction.TransactionType.income ? '+' : '-';
      final formattedAmount = NumberFormat.currency(
        symbol: tx.originalCurrencyCode,
        decimalDigits: 2,
        locale: 'uk_UA',
      ).format(tx.originalAmount);
      return [
        DateFormat('dd.MM.yy').format(tx.date),
        tx.categoryName,
        tx.description ?? '',
        '$amountPrefix$formattedAmount',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Р¤С–РЅР°РЅСЃРѕРІРёР№ Р·РІС–С‚',
                    style: pw.TextStyle(font: boldTtf, fontSize: 20),
                  ),
                  pw.Text(period, style: pw.TextStyle(font: ttf, fontSize: 12)),
                ],
              ),
            ),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(
                font: boldTtf,
                fontSize: 10,
                color: PdfColors.white,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
              cellHeight: 25,
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FlexColumnWidth(3),
              },
            ),
          ];
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'РЎС‚РѕСЂС–РЅРєР° ${context.pageNumber} Р· ${context.pagesCount}',
              style: pw.Theme.of(context)
                  .defaultTextStyle
                  .copyWith(color: PdfColors.grey),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
