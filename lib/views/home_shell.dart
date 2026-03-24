import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/family_group.dart';
import '../models/income.dart';
import '../models/investment.dart';
import '../services/database_service.dart';
import 'dashboard_view.dart';
import 'expenses_view.dart';
import 'family_view.dart';
import 'income_view.dart';
import 'investments_view.dart';

class HomeShell extends StatefulWidget {
  final String userId;
  final String familyId;
  final String displayName;

  const HomeShell({
    super.key,
    required this.userId,
    required this.familyId,
    required this.displayName,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FamilyGroup?>(
      stream: _dbService.familyStream(widget.familyId),
      builder: (context, snapshot) {
        final family = snapshot.data;
        final expCats =
            family != null && family.expenseCategories.isNotEmpty
                ? family.expenseCategories
                : defaultExpenseCategories;
        final incSources =
            family != null && family.incomeSources.isNotEmpty
                ? family.incomeSources
                : defaultIncomeSources;
        final invTypes =
            family != null && family.investmentTypes.isNotEmpty
                ? family.investmentTypes
                : defaultInvestmentTypes;

        final pages = [
          ExpensesView(
            familyId: widget.familyId,
            userId: widget.userId,
            displayName: widget.displayName,
            categories: expCats,
          ),
          IncomeView(
            familyId: widget.familyId,
            userId: widget.userId,
            displayName: widget.displayName,
            sources: incSources,
          ),
          InvestmentsView(
            familyId: widget.familyId,
            userId: widget.userId,
            displayName: widget.displayName,
            types: invTypes,
          ),
          FamilyView(
            familyId: widget.familyId,
            userId: widget.userId,
          ),
          DashboardView(familyId: widget.familyId),
        ];

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Expenses',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Income',
              ),
              NavigationDestination(
                icon: Icon(Icons.trending_up_outlined),
                selectedIcon: Icon(Icons.trending_up),
                label: 'Invest',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people),
                label: 'Family',
              ),
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Reports',
              ),
            ],
          ),
        );
      },
    );
  }
}
