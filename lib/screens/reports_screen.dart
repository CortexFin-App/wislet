import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../core/di/injector.dart';
import '../providers/currency_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/currency_model.dart';
import '../models/category.dart' as FinCategory;
import '../models/transaction.dart' as FinTransactionModel;
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/plan_repository.dart';
import '../services/exchange_rate_service.dart';
import '../services/report_generation_service.dart';

class PlanActualReportItemDisplay {
  final String categoryName;
  final FinCategory.CategoryType categoryType;
  final String formattedPlannedAmount;
  final String formattedActualAmount;
  final String formattedDifference;
  final Color differenceColor;

  PlanActualReportItemDisplay({
    required this.categoryName,
    required this.categoryType,
    required this.formattedPlannedAmount,
    required this.formattedActualAmount,
    required this.formattedDifference,
    required this.differenceColor,
  });
}

class ChartDataPointDisplay {
  final String label;
  final double value;
  final String formattedValue;
  final Color color;

  ChartDataPointDisplay({
    required this.label,
    required this.value,
    required this.formattedValue,
    this.color = Colors.blue
  });
}

class MonthlyTrendDisplayData {
  final DateTime month;
  final double incomeForChart;
  final double expenseForChart;
  final String formattedIncome;
  final String formattedExpense;

  MonthlyTrendDisplayData({
    required this.month,
    required this.incomeForChart,
    required this.expenseForChart,
    required this.formattedIncome,
    required this.formattedExpense,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

enum ReportFormat { pdf, csv }

class _ReportsScreenState extends State<ReportsScreen> {
  final TransactionRepository _transactionRepository = getIt<TransactionRepository>();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  final PlanRepository _planRepository = getIt<PlanRepository>();
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();
  final ReportGenerationService _reportService = getIt<ReportGenerationService>();

  DateTime _reportStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _reportEndDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  
  Future<Map<String, dynamic>>? _reportsFuture;
  int? _touchedIndexPieChart;
  
  final String _baseCurrencyCode = 'UAH';
  static const double _tabletBreakpoint = 720.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiateReportGeneration();
    });
  }
  
