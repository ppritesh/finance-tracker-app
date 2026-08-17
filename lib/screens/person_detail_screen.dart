import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/finance_repository.dart';
import '../logic/person_ledger.dart';
import '../models/person.dart';
import '../models/person_summary.dart';
import '../models/transaction.dart';
import '../utils/adaptive_navigation.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive.dart';
import '../widgets/transaction_tile.dart';
import 'mark_received_screen.dart';
import 'transaction_form_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({super.key, required this.summary});

  final PersonSummary summary;

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  List<Transaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = context.read<FinanceRepository>();
    await repo.refreshTransactions(personId: widget.summary.personId);
    if (mounted) {
      setState(() {
        _transactions = transactionsForPerson(
          repo.transactions,
          widget.summary.personId,
        );
        _loading = false;
      });
    }
  }

  Future<void> _openForm([Transaction? transaction]) async {
    final changed = await pushAdaptivePage<bool>(
      context,
      TransactionFormScreen(transaction: transaction),
    );
    if (changed == true && mounted) await _load();
  }

  Future<void> _recordPayment(Transaction transaction) async {
    final changed = await pushAdaptivePage<bool>(
      context,
      MarkReceivedScreen(transaction: transaction),
      maxWidth: 600,
    );
    if (changed == true && mounted) await _load();
  }

  Future<void> _delete(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<FinanceRepository>().deleteTransaction(transaction.id);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _addCredit() async {
    Person? person;
    for (final p in context.read<FinanceRepository>().persons) {
      if (p.id == widget.summary.personId) {
        person = p;
        break;
      }
    }
    if (person == null) return;

    final changed = await pushAdaptivePage<bool>(
      context,
      TransactionFormScreen(
        initialPerson: person,
        initialType: TransactionType.creditGiven,
      ),
    );
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        actions: context.isDesktop
            ? [
                FilledButton.tonal(
                  onPressed: _addCredit,
                  child: const Text('Add credit'),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: AdaptiveBody(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                  if (s.phone != null)
                    Text(s.phone!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  ResponsiveStatRow(
                    children: [
                      _SummaryBox(
                        label: 'Total given',
                        amount: s.totalCredit,
                        color: theme.colorScheme.primary,
                      ),
                      _SummaryBox(
                        label: 'Received',
                        amount: s.totalReceived,
                        color: Colors.green.shade700,
                      ),
                      _SummaryBox(
                        label: 'Pending',
                        amount: s.totalRemaining,
                        color: Colors.orange.shade800,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Transactions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No transactions yet')),
                    )
                  else
                    ..._transactions.map(
                      (tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TransactionTile(
                          transaction: tx,
                          onTap: () => _openForm(tx),
                          onRecordPayment: tx.canRecordPayment
                              ? () => _recordPayment(tx)
                              : null,
                          onDelete: () => _delete(tx),
                        ),
                      ),
                    ),
                ],
                ),
              ),
            ),
      floatingActionButton: context.isDesktop
          ? null
          : FloatingActionButton(
              onPressed: _addCredit,
              child: const Icon(Icons.add),
            ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            formatInr(amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
