import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/finance_repository.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive.dart';
import '../widgets/amount_field.dart';

class MarkReceivedScreen extends StatefulWidget {
  const MarkReceivedScreen({super.key, required this.transaction});

  final Transaction transaction;

  @override
  State<MarkReceivedScreen> createState() => _MarkReceivedScreenState();
}

class _MarkReceivedScreenState extends State<MarkReceivedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _receivedOn = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final remaining = widget.transaction.remainingAmount;
    _amountController.text = remaining > 0 ? remaining.toString() : '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedOn,
      firstDate: widget.transaction.transactionDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _receivedOn = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final remaining = widget.transaction.remainingAmount;

    if (amount > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Amount cannot exceed ${formatInr(remaining)}'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await context.read<FinanceRepository>().recordPayment(
        widget.transaction.id,
        amount: amount,
        receivedOn: _receivedOn,
        receivedNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fillRemaining() {
    _amountController.text = widget.transaction.remainingAmount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Record payment')),
      body: Form(
        key: _formKey,
        child: AdaptiveBody(
          maxWidth: 560,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
            Text(
              tx.personName ?? 'Credit',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ResponsiveStatRow(
              children: [
                _AmountSummary(
                  label: 'Total',
                  amount: tx.amount,
                  color: theme.colorScheme.primary,
                ),
                _AmountSummary(
                  label: 'Received',
                  amount: tx.receivedTotal,
                  color: Colors.green.shade700,
                ),
                _AmountSummary(
                  label: 'Remaining',
                  amount: tx.remainingAmount,
                  color: Colors.orange.shade800,
                ),
              ],
            ),
            if (tx.settlements.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Previous payments', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...tx.settlements.map(
                (s) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: ListTile(
                    title: Text(formatInr(s.amount)),
                    subtitle: Text(
                      '${formatDate(s.receivedOn)}${s.note != null ? ' · ${s.note}' : ''}',
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            AmountField(
              controller: _amountController,
              label: 'Payment amount',
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid amount';
                }
                if (parsed > tx.remainingAmount) {
                  return 'Max ${formatInr(tx.remainingAmount)}';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _fillRemaining,
                child: const Text('Fill remaining'),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Received on'),
              subtitle: Text(formatDate(_receivedOn)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Cash, UPI, bank transfer…',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Record payment'),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _AmountSummary extends StatelessWidget {
  const _AmountSummary({
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
