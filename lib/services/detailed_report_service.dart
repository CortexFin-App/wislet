import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/di/injector.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/plan_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../models/category.dart' as fin_category;
import '../models/transaction.dart' as fin_transaction;
import '../models/currency_model.dart';
import '../services/exchange_rate_service.dart';
import '../utils/app_palette.dart';

class DetailedReportService {
  final TransactionRepository _transactionRepository = getIt<TransactionRepository>();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  final PlanRepository _planRepository = getIt<PlanRepository>();
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();

  Future<Map<String, dynamic>> generateDetailedReportData({
    required int walletId,
    required DateTime startDate,
    required DateTime endDate,
    required Currency displayCurrency,
  }) async {
    final planActualItems = await _getPlanActualReport(walletId, startDate, endDate, displayCurrency);
    final pieData = await _getSpendingPieChartData(walletId, startDate, endDate, displayCurrency);
    final trendDataResult = await _getMonthlyTrendData(walletId, displayCurrency);

    return {
      'planActualItems': planActualItems,
      'spendingPieChartData': pieData,
      'monthlyTrendData': trendDataResult['data'],
      'lineChartMaxY': trendDataResult['maxY'],
    };
  }

  Future<List<PlanActualReportItemDisplay>> _getPlanActualReport(int walletId, DateTime startDate, DateTime endDate, Currency displayCurrency) async {
    final rateInfo = await _fetchDisplayRateInfoForDate(displayCurrency, endDate);
    final allCategories = (await _categoryRepository.getAllCategories(walletId)).getOrElse((_) => []);
    final allPlans = (await _planRepository.getPlansForPeriod(walletId, startDate, endDate)).getOrElse((_) => []);
    
    List<PlanActualReportItemDisplay> items = [];
    for (var category in allCategories) {
      double totalPlannedUAH = allPlans.where((p) => p.categoryId == category.id).fold(0.0, (sum, p) => sum + p.plannedAmountInBaseCurrency);
      final totalActualUAHEither = await _transactionRepository.getTotalAmount(
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
        transactionType: category.type == fin_category.CategoryType.income ? fin_transaction.TransactionType.income : fin_transaction.TransactionType.expense,
        categoryId: category.id,
      );
      final totalActualUAH = totalActualUAHEither.getOrElse((_) => 0.0);

      if (totalPlannedUAH > 0 || totalActualUAH > 0) {
        double differenceValue = category.type == fin_category.CategoryType.income ? totalActualUAH - totalPlannedUAH : totalPlannedUAH - totalActualUAH;
        items.add(PlanActualReportItemDisplay(
          categoryName: category.name,
          categoryType: category.type,
          formattedPlannedAmount: _formatAmountWithRateInfo(totalPlannedUAH, displayCurrency, rateInfo),
          formattedActualAmount: _formatAmountWithRateInfo(totalActualUAH, displayCurrency, rateInfo),
          formattedDifference: (differenceValue >= 0 ? "+" : "") + _formatAmountWithRateInfo(differenceValue, displayCurrency, rateInfo),
          differenceColor: differenceValue >= 0 ? AppPalette.darkPositive : AppPalette.darkNegative,
        ));
      }
    }
    return items;
  }

  Future<List<ChartDataPointDisplay>> _getSpendingPieChartData(int walletId, DateTime startDate, DateTime endDate, Currency displayCurrency) async {
    final rateInfo = await _fetchDisplayRateInfoForDate(displayCurrency, endDate);
    final expensesGrouped = (await _transactionRepository.getExpensesGroupedByCategory(walletId, startDate, endDate)).getOrElse((_) => []);
    
    List<ChartDataPointDisplay> pieData = [];
    final List<Color> pieColors = [
      AppPalette.darkPrimary, AppPalette.darkAccent, Colors.purpleAccent,
      Colors.orangeAccent, Colors.cyan, Colors.pinkAccent,
    ];

    for (int i = 0; i < expensesGrouped.length; i++) {
        final item = expensesGrouped[i];
        double amountUAH = item['totalAmount'] as double;
        pieData.add(ChartDataPointDisplay(
          label: item['categoryName'] as String,
          value: _convertToDisplayValueWithRateInfo(amountUAH, displayCurrency, rateInfo),
          formattedValue: _formatAmountWithRateInfo(amountUAH, displayCurrency, rateInfo),
          color: pieColors[i % pieColors.length],
        ));
    }
    return pieData;
  }
  
