import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/investment.dart';
import '../services/database_service.dart';

const Map<String, IconData> _typeIcons = {
  'Stocks': Icons.show_chart,
  'Mutual Funds': Icons.pie_chart,
  'Real Estate': Icons.apartment,
  'Cryptocurrency': Icons.currency_bitcoin,
  'Bonds': Icons.account_balance,
  'Fixed Deposit': Icons.lock_clock,
  'Gold': Icons.diamond,
  'Other': Icons.more_horiz,
};

class InvestmentsView extends StatefulWidget {
  final String familyId;
  final String userId;
  final String displayName;
  final List<String> types;

  const InvestmentsView({
    super.key,
    required this.familyId,
    required this.userId,
    required this.displayName,
    required this.types,
  });

  @override
  State<InvestmentsView> createState() => _InvestmentsViewState();
}

class _InvestmentsViewState extends State<InvestmentsView> {
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

  void _showAddEditSheet([Investment? existing]) {
    final dateCtl = TextEditingController(
        text: existing?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final amountCtl = TextEditingController(
        text: existing != null ? existing.amount.toString() : '');
    final notesCtl = TextEditingController(text: existing?.notes ?? '');
    final types = existing != null &&
            !widget.types.contains(existing.source)
        ? [...widget.types, existing.source]
        : widget.types;
    String selectedType = existing?.source ?? '';
    final typeCtl = TextEditingController(text: existing?.source ?? '');
    bool showTypeOptions = existing == null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final query = typeCtl.text.toLowerCase();
          final filteredTypes = types
              .where((t) => t.toLowerCase().contains(query))
              .toList();

          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    existing != null
                        ? 'Edit Investment'
                        : 'Add Investment',
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
                TextField(
                  controller: typeCtl,
                  decoration: InputDecoration(
                    labelText: 'Investment Type',
                    prefixIcon: const Icon(Icons.trending_up),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showTypeOptions
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down),
                      onPressed: () => setSheetState(
                          () => showTypeOptions = !showTypeOptions),
                    ),
                  ),
                  onChanged: (_) =>
                      setSheetState(() => showTypeOptions = true),
                  onTap: () =>
                      setSheetState(() => showTypeOptions = true),
                ),
                if (showTypeOptions && filteredTypes.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(ctx).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: filteredTypes.length,
                      itemBuilder: (_, i) {
                        final typ = filteredTypes[i];
                        return ListTile(
                          dense: true,
                          title: Text(typ),
                          selected: typ == selectedType,
                          onTap: () {
                            typeCtl.text = typ;
                            typeCtl.selection =
                                TextSelection.collapsed(
                                    offset: typ.length);
                            setSheetState(() {
                              selectedType = typ;
                              showTypeOptions = false;
                            });
                          },
                        );
                      },
                    ),
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
                      final typedType = typeCtl.text.trim();
                      final matchedType = types.cast<String?>().firstWhere(
                          (t) => t!.toLowerCase() == typedType.toLowerCase(),
                          orElse: () => null);
                      if (matchedType != null) selectedType = matchedType;
                      final amount = double.tryParse(amountCtl.text);
                      if (dateCtl.text.isEmpty ||
                          amount == null ||
                          amount <= 0 ||
                          !types.contains(selectedType)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text(
                                'Please fill in date, valid type, and amount')));
                        return;
                      }
                      try {
                        if (existing != null) {
                          await _dbService.updateInvestment(
                              widget.familyId, existing.id, {
                            'date': dateCtl.text,
                            'source': selectedType,
                            'amount': amount,
                            'notes': notesCtl.text,
                          });
                        } else {
                          await _dbService.addInvestment(
                            widget.familyId,
                            Investment(
                              id: '',
                              date: dateCtl.text,
                              source: selectedType,
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
                    child: Text(
                        existing != null ? 'Update' : 'Add Investment'),
                  ),
                ),
              ],
            ),
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
      appBar: AppBar(title: const Text('Investments'), centerTitle: true),
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
            child: StreamBuilder<List<Investment>>(
              stream: _dbService.investmentsStream(
                  widget.familyId, _yearMonth),
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
                        Icon(Icons.trending_up,
                            size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('No investments this month',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                  );
                }

                final totalInvested =
                    items.fold(0.0, (sum, i) => sum + i.amount);

                final Map<String, double> byType = {};
                for (final inv in items) {
                  byType[inv.source] =
                      (byType[inv.source] ?? 0) + inv.amount;
                }
                final sortedTypes = byType.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Invested',
                                style: theme.textTheme.titleSmall),
                            Text(
                                _currencyFormat.format(totalInvested),
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text('By Type',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    ...sortedTypes.map((entry) => ListTile(
                          dense: true,
                          leading: Icon(
                              _typeIcons[entry.key] ?? Icons.trending_up,
                              color: Colors.blue.shade700),
                          title: Text(entry.key),
                          trailing: Text(
                              _currencyFormat.format(entry.value),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        )),
                    const Divider(indent: 16, endIndent: 16),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text('All Entries',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    ...items.map((inv) => Dismissible(
                          key: Key(inv.id),
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
                              title: const Text('Delete Investment'),
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
                          onDismissed: (_) =>
                              _dbService.deleteInvestment(
                                  widget.familyId, inv.id),
                          child: ListTile(
                            onTap: () => _showAddEditSheet(inv),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Colors.blue.withAlpha(30),
                              child: Icon(
                                  _typeIcons[inv.source] ??
                                      Icons.trending_up,
                                  color: Colors.blue.shade700,
                                  size: 20),
                            ),
                            title: Text(inv.source),
                            subtitle: Text(
                              '${inv.date} • ${inv.notes.isNotEmpty ? inv.notes : 'No notes'} • ${inv.createdByName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              _currencyFormat.format(inv.amount),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700),
                            ),
                          ),
                        )),
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
