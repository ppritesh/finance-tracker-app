import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import '../widgets/status_chip.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onRecordPayment,
    this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onDelete;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          transaction.personName ??
                              transaction.note ??
                              transaction.type.label,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                  if (compact)
                    _buildCompactMeta(context, theme)
                  else
                    _buildWideMeta(context, theme),
                  if (transaction.status == TransactionStatus.partial)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Received ${formatInr(transaction.receivedTotal)} · Remaining ${formatInr(transaction.remainingAmount)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  if (transaction.note != null &&
                      transaction.personName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        transaction.note!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideMeta(BuildContext context, ThemeData theme) {
    return Row(
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
        if (onRecordPayment != null)
          TextButton(
            onPressed: onRecordPayment,
            child: const Text('Record payment'),
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
      ],
    );
  }

  Widget _buildCompactMeta(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatDate(transaction.transactionDate),
              style: theme.textTheme.bodySmall,
            ),
            StatusChip(
              status: transaction.status,
              type: transaction.type,
            ),
          ],
        ),
        if (onRecordPayment != null || onDelete != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onRecordPayment != null)
                TextButton(
                  onPressed: onRecordPayment,
                  child: const Text('Record payment'),
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
            ],
          ),
      ],
    );
  }
}
