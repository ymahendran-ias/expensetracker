import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/income.dart';
import '../models/investment.dart';
import '../services/database_service.dart';

const Map<String, Color> _knownCategoryColors = {
  'Food & Dining': Color(0xFFFF6F00),
  'Transportation': Color(0xFF1565C0),
  'Housing & Rent': Color(0xFF6A1B9A),
  'Utilities': Color(0xFF00838F),
  'Entertainment': Color(0xFFC62828),
  'Healthcare': Color(0xFF2E7D32),
  'Shopping': Color(0xFFEF6C00),
  'Education': Color(0xFF283593),
  'Personal Care': Color(0xFFAD1457),
  'Insurance': Color(0xFF4E342E),
  'Other': Color(0xFF546E7A),
};

const _fallbackPalette = [
  Color(0xFF7B1FA2), Color(0xFF0288D1), Color(0xFF388E3C),
  Color(0xFFF57C00), Color(0xFF5D4037), Color(0xFF455A64),
  Color(0xFFC2185B), Color(0xFF1976D2), Color(0xFF689F38),
  Color(0xFFE64A19),
];

Color _getCategoryColor(String category) {
  return _knownCategoryColors[category] ??
      _fallbackPalette[category.hashCode.abs() % _fallbackPalette.length];
}

class DashboardView extends StatefulWidget {
  final String familyId;
  const DashboardView({super.key, required this.familyId});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _dbService = DatabaseService();
  late DateTime _selectedMonth;
  final _currencyFormat =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  bool _showSensitive = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  String get _yearMonth =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  String get _monthLabel => DateFormat('MMMM yyyy').format(_selectedMonth);

  String _ymForOffset(int offset) {
    final dt = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
  }

  String _startOfRange() => _ymForOffset(-5);

