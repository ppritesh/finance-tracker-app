import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/auth_controller.dart';
import '../utils/adaptive_navigation.dart';
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
    (icon: Icons.dashboard_outlined, selected: Icons.dashboard, label: 'Home'),
    (
      icon: Icons.receipt_long_outlined,
      selected: Icons.receipt_long,
      label: 'Ledger',
    ),
    (icon: Icons.people_outline, selected: Icons.people, label: 'Persons'),
    (icon: Icons.person_outline, selected: Icons.person, label: 'Account'),
  ];

  Future<void> _addTransaction() async {
    final changed = await pushAdaptivePage<bool>(
      context,
      const TransactionFormScreen(),
    );
    if (changed == true && mounted) {
      setState(() => _index = 1);
    }
  }

  void _onPrimaryAction() {
    if (_index == 2) {
      _personsKey.currentState?.showAddDialog();
    } else {
      _addTransaction();
    }
  }

  String? get _primaryActionLabel => switch (_index) {
    0 || 1 => 'Add transaction',
    2 => 'Add person',
    _ => null,
  };

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

  Widget _buildHeaderActions() {
    final label = _primaryActionLabel;
    if (label == null) return const SizedBox.shrink();

    return FilledButton.icon(
      onPressed: _onPrimaryAction,
      icon: Icon(_index == 2 ? Icons.person_add : Icons.add),
      label: Text(label),
    );
  }

  Widget _buildDesktopSidebar() {
    final theme = Theme.of(context);

    return Container(
      width: Breakpoints.sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Finance Tracker',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          for (var i = 0; i < _destinations.length; i++)
            _SidebarNavItem(
              icon: _destinations[i].icon,
              selectedIcon: _destinations[i].selected,
              label: _destinations[i].label,
              selected: _index == i,
              onTap: () => setState(() => _index = i),
            ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => context.read<AuthController>().signOut(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    final theme = Theme.of(context);

    return Expanded(
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerLowest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 24, 40, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _titles[_index],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildHeaderActions(),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildRailLayout() {
    final extendedRail = context.screenWidth >= Breakpoints.railExtended;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            extended: extendedRail,
            minExtendedWidth: 200,
            labelType: extendedRail
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: extendedRail
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _titles[_index],
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      _buildHeaderActions(),
                    ],
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _primaryActionLabel == null
          ? null
          : FloatingActionButton(
              onPressed: _onPrimaryAction,
              tooltip: _primaryActionLabel,
              child: Icon(_index == 2 ? Icons.person_add : Icons.add),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (context.useDesktopShell) {
      return Scaffold(
        body: Row(
          children: [
            _buildDesktopSidebar(),
            _buildDesktopContent(),
          ],
        ),
      );
    }

    if (context.useNavigationRail) {
      return _buildRailLayout();
    }

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: _buildBody(),
      floatingActionButton: _primaryActionLabel == null
          ? null
          : FloatingActionButton(
              onPressed: _onPrimaryAction,
              tooltip: _primaryActionLabel,
              child: Icon(_index == 2 ? Icons.person_add : Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: selected,
        selectedTileColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.5,
        ),
        leading: Icon(selected ? selectedIcon : icon),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
