import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../models/forecast_data_point.dart';
import '../../providers/currency_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/cashflow_forecast_service.dart';
import '../../widgets/scaffold/patterned_scaffold.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final CashflowForecastService _forecastService = getIt<CashflowForecastService>();
  Future<List<ForecastDataPoint>>? _forecastFuture;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForecast();
    });
  }

  void _loadForecast() {
    if (!mounted) return;
    final walletId = context.read<WalletProvider>().currentWallet?.id;
    if (walletId != null) {
      setState(() {
        _forecastFuture = _forecastService.getForecast(walletId: walletId, days: _selectedDays);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencyFormatter = currencyProvider.currencyFormatter;

    return PatternedScaffold(
      appBar: AppBar(
        title: const Text('Прогноз Грошового Потоку'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30 днів')),
                ButtonSegment(value: 90, label: Text('90 днів')),
                ButtonSegment(value: 180, label: Text('180 днів')),
              ],
              selected: {_selectedDays},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedDays = newSelection.first;
                  _loadForecast();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ForecastDataPoint>>(
              future: _forecastFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Помилка прогнозування: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Немає даних для прогнозу.'));
                }

                final forecastData = snapshot.data!;
                final spots = forecastData.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.balance);
                }).toList();
                
                final minY = forecastData.map((p) => p.balance).reduce((a, b) => a < b ? a : b);
                final maxY = forecastData.map((p) => p.balance).reduce((a, b) => a > b ? a : b);
                final buffer = (maxY - minY).abs() * 0.1;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: (maxY - minY).abs() > 0 ? (maxY - minY).abs() / 4 : 1,
                        verticalInterval: (_selectedDays / 5).roundToDouble(),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: (_selectedDays / 5).roundToDouble(),
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < forecastData.length) {
                                final date = forecastData[value.toInt()].date;
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8.0,
                                  child: Text(DateFormat('dd.MM').format(date)),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8.0,
                                  child: Text(NumberFormat.compact().format(value)),
                                );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
                      minY: minY - buffer,
                      maxY: maxY + buffer,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).colorScheme.primary.withAlpha(51),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final dataPoint = forecastData[spot.spotIndex];
                              return LineTooltipItem(
                                '${DateFormat('dd.MM.yyyy').format(dataPoint.date)}\n${currencyFormatter.format(dataPoint.balance)}',
                                TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.left,
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}