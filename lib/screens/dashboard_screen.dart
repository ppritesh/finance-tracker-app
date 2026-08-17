import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/finance_repository.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FinanceRepository>();
    final summary = repo.summary;

    if (repo.isLoading && summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (summary == null) {
      return Center(
        child: Text(repo.error ?? 'No summary data'),
      );
    }

    return RefreshIndicator(
      onRefresh: repo.refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SummaryCard(
            title: 'Pending Udhari',
            amount: summary.pendingCreditTotal,
            icon: Icons.hourglass_top,
            color: Colors.orange.shade800,
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: 'Received This Month',
            amount: summary.receivedCreditTotal,
            icon: Icons.check_circle_outline,
            color: Colors.green.shade700,
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: 'Expenses This Month',
            amount: summary.expenseTotalThisMonth,
            icon: Icons.shopping_bag_outlined,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: 'Total Expenses',
            amount: summary.expenseTotalAllTime,
            icon: Icons.receipt_long,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
