import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'account_screen.dart';
import 'dashboard_screen.dart';
import 'persons_screen.dart';
import 'transaction_form_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _personsKey = GlobalKey<PersonsScreenState>();

  static const _titles = ['Dashboard', 'Transactions', 'Persons', 'Account'];

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Ledger',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Persons',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Account',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: Text('Ledger'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: Text('Persons'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('Account'),
    ),
  ];

  Future<void> _addTransaction() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
    );
    if (changed == true && mounted) {
      setState(() => _index = 1);
    }
  }

  void _onFabPressed() {
    if (_index == 2) {
      _personsKey.currentState?.showAddDialog();
    } else {
      _addTransaction();
    }
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _index,
      children: [
        const DashboardScreen(),
        const TransactionsScreen(),
        PersonsScreen(key: _personsKey),
        const AccountScreen(),
      ],
    );
  }

  Widget? _buildFab() {
    if (_index > 2) return null;
    return FloatingActionButton(
      onPressed: _onFabPressed,
      tooltip: _index == 2 ? 'Add person' : 'Add transaction',
      child: Icon(_index == 2 ? Icons.person_add : Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useRail = context.useNavigationRail;
    final extendedRail = context.screenWidth >= Breakpoints.railExtended;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              extended: extendedRail,
              labelType: extendedRail
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: _railDestinations,
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      extendedRail ? 32 : 24,
                      20,
                      24,
                      8,
                    ),
                    child: Text(
                      _titles[_index],
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: _buildBody(),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