  Future<Map<String, dynamic>> _getMonthlyTrendData(int walletId, Currency displayCurrency) async {
    List<MonthlyTrendDisplayData> trendItems = [];
    double maxChartYValue = 0;
    DateTime currentMonthEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    for (int i = 5; i >= 0; i--) {
        DateTime monthEndDateForTrend = DateTime(currentMonthEnd.year, currentMonthEnd.month - i + 1, 0);
        DateTime monthStartDateForTrend = DateTime(monthEndDateForTrend.year, monthEndDateForTrend.month, 1);

        final displayRateInfoForMonth = await _fetchDisplayRateInfoForDate(displayCurrency, monthEndDateForTrend);
        
        final monthlyIncomeUAH = await _transactionRepository.getTotalAmount(walletId: walletId, startDate: monthStartDateForTrend, endDate: monthEndDateForTrend, transactionType: fin_transaction.TransactionType.income).then((e) => e.getOrElse((l) => 0.0));
        final monthlyExpensesUAH = await _transactionRepository.getTotalAmount(walletId: walletId, startDate: monthStartDateForTrend, endDate: monthEndDateForTrend, transactionType: fin_transaction.TransactionType.expense).then((e) => e.getOrElse((l) => 0.0));
        
        double incomeForChart = _convertToDisplayValueWithRateInfo(monthlyIncomeUAH, displayCurrency, displayRateInfoForMonth);
        double expenseForChart = _convertToDisplayValueWithRateInfo(monthlyExpensesUAH, displayCurrency, displayRateInfoForMonth);

        trendItems.add(MonthlyTrendDisplayData(
            month: monthStartDateForTrend,
            incomeForChart: incomeForChart,
            expenseForChart: expenseForChart,
            formattedIncome: _formatAmountWithRateInfo(monthlyIncomeUAH, displayCurrency, displayRateInfoForMonth),
            formattedExpense: _formatAmountWithRateInfo(monthlyExpensesUAH, displayCurrency, displayRateInfoForMonth)
        ));
        if (incomeForChart > maxChartYValue) maxChartYValue = incomeForChart;
        if (expenseForChart > maxChartYValue) maxChartYValue = expenseForChart;
    }
    
    return {
      'data': trendItems,
      'maxY': maxChartYValue == 0 ? 1000.0 : (maxChartYValue * 1.25).ceilToDouble()
    };
  }

  Future<ConversionRateInfo?> _fetchDisplayRateInfoForDate(Currency displayCurrency, DateTime dateForRate) async {
    if (displayCurrency.code == 'UAH') {
      return ConversionRateInfo(rate: 1.0, effectiveRateDate: dateForRate, isRateStale: false);
    }
    try {
      DateTime rateQueryDate = dateForRate.isAfter(DateTime.now()) ? DateTime.now() : dateForRate;
      return await _exchangeRateService.getConversionRate('UAH', displayCurrency.code, date: rateQueryDate);
    } catch (e) {
      return null;
    }
  }

  String _formatAmountWithRateInfo(double amountInBaseUAH, Currency displayCurrency, ConversionRateInfo? rateInfo) {
    double displayAmount = amountInBaseUAH;
    String suffix = "";
    if (displayCurrency.code == 'UAH') {
      return NumberFormat.currency(locale: displayCurrency.locale, symbol: displayCurrency.symbol, decimalDigits: 2).format(amountInBaseUAH);
    }

    if (rateInfo != null && rateInfo.rate != 0) {
      displayAmount = amountInBaseUAH * rateInfo.rate;
      if (rateInfo.isRateStale) {
        suffix = " (курс від ${DateFormat('dd.MM.yy').format(rateInfo.effectiveRateDate)})";
      }
      return NumberFormat.currency(locale: displayCurrency.locale, symbol: displayCurrency.symbol, decimalDigits: 2).format(displayAmount) + suffix;
    } else {
      return "${NumberFormat.currency(locale: 'uk_UA', symbol: '₴', decimalDigits: 2).format(amountInBaseUAH)} (${displayCurrency.symbol}?)";
    }
  }

  double _convertToDisplayValueWithRateInfo(double amountInBaseUAH, Currency displayCurrency, ConversionRateInfo? rateInfo) {
    if (displayCurrency.code == 'UAH' || rateInfo == null || rateInfo.rate == 0) {
      return amountInBaseUAH;
    }
    return amountInBaseUAH * rateInfo.rate;
  }
}

class PlanActualReportItemDisplay {
  final String categoryName;
  final fin_category.CategoryType categoryType;
  final String formattedPlannedAmount;
  final String formattedActualAmount;
  final String formattedDifference;
  final Color differenceColor;
  PlanActualReportItemDisplay({required this.categoryName, required this.categoryType, required this.formattedPlannedAmount, required this.formattedActualAmount, required this.formattedDifference, required this.differenceColor});
}

class ChartDataPointDisplay {
  final String label;
  final double value;
  final String formattedValue;
  final Color color;
  ChartDataPointDisplay({required this.label, required this.value, required this.formattedValue, this.color = Colors.blue});
}

class MonthlyTrendDisplayData {
  final DateTime month;
  final double incomeForChart;
  final double expenseForChart;
  final String formattedIncome;
  final String formattedExpense;
  MonthlyTrendDisplayData({required this.month, required this.incomeForChart, required this.expenseForChart, required this.formattedIncome, required this.formattedExpense});
}