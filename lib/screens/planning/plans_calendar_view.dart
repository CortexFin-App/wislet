import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/plan_repository.dart';
import 'package:wislet/models/plan_view_data.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/screens/planning/add_edit_plan_screen.dart';
import 'package:wislet/utils/fade_page_route.dart';
import 'package:table_calendar/table_calendar.dart';

class PlansCalendarView extends StatefulWidget {
  const PlansCalendarView({super.key});

  @override
  State<PlansCalendarView> createState() => _PlansCalendarViewState();
}

class _PlansCalendarViewState extends State<PlansCalendarView> {
  final PlanRepository _planRepository = getIt<PlanRepository>();
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<PlanViewData>> _events = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final walletProvider = context.read<WalletProvider>();
    final walletId = walletProvider.currentWallet?.id;
    if (walletId == null) {
      if (mounted) setState(() => _events = {});
      return;
    }
    final plansEither =
        await _planRepository.getPlansWithCategoryDetails(walletId);
    plansEither.fold(
      (_) => null,
      (r) {
        final map = <DateTime, List<PlanViewData>>{};
        for (final p in r) {
          final k = DateTime.utc(p.startDate.year, p.startDate.month);
          map.putIfAbsent(k, () => []).add(p);
        }
        if (mounted) setState(() => _events = map);
      },
    );
  }

  Future<void> _navigateToAddPlan() async {
    final result = await Navigator.push<bool>(
      context,
      FadePageRoute<bool>(
        builder: (_) => AddEditPlanScreen(initialDate: _focusedDay),
      ),
    );
    if (result == true && mounted) {
      await _loadPlans();
    }
  }

  String _formatAmount(BuildContext context, num value, String code) {
    final symbol = NumberFormat.simpleCurrency(name: code).currencySymbol;
    final v = NumberFormat('#,##0.00').format(value.toDouble());
    return '$v $symbol';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPlan,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const Divider(height: 1),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar<PlanViewData>(
      locale: 'uk_UA',
      firstDay: DateTime.utc(2020),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        }
      },
      eventLoader: (day) {
        final k = DateTime.utc(day.year, day.month);
        return _events[k] ?? [];
      },
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );
  }

  Widget _buildEventList() {
    final k = DateTime.utc(_selectedDay.year, _selectedDay.month);
    final items = _events[k] ?? [];
    final currencyProvider = context.watch<CurrencyProvider>();
    final code = currencyProvider.selectedCurrency.code;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('На цей місяць плани відсутні.'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _navigateToAddPlan,
              child: const Text('Створити новий план'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final p = items[i];
        final planned = p.plannedAmountInBaseCurrency;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            title: Text(p.categoryName),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_formatAmount(context, planned, code)),
            ),
          ),
        );
      },
    );
  }
}
