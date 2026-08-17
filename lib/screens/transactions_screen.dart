import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/finance_repository.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import '../widgets/status_chip.dart';
import 'mark_received_screen.dart';
import 'transaction_form_screen.dart';

enum TransactionFilter { all, credit, expense, pending }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _filter = TransactionFilter.all;

  Future<void> _applyFilter() async {
    final repo = context.read<FinanceRepository>();
    switch (_filter) {
      case TransactionFilter.all:
        await repo.refreshTransactions();
      case TransactionFilter.credit:
        await repo.refreshTransactions(type: TransactionType.creditGiven);
      case TransactionFilter.expense:
        await repo.refreshTransactions(type: TransactionType.expense);
      case TransactionFilter.pending:
        await repo.refreshTransactions(
          type: TransactionType.creditGiven,
          status: TransactionStatus.pending,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilter());
  }

  Future<void> _openForm([Transaction? transaction]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(transaction: transaction),
      ),
    );
    if (changed == true && mounted) await _applyFilter();
  }

  Future<void> _markReceived(Transaction transaction) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MarkReceivedScreen(transaction: transaction),
      ),
    );
    if (changed == true && mounted) await _applyFilter();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FinanceRepository>();
    final transactions = repo.transactions;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: TransactionFilter.values.map((filter) {
              final selected = _filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_filterLabel(filter)),
                  selected: selected,
                  onSelected: (_) async {
                    setState(() => _filter = filter);
                    await _applyFilter();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: repo.isLoading && transactions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : transactions.isEmpty
              ? Center(
                  child: Text(
                    'No transactions yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _applyFilter,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return _TransactionTile(
                        transaction: tx,
                        onTap: () => _openForm(tx),
                        onMarkReceived: tx.isPendingCredit
                            ? () => _markReceived(tx)
                            : null,
                        onDelete: () => _delete(tx),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String _filterLabel(TransactionFilter filter) => switch (filter) {
    TransactionFilter.all => 'All',
    TransactionFilter.credit => 'Credit',
    TransactionFilter.expense => 'Expense',
    TransactionFilter.pending => 'Pending',
  };
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onTap,
    this.onMarkReceived,
    required this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback? onMarkReceived;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.type == TransactionType.creditGiven;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.personName ??
                          transaction.note ??
                          transaction.type.label,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    formatInr(transaction.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCredit
                          ? Colors.orange.shade800
                          : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    formatDate(transaction.transactionDate),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  StatusChip(
                    status: transaction.status,
                    type: transaction.type,
                  ),
                  const Spacer(),
                  if (onMarkReceived != null)
                    TextButton(
                      onPressed: onMarkReceived,
                      child: const Text('Mark received'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (transaction.note != null && transaction.personName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    transaction.note!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
