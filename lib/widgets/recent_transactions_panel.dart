import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/finance_repository.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import '../widgets/status_chip.dart';
import '../utils/adaptive_navigation.dart';
import '../screens/transaction_form_screen.dart';

class RecentTransactionsPanel extends StatelessWidget {
  const RecentTransactionsPanel({super.key});

  Future<void> _openTransaction(BuildContext context, Transaction tx) async {
    await pushAdaptivePage<bool>(
      context,
      TransactionFormScreen(transaction: tx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactions = context
        .watch<FinanceRepository>()
        .transactions
        .take(8)
        .toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recent activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No transactions yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...transactions.map((tx) {
                final isCredit = tx.type == TransactionType.creditGiven;
                return InkWell(
                  onTap: () => _openTransaction(context, tx),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isCredit
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                          child: Icon(
                            isCredit
                                ? Icons.handshake_outlined
                                : Icons.shopping_bag_outlined,
                            size: 18,
                            color: isCredit
                                ? Colors.orange.shade800
                                : Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.personName ?? tx.note ?? tx.type.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatDate(tx.transactionDate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatInr(tx.amount),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCredit
                                    ? Colors.orange.shade800
                                    : Colors.blue.shade700,
                              ),
                            ),
                            StatusChip(status: tx.status, type: tx.type),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
