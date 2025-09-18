import 'package:flutter/material.dart';
import 'package:wislet/screens/budgets/budgets_list_screen.dart';
import 'package:wislet/screens/financial_goals/financial_goals_list_screen.dart';
import 'package:wislet/screens/planning/plans_calendar_view.dart';
import 'package:wislet/widgets/scaffold/patterned_scaffold.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PatternedScaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Р‘СЋРґР¶РµС‚Рё'),
            Tab(text: 'РџР»Р°РЅРё'),
            Tab(text: 'Р¦С–Р»С–'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BudgetsListScreen(),
          PlansCalendarView(),
          FinancialGoalsListScreen(),
        ],
      ),
    );
  }
}
