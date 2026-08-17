import 'package:flutter/material.dart';

import '../models/transaction.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.type});

  final TransactionStatus status;
  final TransactionType? type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _style(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) _style(BuildContext context) {
    switch (status) {
      case TransactionStatus.pending:
        return ('Pending', Colors.orange.shade800);
      case TransactionStatus.received:
        return ('Received', Colors.green.shade700);
      case TransactionStatus.paid:
        return ('Paid', Colors.blue.shade700);
    }
  }
}
