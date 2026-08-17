import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';
import '../utils/responsive.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    this.color,
    this.icon,
  });

  final String title;
  final double amount;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    final isDesktop = context.isDesktop;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: isDesktop ? 22 : 18, color: accent),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: isDesktop ? 15 : null,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 12 : 8),
            Text(
              formatInr(amount),
              style: (isDesktop
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
