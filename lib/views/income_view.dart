import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/income.dart';
import '../services/database_service.dart';

const Map<String, IconData> _sourceIcons = {
  'Salary': Icons.work,
  'Freelance': Icons.laptop,
  'Business': Icons.business,
  'Dividends': Icons.pie_chart,
  'Rental Income': Icons.house,
  'Interest': Icons.percent,
  'Other': Icons.more_horiz,
};

class IncomeView extends StatefulWidget {
  final String familyId;
  final String userId;
  final String displayName;
  final List<String> sources;

  const IncomeView({
    super.key,
    required this.familyId,
    required this.userId,
    required this.displayName,
    required this.sources,
  });

  @override
  State<IncomeView> createState() => _IncomeViewState();
}

class _IncomeViewState extends State<IncomeView> {
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

  void _showAddEditSheet([Income? existing]) {
    final dateCtl = TextEditingController(
        text: existing?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final amountCtl = TextEditingController(
        text: existing != null ? existing.amount.toString() : '');
    final notesCtl = TextEditingController(text: existing?.notes ?? '');
    final sources = existing != null &&
            !widget.sources.contains(existing.source)
        ? [...widget.sources, existing.source]
        : widget.sources;
    String selectedSource = existing?.source ?? sources.first;

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
                Text(existing != null ? 'Edit Income' : 'Add Income',
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
                  initialValue: selectedSource,
                  decoration: const InputDecoration(
                    labelText: 'Source',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(),
                  ),
                  items: sources
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => selectedSource = v!),
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
                          await _dbService.updateIncome(
                              widget.familyId, existing.id, {
                            'date': dateCtl.text,
                            'source': selectedSource,
                            'amount': amount,
                            'notes': notesCtl.text,
                          });
                        } else {
                          await _dbService.addIncome(
                            widget.familyId,
                            Income(
                              id: '',
                              date: dateCtl.text,
                              source: selectedSource,
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
                    child: Text(existing != null ? 'Update' : 'Add Income'),
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
      appBar: AppBar(title: const Text('Income'), centerTitle: true),
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
            child: StreamBuilder<List<Income>>(
              stream: _dbService.incomeStream(widget.familyId, _yearMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet,
                            size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('No income this month',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                  );
                }

                final totalIncome =
                    items.fold(0.0, (sum, i) => sum + i.amount);

                return Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Income',
                                style: theme.textTheme.titleSmall),
                            Text(_currencyFormat.format(totalIncome),
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final income = items[index];
                          return Dismissible(
                            key: Key(income.id),
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
                                title: const Text('Delete Income'),
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
                            onDismissed: (_) => _dbService.deleteIncome(
                                widget.familyId, income.id),
                            child: ListTile(
                              onTap: () => _showAddEditSheet(income),
                              leading: CircleAvatar(
                                backgroundColor:
                                    Colors.green.withAlpha(30),
                                child: Icon(
                                    _sourceIcons[income.source] ??
                                        Icons.attach_money,
                                    color: Colors.green.shade700,
                                    size: 20),
                              ),
                              title: Text(income.source),
                              subtitle: Text(
                                '${income.date} • ${income.notes.isNotEmpty ? income.notes : 'No notes'} • ${income.createdByName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                _currencyFormat.format(income.amount),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
