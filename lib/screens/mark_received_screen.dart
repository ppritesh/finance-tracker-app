import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/finance_repository.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';

class MarkReceivedScreen extends StatefulWidget {
  const MarkReceivedScreen({super.key, required this.transaction});

  final Transaction transaction;

  @override
  State<MarkReceivedScreen> createState() => _MarkReceivedScreenState();
}

class _MarkReceivedScreenState extends State<MarkReceivedScreen> {
  final _noteController = TextEditingController();
  DateTime _receivedOn = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
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
    setState(() => _busy = true);
    try {
      await context.read<FinanceRepository>().markReceived(
        widget.transaction.id,
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

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;

    return Scaffold(
      appBar: AppBar(title: const Text('Mark received')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tx.personName ?? 'Credit',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            formatInr(tx.amount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Received on'),
            subtitle: Text(formatDate(_receivedOn)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Received note (optional)',
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
                : const Text('Confirm received'),
          ),
        ],
      ),
    );
  }
}