  void _initiateReportGeneration() {
    if (mounted) {
      final walletProvider = context.read<WalletProvider>();
      final currencyProvider = context.read<CurrencyProvider>();
      final currentWalletId = walletProvider.currentWallet?.id;

      if (currentWalletId != null) {
        setState(() {
          _reportsFuture = _generateReports(currentWalletId, currencyProvider.selectedCurrency);
        });
      }
    }
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _reportStartDate, end: _reportEndDate),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('uk', 'UA'),
    );

    if (pickedRange != null && mounted) {
      setState(() {
        _reportStartDate = pickedRange.start;
        _reportEndDate = DateTime(pickedRange.end.year, pickedRange.end.month, pickedRange.end.day, 23, 59, 59);
        _initiateReportGeneration();
      });
    }
  }
  
  Future<void> _showExportDialog() async {
    ReportFormat? selectedFormat = ReportFormat.pdf;
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Експорт звіту'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Період: ${DateFormat('dd.MM.yyyy').format(_reportStartDate)} - ${DateFormat('dd.MM.yyyy').format(_reportEndDate)}'),
                    const SizedBox(height: 16),
                    const Text('Оберіть формат файлу:'),
                    RadioListTile<ReportFormat>(
                      title: const Text('PDF документ'),
                      value: ReportFormat.pdf,
                      groupValue: selectedFormat,
                      onChanged: (ReportFormat? value) {
                        setDialogState(() {
                          selectedFormat = value;
                        });
                      },
                    ),
                    RadioListTile<ReportFormat>(
                      title: const Text('CSV таблиця'),
                      value: ReportFormat.csv,
                      groupValue: selectedFormat,
                      onChanged: (ReportFormat? value) {
                        setDialogState(() {
                          selectedFormat = value;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Скасувати'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(selectedFormat);
                    },
                    child: const Text('Експортувати'),
                  )
                ],
              );
            },
          );
        }).then((selectedFormat) {
      if (selectedFormat != null) {
        _handleExport(selectedFormat);
      }
    });
  }

  Future<void> _handleExport(ReportFormat format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Генерація звіту...')),
    );
    try {
      final walletId = context.read<WalletProvider>().currentWallet!.id!;
      final transactions = await _transactionRepository.getTransactionsWithDetails(
        walletId: walletId,
        startDate: _reportStartDate,
        endDate: _reportEndDate,
      );
      if (transactions.isEmpty) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Немає транзакцій за обраний період для експорту.')),
          );
        }
        return;
      }
      
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final reportPeriod = "Звіт за період з ${DateFormat('dd.MM.yyyy').format(_reportStartDate)} по ${DateFormat('dd.MM.yyyy').format(_reportEndDate)}";
      
      if (format == ReportFormat.pdf) {
        final bytes = await _reportService.generatePdfBytes(transactions, reportPeriod);
        final file = XFile.fromData(bytes, mimeType: 'application/pdf', name: 'report_$timestamp.pdf');
        await Share.shareXFiles([file], subject: 'Фінансовий звіт', text: reportPeriod);
      } else {
        final bytes = await _reportService.generateCsvBytes(transactions);
        final file = XFile.fromData(bytes, mimeType: 'text/csv', name: 'report_$timestamp.csv');
        await Share.shareXFiles([file], subject: 'Фінансовий звіт', text: reportPeriod);
      }
      
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка генерації звіту: $e')),
        );
      }
    }
  }

  Future<ConversionRateInfo?> _fetchDisplayRateInfoForDate(Currency displayCurrency, DateTime dateForRate) async {
    if (displayCurrency.code == _baseCurrencyCode) {
      return ConversionRateInfo(rate: 1.0, effectiveRateDate: dateForRate, isRateStale: false);
    }
    try {
      DateTime rateQueryDate = dateForRate.isAfter(DateTime.now()) ? DateTime.now() : dateForRate;
      return await _exchangeRateService.getConversionRate(_baseCurrencyCode, displayCurrency.code, date: rateQueryDate);
    } catch (e) {
      return null;
    }
  }

  String _formatAmountWithRateInfo(double amountInBaseUAH, Currency displayCurrency, ConversionRateInfo? rateInfo) {
    double displayAmount = amountInBaseUAH;
    String suffix = "";
    if (displayCurrency.code == _baseCurrencyCode) {
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
    if (displayCurrency.code == _baseCurrencyCode || rateInfo == null || rateInfo.rate == 0) {
      return amountInBaseUAH;
    }
    return amountInBaseUAH * rateInfo.rate;
  }

  Future<Map<String, dynamic>> _generateReports(int currentWalletId, Currency displayCurrency) async {
    final DateTime rateDateForPeriodReports = _reportEndDate.isAfter(DateTime.now()) ? DateTime.now() : _reportEndDate;
    
    final ConversionRateInfo? displayRateInfoForPeriod = await _fetchDisplayRateInfoForDate(displayCurrency, rateDateForPeriodReports);
    if(!mounted) return {};

    List<PlanActualReportItemDisplay> planActualItems = [];
    final allCategories = await _categoryRepository.getAllCategories(currentWalletId);
    if(!mounted) return {};
    
    final allPlans = await _planRepository.getPlansForPeriod(currentWalletId, _reportStartDate, _reportEndDate);
    if(!mounted) return {};

    for (var category in allCategories) {
      double totalPlannedUAH = allPlans
          .where((plan) => plan.categoryId == category.id)
          .fold(0.0, (sum, p) => sum + p.plannedAmountInBaseCurrency);
      if(!mounted) return {};
      
      double totalActualUAH = await _transactionRepository.getTotalAmount(
        walletId: currentWalletId,
        startDate: _reportStartDate,
        endDate: _reportEndDate,
        transactionType: category.type == FinCategory.CategoryType.income 
            ? FinTransactionModel.TransactionType.income 
            : FinTransactionModel.TransactionType.expense,
        categoryId: category.id,
      );
      if(!mounted) return {};
      
      if (totalPlannedUAH > 0 || totalActualUAH > 0) {
        double differenceValue = category.type == FinCategory.CategoryType.income 
                                    ? totalActualUAH - totalPlannedUAH 
                                    : totalPlannedUAH - totalActualUAH;
        
        final differenceColor = differenceValue > 0 ? Colors.green.shade700 : (differenceValue < 0 ? Colors.red.shade700 : Theme.of(context).textTheme.bodyMedium!.color!);
        if (!mounted) return {};

        planActualItems.add(PlanActualReportItemDisplay(
          categoryName: category.name,
          categoryType: category.type,
          formattedPlannedAmount: _formatAmountWithRateInfo(totalPlannedUAH, displayCurrency, displayRateInfoForPeriod),
          formattedActualAmount: _formatAmountWithRateInfo(totalActualUAH, displayCurrency, displayRateInfoForPeriod),
          formattedDifference: (differenceValue > 0 ? "+" : (differenceValue < 0 ? "-" : "")) + _formatAmountWithRateInfo(differenceValue.abs(), displayCurrency, displayRateInfoForPeriod),
          differenceColor: differenceColor,
        ));
      }
    }

    List<ChartDataPointDisplay> pieDisplayData = [];
    final expensesGroupedUAH = await _transactionRepository.getExpensesGroupedByCategory(currentWalletId, _reportStartDate, _reportEndDate);
    if(!mounted) return {};

    final colorScheme = Theme.of(context).colorScheme;
    if(!mounted) return {};
    
    final List<Color> pieColors = [
      colorScheme.primary, colorScheme.secondary, colorScheme.tertiary,
      colorScheme.error, colorScheme.outline, colorScheme.primaryContainer, 
      colorScheme.secondaryContainer, colorScheme.tertiaryContainer, Colors.cyan, Colors.purpleAccent,
    ];

    for (int i = 0; i < expensesGroupedUAH.length; i++) {
        final item = expensesGroupedUAH[i];
        double amountUAH = item['totalAmount'] as double;
        pieDisplayData.add(ChartDataPointDisplay(
          label: item['categoryName'] as String,
          value: _convertToDisplayValueWithRateInfo(amountUAH, displayCurrency, displayRateInfoForPeriod),
          formattedValue: _formatAmountWithRateInfo(amountUAH, displayCurrency, displayRateInfoForPeriod),
          color: pieColors[i % pieColors.length],
        ));
    }

    List<MonthlyTrendDisplayData> trendDisplayItems = [];
    double maxChartYValue = 0;
    DateTime currentMonthEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    
    for (int i = 5; i >= 0; i--) {
        DateTime monthEndDateForTrend = DateTime(currentMonthEnd.year, currentMonthEnd.month - i + 1, 0);
        DateTime monthStartDateForTrend = DateTime(monthEndDateForTrend.year, monthEndDateForTrend.month, 1);
        
        final ConversionRateInfo? displayRateInfoForMonth = await _fetchDisplayRateInfoForDate(displayCurrency, monthEndDateForTrend);
        if(!mounted) return {};
        
        double monthlyIncomeUAH = await _transactionRepository.getTotalAmount(walletId: currentWalletId, startDate: monthStartDateForTrend, endDate: monthEndDateForTrend, transactionType: FinTransactionModel.TransactionType.income);
        if(!mounted) return {};
        
        double monthlyExpensesUAH = await _transactionRepository.getTotalAmount(walletId: currentWalletId, startDate: monthStartDateForTrend, endDate: monthEndDateForTrend, transactionType: FinTransactionModel.TransactionType.expense);
        if(!mounted) return {};
        
        double incomeForChart = _convertToDisplayValueWithRateInfo(monthlyIncomeUAH, displayCurrency, displayRateInfoForMonth);
        double expenseForChart = _convertToDisplayValueWithRateInfo(monthlyExpensesUAH, displayCurrency, displayRateInfoForMonth);
        
        trendDisplayItems.add(MonthlyTrendDisplayData(
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
      'planActualItems': planActualItems,
      'spendingPieChartData': pieDisplayData,
      'monthlyTrendData': trendDisplayItems,
      'lineChartMaxY': maxChartYValue == 0 ? 1000.0 : (maxChartYValue * 1.25).ceilToDouble(),
    };
  }
  
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Період звітів:", style: Theme.of(context).textTheme.labelLarge),
                    Text(
                      "${DateFormat('dd.MM.yyyy', 'uk_UA').format(_reportStartDate)} - ${DateFormat('dd.MM.yyyy', 'uk_UA').format(_reportEndDate)}",
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                    IconButton(
                    icon: const Icon(Icons.ios_share_outlined),
                    tooltip: 'Експорт звіту',
                    onPressed: _showExportDialog,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Змінити'),
                    onPressed: _pickDateRange,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _reportsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || _reportsFuture == null) {
                return _buildShimmerLoadingReport();
              }
              if (snapshot.hasError) {
                return Center(child: Text('Помилка генерації звіту: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Немає даних для побудови звітів.'));
              }
              final data = snapshot.data!;
              Widget chartsSection = (screenWidth > _tabletBreakpoint) 
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Expanded(child: _buildPieChartSection(context, data['spendingPieChartData'] as List<ChartDataPointDisplay>)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLineChartSection(context, data['monthlyTrendData'] as List<MonthlyTrendDisplayData>, data['lineChartMaxY'] as double)),
                  ])
                : Column(children: <Widget>[
                    _buildPieChartSection(context, data['spendingPieChartData'] as List<ChartDataPointDisplay>),
                    const Divider(height: 24, thickness: 1),
                    _buildLineChartSection(context, data['monthlyTrendData'] as List<MonthlyTrendDisplayData>, data['lineChartMaxY'] as double),
                  ]);
              return RefreshIndicator(
                onRefresh: () async => _initiateReportGeneration(),
                child: ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: [
                    _buildPlanActualSection(context, data['planActualItems'] as List<PlanActualReportItemDisplay>),
                    const Divider(height: 24, thickness: 1),
                    chartsSection,
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanActualSection(BuildContext context, List<PlanActualReportItemDisplay> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Text(
            'Аналіз "План-Факт"',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (items.isEmpty)
          _buildSectionEmptyState(
            context,
            Icons.fact_check_outlined,
            'Немає даних для аналізу "План-Факт"',
            'Перевірте обраний період або додайте плани та відповідні транзакції.',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${item.categoryName} (${item.categoryType == FinCategory.CategoryType.income ? 'Дохід' : 'Витрата'})",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('План:'), Text(item.formattedPlannedAmount, style: const TextStyle(fontWeight: FontWeight.bold))]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Факт:'), Text(item.formattedActualAmount, style: TextStyle(fontWeight: FontWeight.bold, color: item.differenceColor == Colors.green.shade700 ? Theme.of(context).colorScheme.tertiary : (item.differenceColor == Colors.red.shade700 ? Theme.of(context).colorScheme.error : null)))]),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Різниця:'), Text(item.formattedDifference, style: TextStyle(fontWeight: FontWeight.bold, color: item.differenceColor))]),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPieChartSection(BuildContext context, List<ChartDataPointDisplay> pieData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Text('Витрати за категоріями', style: Theme.of(context).textTheme.titleLarge),
        ),
        if (pieData.isEmpty)
        _buildSectionEmptyState(context, Icons.pie_chart_outline, 'Немає даних для діаграми', 'Додайте транзакції витрат за обраний період.')
        else
        SizedBox(
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if(mounted){
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndexPieChart = -1;
                              return;
                            }
                            _touchedIndexPieChart = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        }
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: pieData.asMap().entries.map((entry) {
                      final int i = entry.key;
                      final ChartDataPointDisplay data = entry.value;
                      final bool isTouched = i == _touchedIndexPieChart;
                      final double fontSize = isTouched ? 16.0 : 12.0;
                      final double radius = isTouched ? 70.0 : 60.0;
                      double total = pieData.fold(0.0, (sum, item) => sum + item.value);
                      final double percentage = total > 0 ? (data.value / total) * 100 : 0;
                      return PieChartSectionData(
                        color: data.color,
                        value: data.value,
                        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: data.color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                alignment: WrapAlignment.center,
                children: pieData.map((data) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, color: data.color),
                      const SizedBox(width: 4),
                      Text('${data.label} (${data.formattedValue})', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineChartSection(BuildContext context, List<MonthlyTrendDisplayData> trendData, double lineChartMaxY) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Text('Динаміка (останні 6 міс.)', style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trendData.isEmpty || (trendData.every((d) => d.incomeForChart == 0 && d.expenseForChart == 0)))
        _buildSectionEmptyState(context, Icons.show_chart, 'Немає даних для графіка', 'Додайте транзакції за кілька місяців.')
        else
        SizedBox(
          height: 280,
          child: Column(
            children: [
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).colorScheme.outline.withOpacity(0.2), strokeWidth: 0.5), getDrawingVerticalLine: (value) => FlLine(color: Theme.of(context).colorScheme.outline.withOpacity(0.2), strokeWidth: 0.5)),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < trendData.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(DateFormat('MMM', 'uk_UA').format(trendData[index].month), style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (double value, TitleMeta meta) {
                              if(value == 0 && lineChartMaxY == 0) return const Text('');
                              final displayValue = value;
                              if (value == 0 || value == lineChartMaxY || (lineChartMaxY > 2000 && value % (lineChartMaxY / 4).roundToDouble() == 0) || (lineChartMaxY <=2000 && lineChartMaxY > 0 && value % (lineChartMaxY / 2).roundToDouble()==0) ) {
                                return Text('${(displayValue / 1000).toStringAsFixed(displayValue > 0 && displayValue < 1000 && lineChartMaxY > 0 ? 1:0)}k', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant));
                              }
                              return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5), width: 1)),
                    minX: 0,
                    maxX: trendData.isEmpty ? 0 : (trendData.length - 1).toDouble(),
                    minY: 0,
                    maxY: lineChartMaxY,
                    lineBarsData: [
                      LineChartBarData(spots: trendData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.incomeForChart)).toList(), isCurved: true, color: Theme.of(context).colorScheme.tertiary, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2))),
                      LineChartBarData(spots: trendData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.expenseForChart)).toList(), isCurved: true, color: Theme.of(context).colorScheme.error, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.error.withOpacity(0.2))),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final index = barSpot.spotIndex;
                              if (index < 0 || index >= trendData.length) return null;
                              final trendDataItem = trendData[index];
                              String text;
                              Color spotColor;
                              if (barSpot.barIndex == 0) { 
                                text = 'Дохід: ${trendDataItem.formattedIncome}';
                                spotColor = Theme.of(context).colorScheme.tertiary;
                              } else { 
                                text = 'Витрати: ${trendDataItem.formattedExpense}';
                                spotColor = Theme.of(context).colorScheme.error;
                              }
                              return LineTooltipItem(text, TextStyle(color: spotColor, fontWeight: FontWeight.bold));
                            }).where((item) => item != null).cast<LineTooltipItem>().toList();
                          }
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [Container(width: 12, height: 12, color: Theme.of(context).colorScheme.tertiary), const SizedBox(width: 4), const Text('Доходи')]),
                  const SizedBox(width: 16),
                  Row(children: [Container(width: 12, height: 12, color: Theme.of(context).colorScheme.error), const SizedBox(width: 4), const Text('Витрати')]),
                ],
              )
            ],
          )
        ),
      ],
    );
  }

  Widget _buildSectionEmptyState(BuildContext context, IconData icon, String title, String message) {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard({double height = 70, int lineCount = 2, double lineWidthFraction = 0.6}) {
    return Container(
        height: height,
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: lineCount == 0 ? null : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(lineCount, (index) => 
            Container(
              height: 10, 
              width: MediaQuery.of(context).size.width * (lineWidthFraction - (index * 0.1)), 
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 4),
            )
          ),
        )
    );
  }

  Widget _buildSkeletonTitle() {
    return Container(
      height: 24,
      width: MediaQuery.of(context).size.width * 0.6,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  Widget _buildShimmerLoadingReport() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[700]!,
      highlightColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[100]! : Colors.grey[500]!,
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildSkeletonTitle(), 
          _buildSkeletonCard(height: 100, lineCount: 4, lineWidthFraction: 0.7),
          _buildSkeletonCard(height: 100, lineCount: 4, lineWidthFraction: 0.6),
          const SizedBox(height: 16),
          _buildSkeletonTitle(), 
          _buildSkeletonCard(height: 250, lineCount: 0),
          const SizedBox(height: 16),
          _buildSkeletonTitle(), 
          _buildSkeletonCard(height: 280, lineCount: 0),
        ],
      ),
    );
  }
}