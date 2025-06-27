import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../core/di/injector.dart';
import '../providers/currency_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/transaction.dart' as FinTransaction;
import '../models/currency_model.dart';
import '../models/transaction_view_data.dart';
import 'transactions/add_edit_transaction_screen.dart';
import '../services/exchange_rate_service.dart';
import '../utils/fade_page_route.dart';
import '../data/repositories/transaction_repository.dart';

class CategoryExpenseData {
  final String categoryName;
  final double totalAmountInBaseCurrency;
  final Color color;
  CategoryExpenseData(
      {required this.categoryName,
      required this.totalAmountInBaseCurrency,
      required this.color});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TransactionRepository _transactionRepository =
      getIt<TransactionRepository>();
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();

  double _overallBalanceUAH = 0.0;
  double _currentMonthIncomeUAH = 0.0;
  double _currentMonthExpensesUAH = 0.0;
  List<TransactionViewData> _recentTransactions = [];
  List<CategoryExpenseData> _pieChartRawData = [];

  bool _isLoadingData = true;
  bool _isLoadingDisplayRate = true;
  ConversionRateInfo? _displayRateInfo;
  int? _touchedIndexPieChart;

  final String _baseCurrencyCode = 'UAH';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllData();
      }
    });
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    if (!_isLoadingData || !_isLoadingDisplayRate) {
      setState(() {
        _isLoadingData = true;
        _isLoadingDisplayRate = true;
      });
    }

    await _fetchDisplayRate();
    if (!mounted) return;
    await _loadDashboardFinancialData();
    if (mounted) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _fetchDisplayRate() async {
    if (!mounted) return;

    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);
    if (!mounted) return;
    final selectedDisplayCurrency = currencyProvider.selectedCurrency;
    if (selectedDisplayCurrency.code == _baseCurrencyCode) {
      if (mounted) {
        setState(() {
          _displayRateInfo = ConversionRateInfo(
              rate: 1.0,
              effectiveRateDate: DateTime.now(),
              isRateStale: false);
          _isLoadingDisplayRate = false;
        });
      }
      return;
    }
    try {
      final rateInfo = await _exchangeRateService.getConversionRate(
          _baseCurrencyCode, selectedDisplayCurrency.code,
          date: DateTime.now());
      if (!mounted) return;
      setState(() {
        _displayRateInfo = rateInfo;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _displayRateInfo = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Не вдалося завантажити актуальний курс для ${selectedDisplayCurrency.code}.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDisplayRate = false;
        });
      }
    }
  }

  Future<void> refreshData() async {
    if (_isLoadingData || _isLoadingDisplayRate) return;
    await _loadAllData();
  }

  Future<void> _loadDashboardFinancialData() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) {
      setState(() {
        _isLoadingData = false;
      });
      return;
    }
    try {
      final now = DateTime.now();
      final startDateCurrentMonth = DateTime(now.year, now.month, 1);
      final endDateCurrentMonth =
          DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final balanceFuture =
          _transactionRepository.getOverallBalance(currentWalletId);
      final incomeFuture = _transactionRepository.getTotalAmount(
          walletId: currentWalletId,
          startDate: startDateCurrentMonth,
          endDate: endDateCurrentMonth,
          transactionType: FinTransaction.TransactionType.income);
      final expensesFuture = _transactionRepository.getTotalAmount(
          walletId: currentWalletId,
          startDate: startDateCurrentMonth,
          endDate: endDateCurrentMonth,
          transactionType: FinTransaction.TransactionType.expense);
      final recentTransactionsFuture = _transactionRepository
          .getTransactionsWithDetails(walletId: currentWalletId, limit: 5);
      final expensesGroupedFuture = _transactionRepository
          .getExpensesGroupedByCategory(
              currentWalletId, startDateCurrentMonth, endDateCurrentMonth);
      final results = await Future.wait([
        balanceFuture,
        incomeFuture,
        expensesFuture,
        recentTransactionsFuture,
        expensesGroupedFuture
      ]);
      if (!mounted) return;
      _overallBalanceUAH = results[0] as double;
      _currentMonthIncomeUAH = results[1] as double;
      _currentMonthExpensesUAH = results[2] as double;
      _recentTransactions = results[3] as List<TransactionViewData>;

      final expensesGrouped = results[4] as List<Map<String, dynamic>>;
      if (!mounted) return;

      final colorScheme = Theme.of(context).colorScheme;
      if (!mounted) return;
      final List<Color> dynamicPieChartColors = [
        colorScheme.primary,
        colorScheme.secondary,
        colorScheme.tertiary,
        colorScheme.primaryContainer.withOpacity(0.7),
        colorScheme.secondaryContainer.withOpacity(0.7),
        colorScheme.tertiaryContainer.withOpacity(0.7),
        Colors.pink.shade300,
        Colors.orange.shade300,
        Colors.teal.shade300,
        Colors.lime.shade400,
      ];

      _pieChartRawData = [];
      for (int i = 0; i < expensesGrouped.length; i++) {
        final item = expensesGrouped[i];
        _pieChartRawData.add(CategoryExpenseData(
          categoryName: item['categoryName'] as String,
          totalAmountInBaseCurrency: item['totalAmount'] as double,
          color: dynamicPieChartColors[i % dynamicPieChartColors.length],
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка завантаження даних дашборду: $e')),
        );
      }
    }
  }

  String _formatAmountForDisplay(
      double amountInBaseUAH, CurrencyProvider currencyProvider) {
    final selectedDisplayCurrency = currencyProvider.selectedCurrency;
    double displayAmount = amountInBaseUAH;
    String suffix = "";
    if (selectedDisplayCurrency.code == _baseCurrencyCode) {
      return NumberFormat.currency(
              locale: selectedDisplayCurrency.locale,
              symbol: selectedDisplayCurrency.symbol,
              decimalDigits: 2)
          .format(amountInBaseUAH);
    }
    if (_displayRateInfo != null && _displayRateInfo!.rate != 0) {
      displayAmount = amountInBaseUAH * _displayRateInfo!.rate;
      if (_displayRateInfo!.isRateStale) {
        suffix =
            " (курс від ${DateFormat('dd.MM.yy').format(_displayRateInfo!.effectiveRateDate)})";
      }
      return NumberFormat.currency(
                  locale: selectedDisplayCurrency.locale,
                  symbol: selectedDisplayCurrency.symbol,
                  decimalDigits: 2)
              .format(displayAmount) +
          suffix;
    } else if (!_isLoadingDisplayRate) {
      return "${NumberFormat.currency(locale: 'uk_UA', symbol: '₴', decimalDigits: 2).format(amountInBaseUAH)} (${selectedDisplayCurrency.symbol}?)";
    } else {
      return "${NumberFormat.currency(locale: 'uk_UA', symbol: '₴', decimalDigits: 2).format(amountInBaseUAH)} (...)";
    }
  }

  Widget _buildDashboardEmptyState(
      {required BuildContext context,
      required IconData icon,
      required String title,
      required String message,
      String? buttonText,
      VoidCallback? onButtonPressed}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 50,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (buttonText != null && onButtonPressed != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(buttonText),
                  onPressed: onButtonPressed,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(
      {required double height,
      int lineCount = 2,
      double lineWidthFraction = 0.6}) {
    return Container(
        height: height,
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: lineCount == 0
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                    lineCount,
                    (index) => Container(
                          height: 10,
                          width: MediaQuery.of(context).size.width *
                              (lineWidthFraction - (index * 0.1)),
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 4),
                        )),
              ));
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

  Widget _buildSkeletonListItem() {
    final Color itemColor = Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : Colors.grey[800]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: itemColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 14,
                      color: Theme.of(context).cardColor),
                  const SizedBox(height: 6),
                  Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      height: 12,
                      color: Theme.of(context).cardColor),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 60, height: 16, color: Theme.of(context).cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    final Color baseShimmerColor =
        Theme.of(context).brightness == Brightness.light
            ? Colors.grey[300]!
            : Colors.grey[700]!;
    final Color highlightShimmerColor =
        Theme.of(context).brightness == Brightness.light
            ? Colors.grey[100]!
            : Colors.grey[500]!;

    return Shimmer.fromColors(
      baseColor: baseShimmerColor,
      highlightColor: highlightShimmerColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        children: <Widget>[
          _buildSkeletonCard(height: 80),
          const SizedBox(height: 16),
          _buildSkeletonCard(height: 120),
          const SizedBox(height: 16),
          _buildSkeletonTitle(),
          const SizedBox(height: 8),
          _buildSkeletonCard(height: 250, lineCount: 0),
          const SizedBox(height: 16),
          _buildSkeletonTitle(),
          const SizedBox(height: 8),
          _buildSkeletonListItem(),
          _buildSkeletonListItem(),
          _buildSkeletonListItem(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyProviderListenFalse =
        Provider.of<CurrencyProvider>(context, listen: false);
    if (_isLoadingData ||
        (_isLoadingDisplayRate &&
            currencyProviderListenFalse.selectedCurrency.code !=
                _baseCurrencyCode)) {
      return _buildShimmerPlaceholder();
    }

    bool hasAnyDataForDashboard = _overallBalanceUAH != 0 ||
        _currentMonthIncomeUAH != 0 ||
        _currentMonthExpensesUAH != 0 ||
        _pieChartRawData.isNotEmpty ||
        _recentTransactions.isNotEmpty;
    if (!hasAnyDataForDashboard && !_isLoadingData && !_isLoadingDisplayRate) {
      return _buildDashboardEmptyState(
          context: context,
          icon: Icons.dashboard_customize_outlined,
          title: 'Дашборд порожній',
          message:
              'Додайте транзакції, щоб побачити тут статистику та підсумки.',
          buttonText: 'Додати першу транзакцію',
          onButtonPressed: () async {
            final result = await Navigator.push(
              context,
              FadePageRoute(
                  builder: (context) => const AddEditTransactionScreen()),
            );
            if (result == true && mounted) {
              refreshData();
            }
          });
    }
    return RefreshIndicator(
      onRefresh: refreshData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textTheme = Theme.of(context).textTheme;
          final colorScheme = Theme.of(context).colorScheme;
          if (constraints.maxWidth < 600) {
            return _buildPortraitLayout(context, textTheme, colorScheme);
          } else {
            return _buildLandscapeLayout(context, textTheme, colorScheme);
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout(
      BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      children: <Widget>[
        _buildBalanceCard(context, textTheme, colorScheme, _overallBalanceUAH),
        const SizedBox(height: 16),
        _buildMonthlySummaryCard(
            context,
            textTheme,
            colorScheme,
            _currentMonthIncomeUAH,
            _currentMonthExpensesUAH,
            _currentMonthIncomeUAH - _currentMonthExpensesUAH),
        const SizedBox(height: 16),
        Text('Витрати за поточний місяць',
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        _buildExpensePieChartCard(context, textTheme, colorScheme),
        const SizedBox(height: 16),
        Text('Останні транзакції',
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        _buildRecentTransactionsList(context, textTheme, colorScheme),
      ],
    );
  }

  Widget _buildLandscapeLayout(
      BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildBalanceCard(
                      context, textTheme, colorScheme, _overallBalanceUAH),
                  const SizedBox(height: 16),
                  _buildMonthlySummaryCard(
                      context,
                      textTheme,
                      colorScheme,
                      _currentMonthIncomeUAH,
                      _currentMonthExpensesUAH,
                      _currentMonthIncomeUAH - _currentMonthExpensesUAH),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Витрати за поточний місяць',
                      style: textTheme.titleLarge
                          ?.copyWith(color: colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  _buildExpensePieChartCard(context, textTheme, colorScheme),
                  const SizedBox(height: 16),
                  Text('Останні транзакції',
                      style: textTheme.titleLarge
                          ?.copyWith(color: colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  _buildRecentTransactionsList(context, textTheme, colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, TextTheme textTheme,
      ColorScheme colorScheme, double balanceUAH) {
    final balanceColor =
        balanceUAH >= 0 ? colorScheme.tertiary.withOpacity(0.9) : colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Загальний Баланс',
                style: textTheme.titleMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Consumer<CurrencyProvider>(
                builder: (context, currencyProv, child) {
              String formattedBalance =
                  _formatAmountForDisplay(balanceUAH, currencyProv);
              return Text(
                formattedBalance,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard(
      BuildContext context,
      TextTheme textTheme,
      ColorScheme colorScheme,
      double incomeUAH,
      double expensesUAH,
      double netIncomeUAH) {
    final now = DateTime.now();
    final monthName = DateFormat.MMMM('uk_UA').format(now);
    final incomeColor = colorScheme.tertiary.withOpacity(0.9);
    final expenseColor = colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Підсумок за $monthName ${now.year}',
                style: textTheme.titleMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Доходи:',
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.onSurface)),
                Flexible(
                  child: Consumer<CurrencyProvider>(
                      builder: (context, currencyProv, child) {
                    return Text(
                      _formatAmountForDisplay(incomeUAH, currencyProv),
                      style: textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold, color: incomeColor),
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Витрати:',
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.onSurface)),
                Flexible(
                  child: Consumer<CurrencyProvider>(
                      builder: (context, currencyProv, child) {
                    return Text(
                      _formatAmountForDisplay(expensesUAH, currencyProv),
                      style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: expenseColor),
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Чистий дохід:',
                    style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold)),
                Flexible(
                  child: Consumer<CurrencyProvider>(
                      builder: (context, currencyProv, child) {
                    return Text(
                      _formatAmountForDisplay(netIncomeUAH, currencyProv),
                      style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: netIncomeUAH >= 0
                              ? colorScheme.primary
                              : expenseColor.withOpacity(0.9)),
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensePieChartCard(
      BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    if (_pieChartRawData.isEmpty) {
      return _buildDashboardEmptyState(
        context: context,
        icon: Icons.pie_chart_outline_rounded,
        title: 'Немає витрат для діаграми',
        message:
            'Додайте транзакції витрат цього місяця, щоб побачити їх розподіл.',
      );
    }

    final CurrencyProvider currencyProviderForChartValues =
        Provider.of<CurrencyProvider>(context, listen: false);
    List<PieChartSectionData> sections = [];
    double totalExpensesForChartDisplayValue = 0;
    for (int i = 0; i < _pieChartRawData.length; i++) {
      final data = _pieChartRawData[i];
      double valueForChart = data.totalAmountInBaseCurrency;
      if (_displayRateInfo != null &&
          currencyProviderForChartValues.selectedCurrency.code !=
              _baseCurrencyCode &&
          _displayRateInfo!.rate != 0) {
        valueForChart = data.totalAmountInBaseCurrency * _displayRateInfo!.rate;
      }
      totalExpensesForChartDisplayValue += valueForChart;
    }
    for (int i = 0; i < _pieChartRawData.length; i++) {
      final data = _pieChartRawData[i];
      double valueForChart = data.totalAmountInBaseCurrency;
      if (_displayRateInfo != null &&
          currencyProviderForChartValues.selectedCurrency.code !=
              _baseCurrencyCode &&
          _displayRateInfo!.rate != 0) {
        valueForChart = data.totalAmountInBaseCurrency * _displayRateInfo!.rate;
      }

      final bool isTouched = i == _touchedIndexPieChart;
      final double fontSize = isTouched ? 15.0 : 12.0;
      final double radius = isTouched ? 60.0 : 50.0;
      final double percentage = totalExpensesForChartDisplayValue > 0
          ? (valueForChart / totalExpensesForChartDisplayValue) * 100
          : 0;
      final textColorOnSection =
          data.color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

      sections.add(PieChartSectionData(
        color: data.color,
        value: valueForChart,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColorOnSection,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      ));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (!mounted) return;
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndexPieChart = -1;
                          return;
                        }
                        _touchedIndexPieChart =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<CurrencyProvider>(
                builder: (context, currencyProv, child) {
              return Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                alignment: WrapAlignment.center,
                children: _pieChartRawData.map((data) {
                  String formattedLegendAmount = _formatAmountForDisplay(
                      data.totalAmountInBaseCurrency, currencyProv);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, color: data.color),
                      const SizedBox(width: 4),
                      Text('${data.categoryName} ($formattedLegendAmount)',
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsList(
      BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    if (_recentTransactions.isEmpty) {
      return _buildDashboardEmptyState(
          context: context,
          icon: Icons.history_edu_outlined,
          title: 'Поки що немає транзакцій',
          message: 'Ваші останні фінансові операції будуть відображені тут.',
          buttonText: 'Додати першу транзакцію',
          onButtonPressed: () async {
            final result = await Navigator.push(
              context,
              FadePageRoute(
                  builder: (context) => const AddEditTransactionScreen()),
            );
            if (result == true && mounted) {
              refreshData();
            }
          });
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentTransactions.length > 5 ? 5 : _recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _recentTransactions[index];
        final isIncome = transaction.type == FinTransaction.TransactionType.income;
        final amountColor =
            isIncome ? colorScheme.tertiary.withOpacity(0.9) : colorScheme.error;
        final amountPrefix = isIncome ? '+' : '-';
        final currency = appCurrencies.firstWhere(
            (c) => c.code == transaction.originalCurrencyCode,
            orElse: () => Currency(
                code: transaction.originalCurrencyCode,
                symbol: transaction.originalCurrencyCode,
                name: '',
                locale: ''));
        final formattedAmount = NumberFormat.currency(
                locale: currency.locale,
                symbol: currency.symbol,
                decimalDigits: 2)
            .format(transaction.originalAmount.abs());
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: amountColor.withOpacity(0.1),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: amountColor,
                size: 20,
              ),
            ),
            title: Text(transaction.categoryName,
                style: textTheme.titleSmall
                    ?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
            subtitle: Text(
                DateFormat('dd.MM.yyyy').format(transaction.date),
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            trailing: Text(
              '$amountPrefix$formattedAmount',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: amountColor),
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                FadePageRoute(
                  builder: (context) => AddEditTransactionScreen(
                      transactionToEdit: transaction.toTransactionModel()),
                ),
              );
              if (result == true && mounted) {
                refreshData();
              }
            },
          ),
        );
      },
    );
  }
}