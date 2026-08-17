import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/finance_repository.dart';
import '../models/person.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive.dart';
import '../widgets/amount_field.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.transaction,
    this.initialPerson,
    this.initialType,
  });

  final Transaction? transaction;
  final Person? initialPerson;
  final TransactionType? initialType;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  DateTime _date = DateTime.now();
  Person? _selectedPerson;
  bool _busy = false;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    if (tx != null) {
      _type = tx.type;
      _date = tx.transactionDate;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
      final persons = context.read<FinanceRepository>().persons;
      if (tx.personId != null) {
        for (final p in persons) {
          if (p.id == tx.personId) {
            _selectedPerson = p;
            break;
          }
        }
      }
    } else {
      _type = widget.initialType ?? TransactionType.creditGiven;
      _selectedPerson = widget.initialPerson;
    }
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
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickPerson() async {
    final repo = context.read<FinanceRepository>();
    if (repo.persons.isEmpty) await repo.refreshPersons();

    if (!mounted) return;

    final picked = await showModalBottomSheet<Person>(
      context: context,
      builder: (ctx) => _PersonPickerSheet(
        persons: repo.persons,
        onCreate: _createPersonQuick,
      ),
    );
    if (picked != null) setState(() => _selectedPerson = picked);
  }

  Future<Person?> _createPersonQuick() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final created = await showDialog<Person>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                final person = await context.read<FinanceRepository>().createPerson(
                  name: name,
                  phone: phoneController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx, person);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    return created;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type == TransactionType.creditGiven && _selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a person for credit given')),
      );
      return;
    }

    setState(() => _busy = true);
    final repo = context.read<FinanceRepository>();

    final draft = Transaction(
      id: widget.transaction?.id ?? 0,
      type: _type,
      personId: _selectedPerson?.id,
      personName: _selectedPerson?.name,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      transactionDate: _date,
      status: _type == TransactionType.expense
          ? TransactionStatus.paid
          : TransactionStatus.pending,
    );

    try {
      if (_isEdit) {
        await repo.updateTransaction(draft);
      } else {
        await repo.createTransaction(draft);
      }
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
    final isReceivedCredit = widget.transaction?.status == TransactionStatus.received;
    final hasPayments = widget.transaction?.status == TransactionStatus.partial;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit transaction' : 'Add transaction'),
      ),
      body: Form(
        key: _formKey,
        child: AdaptiveBody(
          maxWidth: 560,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.creditGiven,
                  label: Text('Credit Given'),
                  icon: Icon(Icons.handshake_outlined),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.shopping_cart_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: isReceivedCredit || hasPayments
                  ? null
                  : (value) => setState(() => _type = value.first),
            ),
            const SizedBox(height: 16),
            if (_type == TransactionType.creditGiven)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Person'),
                subtitle: Text(_selectedPerson?.name ?? 'Tap to select'),
                trailing: const Icon(Icons.chevron_right),
                onTap: isReceivedCredit || hasPayments ? null : _pickPerson,
              ),
            AmountField(controller: _amountController),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(formatDate(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: isReceivedCredit || hasPayments ? null : _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note / reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              readOnly: isReceivedCredit || hasPayments,
            ),
            const SizedBox(height: 24),
            if (!isReceivedCredit && !hasPayments)
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Save changes' : 'Add transaction'),
              ),
          ],
          ),
        ),
      ),
    );
  }
}

class _PersonPickerSheet extends StatelessWidget {
  const _PersonPickerSheet({
    required this.persons,
    required this.onCreate,
  });

  final List<Person> persons;
  final Future<Person?> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Select person'),
            trailing: TextButton(
              onPressed: () async {
                final created = await onCreate();
                if (created != null && context.mounted) {
                  Navigator.pop(context, created);
                }
              },
              child: const Text('Add new'),
            ),
          ),
          if (persons.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No persons yet. Add one.'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: persons.length,
                itemBuilder: (context, index) {
                  final person = persons[index];
                  return ListTile(
                    title: Text(person.name),
                    subtitle: person.phone != null ? Text(person.phone!) : null,
                    onTap: () => Navigator.pop(context, person),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
