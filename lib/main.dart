import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/auth_controller.dart';
import 'data/finance_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FinanceTrackerApp());
}

class FinanceTrackerApp extends StatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  late final ApiClient _api;
  late final AuthController _auth;
  late final FinanceRepository _repo;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _auth = AuthController(_api)..load();
    _repo = FinanceRepository(api: _api, auth: _auth);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _repo),
      ],
      child: MaterialApp(
        title: 'Finance Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const _AppGate(),
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _maybeLoadData();
  }

  Future<void> _maybeLoadData() async {
    final auth = context.read<AuthController>();
    while (!auth.isLoaded) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (auth.isAuthenticated && mounted) {
      await context.read<FinanceRepository>().refreshAll();
    }
    if (mounted) setState(() => _dataLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isLoaded || (auth.isAuthenticated && !_dataLoaded)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated) {
      return const AuthScreen();
    }

    return const HomeScreen();
  }
}
