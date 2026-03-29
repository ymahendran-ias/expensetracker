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
  bool _hasFullAccess = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FamilyGroup?>(
      stream: _dbService.familyStream(widget.familyId),
      builder: (context, snapshot) {
        final family = snapshot.data;

        // Only update access when we have real data to avoid flicker
        if (family != null) {
          _hasFullAccess = family.hasFullAccess(widget.userId);
        }

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

        final hasFullAccess = _hasFullAccess;

        // Clamp index so it stays valid when tabs change
        final pages = <Widget>[
          ExpensesView(
            familyId: widget.familyId,
            userId: widget.userId,
            displayName: widget.displayName,
            categories: expCats,
          ),
          if (hasFullAccess)
            IncomeView(
              familyId: widget.familyId,
              userId: widget.userId,
              displayName: widget.displayName,
              sources: incSources,
            ),
          if (hasFullAccess)
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
          DashboardView(
            familyId: widget.familyId,
            hasFullAccess: hasFullAccess,
          ),
        ];

        final destinations = <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          if (hasFullAccess)
            const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Income',
            ),
          if (hasFullAccess)
            const NavigationDestination(
              icon: Icon(Icons.trending_up_outlined),
              selectedIcon: Icon(Icons.trending_up),
              label: 'Invest',
            ),
          const NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Family',
          ),
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Reports',
          ),
        ];

        final safeIndex = _currentIndex.clamp(0, pages.length - 1);

        return Scaffold(
          body: IndexedStack(index: safeIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: destinations,
          ),
        );
      },
    );
  }
}