  void _previousMonth() =>
      setState(() => _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() =>
      setState(() => _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), centerTitle: true),
      body: Column(
        children: [
          _buildMonthSelector(theme),
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: _dbService.expensesStream(
                  widget.familyId, _yearMonth),
              builder: (context, expSnap) {
                return StreamBuilder<List<Expense>>(
                  stream: _dbService.expensesRangeStream(
                      widget.familyId, _startOfRange(), _yearMonth),
                  builder: (context, trendSnap) {
                    return StreamBuilder<List<Income>>(
                      stream: _dbService.incomeStream(
                          widget.familyId, _yearMonth),
                      builder: (context, incSnap) {
                        return StreamBuilder<List<Investment>>(
                          stream: _dbService.investmentsStream(
                              widget.familyId, _yearMonth),
                          builder: (context, invSnap) {
                            if (expSnap.connectionState ==
                                    ConnectionState.waiting ||
                                trendSnap.connectionState ==
                                    ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            return _buildContent(
                              theme,
                              expSnap.data ?? [],
                              trendSnap.data ?? [],
                              incSnap.data ?? [],
                              invSnap.data ?? [],
                            );
                          },
                        );
                      },
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

  Widget _buildMonthSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              onPressed: _previousMonth,
              icon: const Icon(Icons.chevron_left)),
          Text(_monthLabel,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    List<Expense> currentExpenses,
    List<Expense> rangeExpenses,
    List<Income> incomes,
    List<Investment> investments,
  ) {
    final totalExpenses =
        currentExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final totalInvestments =
        investments.fold(0.0, (sum, i) => sum + i.amount);
    final netSavings = totalIncome - totalExpenses - totalInvestments;

    // Category breakdown for current month
    final Map<String, double> catTotals = {};
    for (final e in currentExpenses) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Monthly totals for trend (last 6 months)
    final months = List.generate(6, (i) => _ymForOffset(i - 5));
    final Map<String, double> monthlyTotals = {for (final m in months) m: 0};
    final Map<String, Map<String, double>> monthlyCatTotals = {
      for (final m in months) m: {},
    };
    for (final e in rangeExpenses) {
      final ym = e.date.substring(0, 7);
      if (monthlyTotals.containsKey(ym)) {
        monthlyTotals[ym] = (monthlyTotals[ym] ?? 0) + e.amount;
        monthlyCatTotals[ym]![e.category] =
            (monthlyCatTotals[ym]![e.category] ?? 0) + e.amount;
      }
    }

    // Top categories across all 6 months for trend lines
    final Map<String, double> globalCatTotals = {};
    for (final entry in monthlyCatTotals.values) {
      for (final ce in entry.entries) {
        globalCatTotals[ce.key] = (globalCatTotals[ce.key] ?? 0) + ce.value;
      }
    }
    final topCategories = (globalCatTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => e.key)
        .toList();

    final hasExpenseData = currentExpenses.isNotEmpty;
    final hasTrendData = rangeExpenses.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Expenses Total ──
        Card(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.receipt_long,
                    size: 32,
                    color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Expenses',
                          style: theme.textTheme.titleSmall?.copyWith(
                              color:
                                  theme.colorScheme.onErrorContainer)),
                      Text(_currencyFormat.format(totalExpenses),
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  theme.colorScheme.onErrorContainer)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Pie Chart ──
        if (hasExpenseData) ...[
          Text('Expenses by Category',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: sortedCats.map((entry) {
                  final pct = entry.value / totalExpenses * 100;
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    color: _getCategoryColor(entry.key),
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...sortedCats.map((entry) {
            final pct = totalExpenses > 0
                ? entry.value / totalExpenses * 100
                : 0.0;
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor:
                    _getCategoryColor(entry.key),
                radius: 14,
              ),
              title: Text(entry.key),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_currencyFormat.format(entry.value),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  Text('${pct.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
        ],

        // ── Monthly Expense Trend (bar chart) ──
        if (hasTrendData) ...[
          Text('Monthly Expense Trend',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Last 6 months',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (monthlyTotals.values.fold(
                            0.0,
                            (a, b) =>
                                a > b ? a : b) *
                        1.2)
                    .clamp(100, double.infinity),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final ym = months[group.x];
                      final dt = DateTime.parse('$ym-01');
                      return BarTooltipItem(
                        '${DateFormat('MMM yy').format(dt)}\n${_currencyFormat.format(rod.toY)}',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        final dt =
                            DateTime.parse('${months[idx]}-01');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                              DateFormat('MMM').format(dt),
                              style: const TextStyle(fontSize: 11)),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(months.length, (i) {
                  final isCurrentMonth = months[i] == _yearMonth;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: monthlyTotals[months[i]] ?? 0,
                        color: isCurrentMonth
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withAlpha(100),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Category Trends ──
        if (hasTrendData && topCategories.isNotEmpty) ...[
          Text('Category Trends',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Top categories over 6 months',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      final cat = topCategories[spot.barIndex];
                      return LineTooltipItem(
                        '$cat\n${_currencyFormat.format(spot.y)}',
                        TextStyle(
                          color: _getCategoryColor(cat),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        final dt =
                            DateTime.parse('${months[idx]}-01');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                              DateFormat('MMM').format(dt),
                              style: const TextStyle(fontSize: 11)),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: topCategories.map((cat) {
                  final color = _getCategoryColor(cat);
                  return LineChartBarData(
                    spots: List.generate(months.length, (i) {
                      return FlSpot(
                        i.toDouble(),
                        monthlyCatTotals[months[i]]?[cat] ?? 0,
                      );
                    }),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: color,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: topCategories.map((cat) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(cat),
                        shape: BoxShape.circle,
                      )),
                  const SizedBox(width: 4),
                  Text(cat, style: theme.textTheme.bodySmall),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── Empty State ──
        if (!hasExpenseData && incomes.isEmpty && investments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              children: [
                Icon(Icons.insert_chart_outlined,
                    size: 80, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'No data for this month.\nStart adding expenses, income, or investments!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),

        // ── Sensitive: Income, Investments, Net Savings ──
        if (incomes.isNotEmpty ||
            investments.isNotEmpty ||
            totalIncome > 0 ||
            totalInvestments > 0) ...[
          const Divider(height: 32),
          InkWell(
            onTap: () =>
                setState(() => _showSensitive = !_showSensitive),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _showSensitive
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _showSensitive
                          ? 'Hide Income & Investments'
                          : 'Show Income & Investments',
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.outline),
                    ),
                  ),
                  Icon(
                    _showSensitive
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          if (_showSensitive) ...[
            const SizedBox(height: 12),
            Row(children: [
              _SummaryCard(
                  label: 'Income',
                  amount: _currencyFormat.format(totalIncome),
                  color: Colors.green,
                  icon: Icons.arrow_downward),
              const SizedBox(width: 8),
              _SummaryCard(
                  label: 'Investments',
                  amount: _currencyFormat.format(totalInvestments),
                  color: Colors.blue,
                  icon: Icons.trending_up),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _SummaryCard(
                  label: 'Net Savings',
                  amount: _currencyFormat.format(netSavings),
                  color: netSavings >= 0 ? Colors.teal : Colors.orange,
                  icon: netSavings >= 0
                      ? Icons.savings
                      : Icons.warning),
              const Spacer(),
            ]),
          ],
        ],

        const SizedBox(height: 32),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ]),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  amount,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
