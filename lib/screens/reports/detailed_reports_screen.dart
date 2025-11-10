import 'dart:io';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/services/detailed_report_service.dart';
import 'package:wislet/services/report_generation_service.dart';
import 'package:wislet/widgets/scaffold/patterned_scaffold.dart';

class DetailedReportsScreen extends StatefulWidget {
  const DetailedReportsScreen({super.key});

  @override
  State<DetailedReportsScreen> createState() => _DetailedReportsScreenState();
}

class _DetailedReportsScreenState extends State<DetailedReportsScreen> {
  final DetailedReportService _reportService = getIt<DetailedReportService>();
  final ReportGenerationService _reportGenerationService =
      getIt<ReportGenerationService>();
  final TransactionRepository _transactionRepository =
      getIt<TransactionRepository>();

  DateTime _reportStartDate =
      DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _reportEndDate =
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  Future<Map<String, dynamic>>? _reportsFuture;
  int? _touchedIndexPieChart;
  static const double _tabletBreakpoint = 720;

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
          _reportsFuture = _reportService.generateDetailedReportData(
            walletId: currentWalletId,
            startDate: _reportStartDate,
            endDate: _reportEndDate,
            displayCurrency: currencyProvider.selectedCurrency,
          );
        });
      }
    }
  }

  Future<void> _pickDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange:
          DateTimeRange(start: _reportStartDate, end: _reportEndDate),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedRange != null && mounted) {
      setState(() {
        _reportStartDate = pickedRange.start;
        _reportEndDate = DateTime(
          pickedRange.end.year,
          pickedRange.end.month,
          pickedRange.end.day,
          23,
          59,
          59,
        );
        _initiateReportGeneration();
      });
    }
  }

  Future<void> _exportReport(String format) async {
    final walletProvider = context.read<WalletProvider>();
    final walletId = walletProvider.currentWallet?.id;
    if (walletId == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Генерація звіту...')),
    );

    try {
      final transactionsEither =
          await _transactionRepository.getTransactionsWithDetails(
        walletId: walletId,
        startDate: _reportStartDate,
        endDate: _reportEndDate,
      );

      await transactionsEither.fold(
        (failure) => throw Exception(failure.userMessage),
        (transactions) async {
          Uint8List fileBytes;
          String fileName;
          String mimeType;

          final period =
              '${DateFormat('dd.MM.yy').format(_reportStartDate)}-${DateFormat('dd.MM.yy').format(_reportEndDate)}';

          if (format == 'pdf') {
            fileBytes = await _reportGenerationService.generatePdfBytes(
              transactions,
              period,
            );
            fileName = 'SageWallet_Report_$period.pdf';
            mimeType = 'application/pdf';
          } else {
            fileBytes =
                await _reportGenerationService.generateCsvBytes(transactions);
            fileName = 'SageWallet_Report_$period.csv';
            mimeType = 'text/csv';
          }

          final tempDir = await getTemporaryDirectory();
          final file =
              await File('${tempDir.path}/$fileName').writeAsBytes(fileBytes);

          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: mimeType)],
              subject: 'Фінансовий звіт',
            ),
          );
        },
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка експорту: $e')),
      );
    }
  }

  void _showExportDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Експорт звіту'),
        content: const Text(
          'Оберіть формат файлу для експорту.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportReport('csv');
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportReport('pdf');
            },
            child: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternedScaffold(
      appBar: AppBar(
        title: const Text('Детальні звіти'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: _showExportDialog,
            tooltip: 'Експорт',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Період:',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        '${DateFormat('dd.MM.yyyy').format(_reportStartDate)} - ${DateFormat('dd.MM.yyyy').format(_reportEndDate)}',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Змінити'),
                  onPressed: _pickDateRange,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    _reportsFuture == null) {
                  return _buildShimmerLoadingReport();
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Помилка генерації звіту: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Немає даних для побудови звітів.',
                    ),
                  );
                }
                final data = snapshot.data!;

                                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen =
                        constraints.maxWidth > _tabletBreakpoint;
                    final chartsSection = isWideScreen
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _buildPieChartSection(
                                  context,
                                  data['spendingPieChartData']
                                      as List<ChartDataPointDisplay>,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLineChartSection(
                                  context,
                                  data['monthlyTrendData']
                                      as List<MonthlyTrendDisplayData>,
                                  data['lineChartMaxY'] as double,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              _buildPieChartSection(
                                context,
                                data['spendingPieChartData']
                                    as List<ChartDataPointDisplay>,
                              ),
                              const Divider(
                                height: 24,
                                thickness: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              _buildLineChartSection(
                                context,
                                data['monthlyTrendData']
                                    as List<MonthlyTrendDisplayData>,
                                data['lineChartMaxY'] as double,
                              ),
                            ],
                          );

                    return RefreshIndicator(
                      onRefresh: () async => _initiateReportGeneration(),
                      child: ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          _buildPlanActualSection(
                            context,
                            data['planActualItems']
                                as List<PlanActualReportItemDisplay>,
                          ),
                          const Divider(
                            height: 24,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          chartsSection,
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanActualSection(
    BuildContext context,
    List<PlanActualReportItemDisplay> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            'Аналіз "План-Факт"',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (items.isEmpty)
          _buildSectionEmptyState(
            context,
            Icons.fact_check_outlined,
            'Немає даних для аналізу',
            'Перевірте обраний період або додайте плани та відповідні транзакції.',
          )
        else
          ...items.map((item) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.categoryName} (${item.categoryType.name == 'income' ? 'Доход' : 'Витрата'})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('План:'),
                        Text(
                          item.formattedPlannedAmount,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Факт:'),
                        Text(
                          item.formattedActualAmount,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.differenceColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Різниця:'),
                        Text(
                          item.formattedDifference,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.differenceColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPieChartSection(
    BuildContext context,
    List<ChartDataPointDisplay> pieData,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            'Витрати за категоріями',
            style: theme.textTheme.titleLarge,
          ),
        ),
        if (pieData.isEmpty)
          _buildSectionEmptyState(
            context,
            Icons.pie_chart_outline,
            'Немає даних для діаграми',
            'Додайте транзакції витрат за обраний період.',
          )
        else
          SizedBox(
            height: 300,
            child: Column(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          if (mounted) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndexPieChart = -1;
                                return;
                              }
                              _touchedIndexPieChart = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          }
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: pieData.asMap().entries.map((entry) {
                        final i = entry.key;
                        final data = entry.value;
                        final isTouched = i == _touchedIndexPieChart;
                        final fontSize = isTouched ? 16.0 : 12.0;
                        final radius = isTouched ? 70.0 : 60.0;
                        final total = pieData.fold<double>(
                          0,
                          (sum, item) => sum + item.value,
                        );
                        final percentage =
                            total > 0 ? (data.value / total) * 100 : 0.0;
                        return PieChartSectionData(
                          color: data.color,
                          value: data.value,
                          title: percentage > 5
                              ? '${percentage.toStringAsFixed(0)}%'
                              : '',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: data.color.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black26, blurRadius: 2),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: pieData.map((data) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 12, height: 12, color: data.color),
                        const SizedBox(width: 4),
                        Text(
                          '${data.label} (${data.formattedValue})',
                          style: theme.textTheme.bodySmall,
                        ),
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

  Widget _buildLineChartSection(
    BuildContext context,
    List<MonthlyTrendDisplayData> trendData,
    double lineChartMaxY,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            'Динаміка (останні 6 міс.)',
            style: theme.textTheme.titleLarge,
          ),
        ),
        if (trendData.isEmpty ||
            (trendData
                .every((d) => d.incomeForChart == 0 && d.expenseForChart == 0)))
          _buildSectionEmptyState(
            context,
            Icons.show_chart,
            'Немає даних для графіка',
            'Додайте транзакції за кілька місяців.',
          )
        else
          SizedBox(
            height: 280,
            child: Column(
              children: [
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.colorScheme.outline.withAlpha(50),
                          strokeWidth: 0.5,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: theme.colorScheme.outline.withAlpha(50),
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < trendData.length) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    DateFormat('MMM', 'uk_UA')
                                        .format(trendData[index].month),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
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
                            getTitlesWidget: (value, meta) {
                              if (value == 0 && lineChartMaxY == 0) {
                                return const Text('');
                              }
                              final displayValue = value;
                              if (value == 0 ||
                                  value == lineChartMaxY ||
                                  (lineChartMaxY > 2000 &&
                                      value %
                                              (lineChartMaxY / 4)
                                                  .roundToDouble() ==
                                          0) ||
                                  (lineChartMaxY <= 2000 &&
                                      lineChartMaxY > 0 &&
                                      value %
                                              (lineChartMaxY / 2)
                                                  .roundToDouble() ==
                                          0)) {
                                return Text(
                                  '${(displayValue / 1000).toStringAsFixed(displayValue > 0 && displayValue < 1000 && lineChartMaxY > 0 ? 1 : 0)}k',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(128),
                        ),
                      ),
                      minX: 0,
                      maxX: trendData.isEmpty
                          ? 0
                          : (trendData.length - 1).toDouble(),
                      minY: 0,
                      maxY: lineChartMaxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: trendData
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.incomeForChart,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          color: theme.colorScheme.tertiary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.tertiary.withAlpha(51),
                          ),
                        ),
                        LineChartBarData(
                          spots: trendData
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.expenseForChart,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          color: theme.colorScheme.error,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.error.withAlpha(51),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedBarSpots) {
                            return touchedBarSpots
                                .map((barSpot) {
                                  final index = barSpot.spotIndex;
                                  if (index < 0 || index >= trendData.length) {
                                    return null;
                                  }
                                  final trendDataItem = trendData[index];
                                  String text;
                                  Color spotColor;
                                  if (barSpot.barIndex == 0) {
                                    text =
                                        'Доход: ${trendDataItem.formattedIncome}';
                                    spotColor = theme.colorScheme.tertiary;
                                  } else {
                                    text =
                                        'Витрати: ${trendDataItem.formattedExpense}';
                                    spotColor = theme.colorScheme.error;
                                  }
                                  return LineTooltipItem(
                                    text,
                                    TextStyle(
                                      color: spotColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.left,
                                  );
                                })
                                .whereType<LineTooltipItem>()
                                .toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        const Text('Доходи'),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        const Text('Витрати'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionEmptyState(
    BuildContext context,
    IconData icon,
    String title,
    String message,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoadingReport() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainer,
      highlightColor: theme.colorScheme.surfaceContainerHighest,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Container(
            height: 24,
            width: MediaQuery.of(context).size.width * 0.6,
            margin: const EdgeInsets.all(8),
            color: Colors.white,
          ),
          Container(
            height: 100,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Container(
            height: 100,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 24,
            width: MediaQuery.of(context).size.width * 0.6,
            margin: const EdgeInsets.all(8),
            color: Colors.white,
          ),
          Container(
            height: 300,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
