import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/finance_repository.dart';
import '../models/person.dart';
import '../models/person_summary.dart';
import '../utils/adaptive_navigation.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive.dart';
import 'person_detail_screen.dart';

class PersonsScreen extends StatefulWidget {
  const PersonsScreen({super.key});

  @override
  State<PersonsScreen> createState() => PersonsScreenState();
}

class PersonsScreenState extends State<PersonsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceRepository>().refreshAll();
    });
  }

  Future<void> showAddDialog([PersonSummary? summary]) => _showPersonDialog(summary);

  Future<void> _showPersonDialog([PersonSummary? summary]) async {
    final repo = context.read<FinanceRepository>();
    Person? person;
    if (summary != null) {
      for (final p in repo.persons) {
        if (p.id == summary.personId) {
          person = p;
          break;
        }
      }
    }

    final nameController = TextEditingController(text: person?.name ?? '');
    final phoneController = TextEditingController(text: person?.phone ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(person == null ? 'Add person' : 'Edit person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) {
      nameController.dispose();
      phoneController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    nameController.dispose();
    phoneController.dispose();

    if (name.isEmpty) return;

    try {
      if (person == null) {
        await repo.createPerson(name: name, phone: phone);
      } else {
        await repo.updatePerson(
          Person(
            id: person.id,
            name: name,
            phone: phone.isEmpty ? null : phone,
          ),
        );
      }
      await repo.refreshAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _delete(PersonSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete person?'),
        content: Text('Remove ${summary.name}?'),
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

    final repo = context.read<FinanceRepository>();
    try {
      await repo.deletePerson(summary.personId);
      await repo.refreshAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _openPerson(PersonSummary summary) {
    pushAdaptivePage<void>(
      context,
      PersonDetailScreen(summary: summary),
      maxWidth: 900,
      maxHeight: 800,
    );
  }

  Widget _buildPersonCard(PersonSummary summary) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openPerson(summary),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Text(
                      summary.name.isNotEmpty
                          ? summary.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (summary.phone != null)
                          Text(
                            summary.phone!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (summary.totalRemaining > 0)
                    Text(
                      formatInr(summary.totalRemaining),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showPersonDialog(summary);
                      } else if (value == 'delete') {
                        _delete(summary);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              if (summary.hasCredit) ...[
                const SizedBox(height: 10),
                Text(
                  'Given ${formatInr(summary.totalCredit)} · Received ${formatInr(summary.totalReceived)} · Pending ${formatInr(summary.totalRemaining)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FinanceRepository>();
    final summaries = repo.personSummaries;
    final columns = context.listColumns;

    if (summaries.isEmpty) {
      return AdaptiveBody(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No persons yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.isDesktop
                    ? 'Click "Add person" to get started'
                    : 'Tap + to add someone you lend to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: repo.refreshAll,
      child: AdaptiveBody(
        child: columns == 1
            ? ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: summaries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _buildPersonCard(summaries[index]),
              )
            : GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                  childAspectRatio: columns >= 3 ? 1.55 : 1.7,
                ),
                itemCount: summaries.length,
                itemBuilder: (context, index) =>
                    _buildPersonCard(summaries[index]),
              ),
      ),
    );
  }
}
