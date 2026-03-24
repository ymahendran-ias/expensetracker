import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/database_service.dart';

const Map<String, Color> _categoryColors = {
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

const Map<String, IconData> _categoryIcons = {
  'Food & Dining': Icons.restaurant,
  'Transportation': Icons.directions_car,
  'Housing & Rent': Icons.home,
  'Utilities': Icons.bolt,
  'Entertainment': Icons.movie,
  'Healthcare': Icons.local_hospital,
  'Shopping': Icons.shopping_bag,
  'Education': Icons.school,
  'Personal Care': Icons.spa,
  'Insurance': Icons.security,
  'Other': Icons.more_horiz,
};

const _fallbackColors = [
  Color(0xFF7B1FA2), Color(0xFF0288D1), Color(0xFF388E3C),
  Color(0xFFF57C00), Color(0xFF5D4037), Color(0xFF455A64),
  Color(0xFFC2185B), Color(0xFF1976D2), Color(0xFF689F38),
  Color(0xFFE64A19),
];

Color _getColor(String category) {
  return _categoryColors[category] ??
      _fallbackColors[category.hashCode.abs() % _fallbackColors.length];
}

class ExpensesView extends StatefulWidget {
  final String familyId;
  final String userId;
  final String displayName;
  final List<String> categories;

  const ExpensesView({
    super.key,
    required this.familyId,
    required this.userId,
    required this.displayName,
    required this.categories,
  });

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  final _dbService = DatabaseService();
  late DateTime _selectedMonth;
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  String get _yearMonth =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  void _showAddEditSheet([Expense? existing]) {
    final dateCtl = TextEditingController(
        text: existing?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final amountCtl = TextEditingController(
        text: existing != null ? existing.amount.toString() : '');
    final notesCtl = TextEditingController(text: existing?.notes ?? '');
    final categories = existing != null &&
            !widget.categories.contains(existing.category)
        ? [...widget.categories, existing.category]
        : widget.categories;
    String selectedCategory = existing?.category ?? categories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing != null ? 'Edit Expense' : 'Add Expense',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextField(
                  controller: dateCtl,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          DateTime.tryParse(dateCtl.text) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      dateCtl.text = DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtl,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountCtl.text);
                      if (dateCtl.text.isEmpty ||
                          amount == null ||
                          amount <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text(
                                'Please fill in date and a valid amount')));
                        return;
                      }
                      try {
                        if (existing != null) {
                          await _dbService.updateExpense(
                              widget.familyId, existing.id, {
                            'date': dateCtl.text,
                            'category': selectedCategory,
                            'amount': amount,
                            'notes': notesCtl.text,
                          });
                        } else {
                          await _dbService.addExpense(
                            widget.familyId,
                            Expense(
                              id: '',
                              date: dateCtl.text,
                              category: selectedCategory,
                              amount: amount,
                              notes: notesCtl.text,
                              createdBy: widget.userId,
                              createdByName: widget.displayName,
                            ),
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child:
                        Text(existing != null ? 'Update' : 'Add Expense'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedMonth = DateTime(
                      _selectedMonth.year, _selectedMonth.month - 1)),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => setState(() => _selectedMonth = DateTime(
                      _selectedMonth.year, _selectedMonth.month + 1)),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream:
                  _dbService.expensesStream(widget.familyId, _yearMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final expenses = snapshot.data ?? [];
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('No expenses this month',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                  );
                }

                final Map<String, List<Expense>> grouped = {};
                for (final e in expenses) {
                  grouped.putIfAbsent(e.date, () => []).add(e);
                }
                final dates = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final items = grouped[date]!;
                    final dayTotal =
                        items.fold(0.0, (sum, e) => sum + e.amount);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(date,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(
                                          color:
                                              theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold)),
                              Text(_currencyFormat.format(dayTotal),
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(
                                          color:
                                              theme.colorScheme.error)),
                            ],
                          ),
                        ),
                        ...items.map((expense) => Dismissible(
                              key: Key(expense.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (_) => showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Expense'),
                                  content: const Text('Are you sure?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Delete')),
                                  ],
                                ),
                              ),
                              onDismissed: (_) => _dbService.deleteExpense(
                                  widget.familyId, expense.id),
                              child: ListTile(
                                onTap: () =>
                                    _showAddEditSheet(expense),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _getColor(expense.category)
                                          .withAlpha(30),
                                  child: Icon(
                                      _categoryIcons[expense.category] ??
                                          Icons.label,
                                      color:
                                          _getColor(expense.category),
                                      size: 20),
                                ),
                                title: Text(expense.category),
                                subtitle: Text(
                                  '${expense.notes.isNotEmpty ? expense.notes : 'No notes'} • ${expense.createdByName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  _currencyFormat.format(expense.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
