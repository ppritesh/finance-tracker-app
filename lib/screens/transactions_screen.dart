import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/finance_repository.dart';
import '../logic/person_ledger.dart';
import '../models/transaction.dart';
import '../utils/adaptive_navigation.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive.dart';
import '../widgets/transaction_tile.dart';
import 'mark_received_screen.dart';
import 'transaction_form_screen.dart';

enum TransactionFilter { all, credit, expense, pending, partial }

enum LedgerViewMode { list, byPerson }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _filter = TransactionFilter.all;
  LedgerViewMode _viewMode = LedgerViewMode.list;

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
      case TransactionFilter.partial:
        await repo.refreshTransactions(
          type: TransactionType.creditGiven,
          status: TransactionStatus.partial,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilter());
  }

  Future<void> _openForm([Transaction? transaction]) async {
    final changed = await pushAdaptivePage<bool>(
      context,
      TransactionFormScreen(transaction: transaction),
    );
    if (changed == true && mounted) await _applyFilter();
  }

  Future<void> _markReceived(Transaction transaction) async {
    final changed = await pushAdaptivePage<bool>(
      context,
      MarkReceivedScreen(transaction: transaction),
      maxWidth: 600,
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

  Widget _buildTransactionList(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.3,
            child: Center(
              child: Text(
                'No transactions yet',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      );
    }

    final columns = context.listColumns;

    if (columns == 1) {
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: transactions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return TransactionTile(
            transaction: tx,
            onTap: () => _openForm(tx),
            onRecordPayment:
                tx.canRecordPayment ? () => _markReceived(tx) : null,
            onDelete: () => _delete(tx),
          );
        },
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 8,
        childAspectRatio: columns >= 3 ? 1.45 : 1.55,
      ),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return TransactionTile(
          transaction: tx,
          onTap: () => _openForm(tx),
          onRecordPayment:
              tx.canRecordPayment ? () => _markReceived(tx) : null,
          onDelete: () => _delete(tx),
        );
      },
    );
  }

  Widget _buildGroupedByPerson(List<Transaction> transactions) {
    final grouped = groupCreditTransactionsByPerson(transactions);
    if (grouped.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.3,
            child: Center(
              child: Text(
                'No credit transactions to group',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final entry in grouped.entries) ...[
          _PersonSectionHeader(
            name: entry.key,
            transactions: entry.value,
          ),
          const SizedBox(height: 8),
          ...entry.value.map(
            (tx) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TransactionTile(
                transaction: tx,
                onTap: () => _openForm(tx),
                onRecordPayment:
                    tx.canRecordPayment ? () => _markReceived(tx) : null,
                onDelete: () => _delete(tx),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildFilters({bool vertical = false}) {
    final filters = TransactionFilter.values;

    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: filters.map((filter) {
          final selected = _filter == filter;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              selected: selected,
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.4),
              title: Text(_filterLabel(filter)),
              onTap: () async {
                setState(() => _filter = filter);
                await _applyFilter();
              },
            ),
          );
        }).toList(),
      );
    }

    if (!context.isMobile) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.map((filter) {
          return FilterChip(
            label: Text(_filterLabel(filter)),
            selected: _filter == filter,
            onSelected: (_) async {
              setState(() => _filter = filter);
              await _applyFilter();
            },
          );
        }).toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
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
    );
  }

  Widget _buildToolbar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<LedgerViewMode>(
          segments: const [
            ButtonSegment(
              value: LedgerViewMode.list,
              label: Text('List'),
              icon: Icon(Icons.list),
            ),
            ButtonSegment(
              value: LedgerViewMode.byPerson,
              label: Text('By person'),
              icon: Icon(Icons.people_outline),
            ),
          ],
          selected: {_viewMode},
          onSelectionChanged: (value) {
            setState(() => _viewMode = value.first);
          },
        ),
        if (!context.isDesktop) ...[
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FinanceRepository>();
    final transactions = repo.transactions;
    final useDesktopLayout = context.isDesktop;

    final listContent = repo.isLoading && transactions.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _applyFilter,
            child: _viewMode == LedgerViewMode.list
                ? _buildTransactionList(transactions)
                : _buildGroupedByPerson(transactions),
          );

    if (useDesktopLayout) {
      return AdaptiveBody(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilters(vertical: true),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToolbar(),
                  const SizedBox(height: 16),
                  Expanded(child: listContent),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        AdaptiveBody(
          padding: EdgeInsets.fromLTRB(
            context.pagePadding.left,
            0,
            context.pagePadding.right,
            0,
          ),
          child: _buildToolbar(),
        ),
        Expanded(
          child: AdaptiveBody(child: listContent),
        ),
      ],
    );
  }

  String _filterLabel(TransactionFilter filter) => switch (filter) {
    TransactionFilter.all => 'All',
    TransactionFilter.credit => 'Credit',
    TransactionFilter.expense => 'Expense',
    TransactionFilter.pending => 'Pending',
    TransactionFilter.partial => 'Partial',
  };
}

class _PersonSectionHeader extends StatelessWidget {
  const _PersonSectionHeader({
    required this.name,
    required this.transactions,
  });

  final String name;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final total = transactions.fold<double>(0, (s, t) => s + t.amount);
    final remaining = transactions.fold<double>(
      0,
      (s, t) => s + t.remainingAmount,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(
          alpha: 0.4,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 400;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pending ${formatInr(remaining)} · ${formatInr(total)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Pending ${formatInr(remaining)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatInr(total),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
