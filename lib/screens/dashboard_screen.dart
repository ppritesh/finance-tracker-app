import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/finance_repository.dart';
import '../utils/responsive.dart';
import '../widgets/recent_transactions_panel.dart';
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

    final cards = [
      SummaryCard(
        title: 'Pending Udhari',
        amount: summary.pendingCreditTotal,
        icon: Icons.hourglass_top,
        color: Colors.orange.shade800,
      ),
      SummaryCard(
        title: 'Received This Month',
        amount: summary.receivedCreditTotal,
        icon: Icons.check_circle_outline,
        color: Colors.green.shade700,
      ),
      SummaryCard(
        title: 'Expenses This Month',
        amount: summary.expenseTotalThisMonth,
        icon: Icons.shopping_bag_outlined,
        color: Colors.blue.shade700,
      ),
      SummaryCard(
        title: 'Total Expenses',
        amount: summary.expenseTotalAllTime,
        icon: Icons.receipt_long,
        color: Theme.of(context).colorScheme.primary,
      ),
    ];

    if (context.isDesktop) {
      return RefreshIndicator(
        onRefresh: repo.refreshAll,
        child: AdaptiveBody(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useSidePanel = constraints.maxWidth >= 1000;

              final summaryGrid = GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.85,
                ),
                itemCount: cards.length,
                itemBuilder: (_, i) => cards[i],
              );

              if (!useSidePanel) {
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [summaryGrid],
                );
              }

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: summaryGrid),
                      const SizedBox(width: 24),
                      const Expanded(
                        flex: 2,
                        child: RecentTransactionsPanel(),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    final columns = context.dashboardColumns;

    return RefreshIndicator(
      onRefresh: repo.refreshAll,
      child: AdaptiveBody(
        child: columns == 1
            ? ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: cards.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => cards[i],
              )
            : GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns >= 4 ? 1.6 : 1.8,
                ),
                itemCount: cards.length,
                itemBuilder: (_, i) => cards[i],
              ),
      ),
    );
  }
}
