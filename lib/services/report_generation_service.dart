import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import '../models/transaction_view_data.dart';
import '../models/transaction.dart' as FinTransaction;

class ReportGenerationService {
  Future<Uint8List> generateCsvBytes(List<TransactionViewData> transactions) async {
    List<List<dynamic>> rows = [];
    rows.add(['Дата', 'Час', 'Категорія', 'Опис', 'Сума', 'Валюта', 'Тип']);

    for (var tx in transactions) {
      rows.add([
        DateFormat('dd.MM.yyyy').format(tx.date),
        DateFormat('HH:mm').format(tx.date),
        tx.categoryName,
        tx.description ?? '',
        tx.originalAmount,
        tx.originalCurrencyCode,
        tx.type == FinTransaction.TransactionType.income ? 'Дохід' : 'Витрата'
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    return Uint8List.fromList(utf8.encode(csv));
  }

  Future<Uint8List> generatePdfBytes(List<TransactionViewData> transactions, String period) async {
    final pdf = pw.Document();
    
    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/NotoSans-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    final headers = ['Дата', 'Категорія', 'Опис', 'Сума'];

    final data = transactions.map((tx) {
      final amountPrefix = tx.type == FinTransaction.TransactionType.income ? '+' : '-';
      final formattedAmount = NumberFormat.currency(symbol: tx.originalCurrencyCode, decimalDigits: 2, locale: 'uk_UA').format(tx.originalAmount);
      return [
        DateFormat('dd.MM.yy').format(tx.date),
        tx.categoryName,
        tx.description ?? '',
        '$amountPrefix$formattedAmount'
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Фінансовий звіт', style: pw.TextStyle(font: boldTtf, fontSize: 20)),
                  pw.Text(period, style: pw.TextStyle(font: ttf, fontSize: 12)),
                ],
              ),
            ),
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(font: boldTtf, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
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
              }
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text('Сторінка ${context.pageNumber} з ${context.pagesCount}',
                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey)),
          );
        },
      ),
    );
    
    return pdf.save();
  }
}